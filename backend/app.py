from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db_connection
from otp_service import send_mobile_otp, send_email_otp, verify_otp
import bcrypt
import os
from flask import send_from_directory

def hash_pin(pin: str) -> str:
    return bcrypt.hashpw(pin.encode(), bcrypt.gensalt()).decode()

def verify_pin(pin: str, hashed: str) -> bool:
    return bcrypt.checkpw(pin.encode(), hashed.encode())


app = Flask(__name__)
CORS(app)

# ===================== HEALTH===================
@app.route("/", methods=["GET"])
def health():
    return {"status": "LUME Backend Running"}

# ==================== UNIVERSITIES===========================
@app.route("/api/universities", methods=["GET"])
def get_universities():
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("SELECT id, name FROM universities WHERE status='active'")
    data = c.fetchall()

    c.close()
    conn.close()
    return jsonify(data)
# ==================REGISTER – SEND OTP=======================

@app.route("/api/register/send-otp", methods=["POST"])
def register_send_otp():
    data = request.json
    send_mobile_otp(data["mobile"])
    send_email_otp(data["email"])
    return {"message": "OTP_SENT"}

# ==================REGISTER – VERIFY OTP========================

@app.route("/api/register/verify-otp", methods=["POST"])
def register_verify_otp():
    data = request.json

    if not verify_otp(data["mobile_otp"]):
        return {"message": "INVALID_MOBILE_OTP"}, 400

    if not verify_otp(data["email_otp"]):
        return {"message": "INVALID_EMAIL_OTP"}, 400

    return {"message": "OTP_VERIFIED"}

# ======================== REGISTER – FINAL==========================

@app.route("/api/register", methods=["POST"])
def register_student():
    d = request.json
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    # Validate college student
    c.execute("""
        SELECT id FROM students
        WHERE university_id=%s AND mobile=%s AND email=%s
    """, (d["university_id"], d["mobile"], d["email"]))

    student = c.fetchone()
    if not student:
        c.close()
        conn.close()
        return {"message": "NOT_COLLEGE_STUDENT"}, 403

    # Prevent duplicate registration
    c.execute("""
        SELECT id FROM registered_students
        WHERE student_id=%s
    """, (student["id"],))

    if c.fetchone():
        c.close()
        conn.close()
        return {"message": "ALREADY_REGISTERED"}, 409

    # Create registered student
    c.execute("""
        INSERT INTO registered_students (
            student_id,
            aadhaar_verified,
            pan_verified,
            upi_id
        )
        VALUES (%s, 0, 0, NULL)
    """, (student["id"],))

    reg_id = c.lastrowid

    # Create wallet (ALWAYS inactive initially)
    c.execute("""
        INSERT INTO wallets (registered_student_id, status)
        VALUES (%s, 'inactive')
    """, (reg_id,))

    conn.commit()
    c.close()
    conn.close()

    return {
        "message": "REGISTERED",
        "registered_student_id": reg_id
    }, 201

# =================== LOGIN – SEND OTP=======================

@app.route("/api/login/send-otp", methods=["POST"])
def login_send_otp():
    data = request.json

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT rs.id
        FROM students s
        JOIN registered_students rs ON s.id = rs.student_id
        WHERE s.mobile=%s OR s.email=%s
    """, (data.get("mobile"), data.get("email")))

    user = c.fetchone()
    c.close()
    conn.close()

    if not user:
        return {"message": "NOT_REGISTERED"}, 404

    if data.get("mobile"):
        send_mobile_otp(data["mobile"])
    else:
        send_email_otp(data["email"])

    return {"message": "OTP_SENT"}


# ==============LOGIN – VERIFY OTP===================

@app.route("/api/login/verify-otp", methods=["POST"])
def login_verify_otp():
    d = request.json

    # Validate request body
    if not d or "otp" not in d:
        return {"message": "OTP_REQUIRED"}, 400

    # Validate OTP
    if not verify_otp(d["otp"]):
        return {"message": "INVALID_OTP"}, 400

    # Validate login identifier
    if not d.get("mobile") and not d.get("email"):
        return {"message": "MOBILE_OR_EMAIL_REQUIRED"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                rs.id AS reg_id,
                s.full_name,
                s.mobile,
                s.email,
                rs.upi_id,
                rs.aadhaar_verified,
                rs.pan_verified,
                w.status AS wallet_status
            FROM students s
            JOIN registered_students rs ON s.id = rs.student_id
            JOIN wallets w ON rs.id = w.registered_student_id
            WHERE s.mobile=%s OR s.email=%s
        """, (d.get("mobile"), d.get("email")))

        user = c.fetchone()

        if not user:
            return {"message": "NOT_REGISTERED"}, 404

        return jsonify(user), 200

    except Exception as e:
        # Always return something on exception
        return {
            "message": "LOGIN_VERIFY_FAILED",
            "error": str(e)
        }, 500

    finally:
        c.close()
        conn.close()
# ============== Upload profile image =============
@app.route("/api/profile/upload", methods=["POST"])
def upload_profile_image():
    file = request.files.get("image")
    reg_id = request.form.get("reg_id")

    if not file or not reg_id:
        return {"message": "INVALID_REQUEST"}, 400

    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True) 

    filename = f"profile_{reg_id}.jpg"
    path = os.path.join(upload_dir, filename)

    file.save(path)

    conn = get_db_connection()
    c = conn.cursor()
    image_url = f"http://192.168.0.4:5000/{path}"

    c.execute("""
        UPDATE registered_students
        SET profile_image=%s
        WHERE id=%s
    """, (image_url, reg_id))
    conn.commit()
    c.close()
    conn.close()

    image_url = f"http://192.168.0.4:5000/{path}"
    return {"image_url": image_url}, 200


@app.route("/uploads/<path:filename>")
def serve_uploaded_file(filename):
    return send_from_directory("uploads", filename)

# ======================STUDENT DETAILS (AUTHORITATIVE STATE)=====================

@app.route("/api/student/details/<int:reg_id>", methods=["GET"])
def student_details(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
        s.full_name,
        s.mobile,
        s.email,
        rs.profile_image,
        rs.upi_id,
        rs.aadhaar_verified,
        rs.pan_verified,
        rs.kyc_completion_percent,
        rs.tier,
        rs.total_spent AS total_spent,
        w.status AS wallet_status
        FROM registered_students rs
        JOIN students s ON rs.student_id = s.id
        JOIN wallets w ON rs.id = w.registered_student_id
        WHERE rs.id=%s
    """, (reg_id,))

    data = c.fetchone()
    c.close()
    conn.close()

    return jsonify(data), 200

# ================== Get Recent Payees ==============
@app.route("/api/payments/recent/<int:reg_id>", methods=["GET"])
def get_recent_payments(reg_id):
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    cur.execute("""
        SELECT
            COALESCE(
                wt.counterparty_name,
                s.full_name,
                wt.receiver_upi_id
            ) AS name,

            wt.receiver_upi_id AS identifier,

            CASE
                WHEN wt.receiver_upi_id LIKE '%%@lumepay' THEN 1
                ELSE 0
            END AS isWallet,

            rs.profile_image
        FROM wallet_transactions wt

        JOIN (
            SELECT
                receiver_upi_id,
                MAX(created_at) AS last_txn
            FROM wallet_transactions
            WHERE
                sender_reg_id = %s
                AND status = 'success'
                AND receiver_upi_id IS NOT NULL
            GROUP BY receiver_upi_id
        ) latest
          ON latest.receiver_upi_id = wt.receiver_upi_id
         AND latest.last_txn = wt.created_at

        LEFT JOIN registered_students rs
          ON wt.receiver_reg_id = rs.id
        LEFT JOIN students s
          ON rs.student_id = s.id

        ORDER BY wt.created_at DESC
        LIMIT 8
    """, (reg_id,))

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(rows), 200


# ================= AADHAAR KYC (SEND + VERIFY OTP) =================
@app.route("/api/kyc/aadhaar", methods=["POST"])
def aadhaar_kyc():
    d = request.json

    # BASIC VALIDATION
    if not d or "registered_student_id" not in d or "mobile" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    # ---------------- SEND OTP MODE ----------------
    if "otp" not in d or not d["otp"]:
        send_mobile_otp(d["mobile"])
        return {"message": "AADHAAR_OTP_SENT"}, 200

    # ---------------- VERIFY OTP MODE ----------------
    if not verify_otp(d.get("otp")):
        return {"message": "INVALID_OTP"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    # Check Aadhaar status
    c.execute("""
        SELECT aadhaar_verified FROM registered_students
        WHERE id=%s
    """, (d["registered_student_id"],))

    row = c.fetchone()
    if not row:
        c.close()
        conn.close()
        return {"message": "INVALID_USER"}, 404

    if row["aadhaar_verified"] == 1:
        c.close()
        conn.close()
        return {"message": "AADHAAR_ALREADY_VERIFIED"}, 200

    # Mark Aadhaar verified
    c.execute("""
    UPDATE registered_students
    SET
        aadhaar_verified = 1,
        wallet_status = 'active',
        kyc_completion_percent = 75
    WHERE id=%s
""", (d["registered_student_id"],))


    # Activate wallet
    c.execute("""
    UPDATE wallets
    SET status='active'
    WHERE registered_student_id=%s
""", (d["registered_student_id"],))

    conn.commit()
    c.close()
    conn.close()

    return {
        "message": "AADHAAR_VERIFIED_WALLET_ACTIVE",
        "aadhaar_verified": 1,
        "wallet_status": "active"
    }, 200


# ================= PAN KYC (SEND + VERIFY OTP) =================
@app.route("/api/kyc/pan", methods=["POST"])
def pan_kyc():
    d = request.json

    # BASIC VALIDATION
    if not d or "registered_student_id" not in d or "mobile" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    # ---------------- SEND OTP MODE ----------------
    if "otp" not in d or not d["otp"]:
        send_mobile_otp(d["mobile"])
        return {"message": "PAN_OTP_SENT"}, 200

    # ---------------- VERIFY OTP MODE ----------------
    if not verify_otp(d.get("otp")):
        return {"message": "INVALID_OTP"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    # Check PAN status
    c.execute("""
        SELECT pan_verified FROM registered_students
        WHERE id=%s
    """, (d["registered_student_id"],))

    row = c.fetchone()
    if not row:
        c.close()
        conn.close()
        return {"message": "INVALID_USER"}, 404

    if row["pan_verified"] == 1:
        c.close()
        conn.close()
        return {"message": "PAN_ALREADY_VERIFIED"}, 200

    # Mark PAN verified
    c.execute("""
    UPDATE registered_students
    SET
        pan_verified = 1,
        kyc_completion_percent = 100
    WHERE id=%s
""", (d["registered_student_id"],))


    conn.commit()
    c.close()
    conn.close()

    return {
        "message": "PAN_VERIFIED",
        "pan_verified": 1
    }, 200

# ================ Monthly spent for Verified Users ===================
def _get_monthly_spent(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT IFNULL(SUM(amount), 0) AS total
        FROM wallet_transactions
        WHERE sender_reg_id = %s
          AND status = 'success'
          AND created_at >= DATE_FORMAT(NOW(), '%%Y-%%m-01')
    """, (reg_id,))

    row = c.fetchone()
    c.close()

    return float(row["total"] or 0)

# ========UPDATE / CREATE UPI=============

@app.route("/api/upi/update", methods=["POST"])
def update_upi():
    d = request.json
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT id FROM registered_students
        WHERE upi_id=%s
    """, (d["upi_id"],))

    if c.fetchone():
        c.close()
        conn.close()
        return {"message": "UPI_ALREADY_EXISTS"}, 409

    c.execute("""
        UPDATE registered_students
        SET upi_id=%s
        WHERE id=%s
    """, (d["upi_id"], d["registered_student_id"]))

    conn.commit()
    c.close()
    conn.close()

    return {"message": "UPI_UPDATED"}, 200

# ================= WALLET BALANCE =================
@app.route("/api/wallet/balance/<int:reg_id>", methods=["GET"])
def get_wallet_balance(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT balance
        FROM wallets
        WHERE registered_student_id=%s
    """, (reg_id,))

    row = c.fetchone()
    c.close()
    conn.close()

    if not row:
        return {"message": "WALLET_NOT_FOUND"}, 404

    return {
        "balance": float(row["balance"])
    }, 200

# ================= PAY – SEARCH LUME USER BY MOBILE =================
@app.route("/api/pay/search/mobile", methods=["GET"])
def search_pay_user():
    q = request.args.get("q")

    if not q or len(q) < 3:
        return jsonify([])

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            s.full_name AS name,
            s.mobile AS identifier
        FROM students s
        JOIN registered_students rs ON s.id = rs.student_id
        WHERE s.mobile LIKE %s
        LIMIT 5
    """, (q + "%",))

    data = c.fetchall()
    c.close()
    conn.close()

    return jsonify(data), 200

# ================= WALLET → WALLET TRANSFER =================
@app.route("/api/wallet/transfer", methods=["POST"])
def wallet_to_wallet_transfer():
    d = request.json

    required = ["sender_reg_id", "receiver_mobile", "amount"]
    if not all(k in d for k in required):
        return {"message": "INVALID_REQUEST"}, 400

    try:
        amount = float(d["amount"])
    except:
        return {"message": "INVALID_AMOUNT"}, 400

    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    sender_reg_id = d["sender_reg_id"]
    receiver_identifier = d["receiver_mobile"]
    # ================= UPI MANDATORY CHECK =================
    c.execute("""
        SELECT upi_id
        FROM registered_students
        WHERE id = %s
    """, (sender_reg_id,))
    sender_upi = c.fetchone()

    if not sender_upi or not sender_upi["upi_id"]:
        return {"message": "UPI_REQUIRED"}, 403


    try:
        # ================= FETCH KYC STATUS =================
        c.execute("""
            SELECT aadhaar_verified, pan_verified
            FROM registered_students
            WHERE id = %s
        """, (sender_reg_id,))
        kyc = c.fetchone()

        if not kyc:
            return {"message": "SENDER_NOT_FOUND"}, 404

        aadhaar_verified = kyc["aadhaar_verified"] == 1
        pan_verified = kyc["pan_verified"] == 1

        # ================= KYC ENFORCEMENT =================
        if not aadhaar_verified:
            _log_txn(
                    c,
                    sender_reg_id,
                    None,
                    receiver_identifier,
                    amount,
                    "failed",
                    "AADHAAR_NOT_VERIFIED",
                    "transfer",
                    "wallet"
                )
            conn.commit()
            return {
                "message": "AADHAAR_REQUIRED"
            }, 403

        if aadhaar_verified and not pan_verified:
            # Monthly spent calculation
            c.execute("""
                SELECT IFNULL(SUM(amount), 0) AS total
                FROM wallet_transactions
                WHERE sender_reg_id = %s
                  AND status = 'success'
                  AND created_at >= DATE_FORMAT(NOW(), '%%Y-%%m-01')
            """, (sender_reg_id,))
            row = c.fetchone()
            monthly_spent = float(row["total"] or 0)

            if monthly_spent + amount > 100000:
                _log_txn(
                    c,
                    sender_reg_id,
                    None,
                    receiver_identifier,
                    amount,
                    "failed",
                    "MONTHLY_LIMIT_EXCEEDED",
                    "transfer",
                    "wallet"
                )

                conn.commit()
                return {
                    "message": "MONTHLY_LIMIT_EXCEEDED"
                }, 403

        # ================= LOCK SENDER WALLET =================
        c.execute("""
            SELECT balance, status
            FROM wallets
            WHERE registered_student_id=%s
            FOR UPDATE
        """, (sender_reg_id,))
        sender = c.fetchone()

        if not sender:
            return {"message": "SENDER_NOT_FOUND"}, 404

        if sender["status"] != "active":
            _log_txn(
                    c,
                    sender_reg_id,
                    None,
                    receiver_identifier,
                    amount,
                    "failed",
                    "WALLET_INACTIVE",
                    "transfer",
                    "wallet"
                )
            conn.commit()
            return {"message": "WALLET_INACTIVE"}, 403

        if sender["balance"] < amount:
            _log_txn(
                    c,
                    sender_reg_id,
                    None,
                    receiver_identifier,
                    amount,
                    "failed",
                    "INSUFFICIENT_BALANCE",
                    "transfer",
                    "wallet"
                )

            conn.commit()
            return {"message": "INSUFFICIENT_BALANCE"}, 400

        # ================= FETCH RECEIVER =================
        c.execute("""
            SELECT
              rs.id AS receiver_reg_id,
              rs.upi_id,
              s.full_name
            FROM students s
            JOIN registered_students rs
              ON s.id = rs.student_id
            WHERE s.mobile=%s
        """, (receiver_identifier,))
        receiver = c.fetchone()

        if not receiver:
            _log_txn(
                    c,
                    sender_reg_id,
                    None,
                    receiver_identifier,
                    amount,
                    "failed",
                    "RECEIVER_NOT_FOUND",
                    "transfer",
                    "wallet"
                )

            conn.commit()
            return {"message": "RECEIVER_NOT_FOUND"}, 404

        receiver_reg_id = receiver["receiver_reg_id"]
        receiver_upi_id = receiver["upi_id"] or receiver_identifier

        # ================= DEBIT SENDER =================
        c.execute("""
            UPDATE wallets
            SET balance = balance - %s
            WHERE registered_student_id=%s
        """, (amount, sender_reg_id))

        # ================= CREDIT RECEIVER =================
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
        """, (amount, receiver_reg_id))

        # ================= LOG SUCCESS TXN =================
        _log_txn(
            c,
            sender_reg_id,
            receiver_reg_id,
            receiver_upi_id,
            amount,
            "success",
            None,
            "transfer",
            "wallet",
            receiver["full_name"]
        )
        update_user_tier(conn, c, sender_reg_id)

        conn.commit()
        return {"message": "TRANSFER_SUCCESS"}, 200

    except Exception as e:
        conn.rollback()

        _log_txn(
            c,
            sender_reg_id,
            None,
            receiver_identifier,
            amount,
            "failed",
            str(e),
            "transfer"
        )
        conn.commit()

        return {"message": "TRANSFER_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# =================== Wallet > UPI ===========================
@app.route("/api/pay/upi", methods=["POST"])
def wallet_to_upi_payment():
    d = request.json

    required = ["sender_reg_id", "upi_id", "amount"]
    if not all(k in d for k in required):
        return {"message": "INVALID_REQUEST"}, 400

    amount = float(d["amount"])
    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    sender_id = d["sender_reg_id"]
    upi_id = d["upi_id"].lower()

    # Check if this UPI belongs to a LUME user
    receiver_reg_id = get_reg_id_by_upi(upi_id)

    # ===== Extract name for QR payments =====
    upi_name = d.get("name")

    if not upi_name and "pn=" in d.get("upi_id", ""):
        try:
            from urllib.parse import urlparse, parse_qs
            parsed = urlparse(d["upi_id"])
            params = parse_qs(parsed.query)
            upi_name = params.get("pn", [None])[0]
        except:
            upi_name = None

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ================= UPI MANDATORY CHECK =================
        c.execute("""
            SELECT upi_id
            FROM registered_students
            WHERE id = %s
        """, (sender_id,))
        sender = c.fetchone()

        if not sender or not sender["upi_id"]:
            return {"message": "UPI_REQUIRED"}, 403

        # ================= LOCK SENDER WALLET =================
        c.execute("""
            SELECT balance, status
            FROM wallets
            WHERE registered_student_id = %s
            FOR UPDATE
        """, (sender_id,))
        wallet = c.fetchone()

        if not wallet or wallet["status"] != "active":
            _log_txn(
                c,
                sender_id,
                None,
                upi_id,
                amount,
                "failed",
                "WALLET_INACTIVE",
                "upi",
                "upi",
                upi_name
            )
            conn.commit()
            return {"message": "WALLET_INACTIVE"}, 403

        if wallet["balance"] < amount:
            _log_txn(
                c,
                sender_id,
                None,
                upi_id,
                amount,
                "failed",
                "INSUFFICIENT_BALANCE",
                "upi",
                "upi",
                upi_name
            )
            conn.commit()
            return {"message": "INSUFFICIENT_BALANCE"}, 400

        # ================= DEBIT SENDER =================
        c.execute("""
            UPDATE wallets
            SET balance = balance - %s
            WHERE registered_student_id = %s
        """, (amount, sender_id))

        # ================= INTERNAL vs EXTERNAL =================
        if receiver_reg_id:
            # INTERNAL QR
            c.execute("""
                UPDATE wallets
                SET balance = balance + %s
                WHERE registered_student_id = %s
            """, (amount, receiver_reg_id))

            _log_txn(
                c,
                sender_id,
                receiver_reg_id,
                upi_id,
                amount,
                "success",
                None,
                "transfer",
                "wallet",
                upi_name
            )
        else:
            # EXTERNAL UPI
            _log_txn(
                c,
                sender_id,
                None,
                upi_id,
                amount,
                "success",
                None,
                "upi",
                "upi",
                upi_name
            )
        update_user_tier(conn, c, sender_id)

        conn.commit()
        return {"message": "UPI_PAYMENT_SUCCESS"}, 200

    except Exception as e:
        conn.rollback()

        _log_txn(
            c,
            sender_id,
            None,
            upi_id,
            amount,
            "failed",
            str(e),
            "upi",
            "upi",
            upi_name
        )
        conn.commit()
        return {"message": "UPI_PAYMENT_FAILED"}, 500

    finally:
        c.close()
        conn.close()
        
# =========== wallet > wallet Transfer internal ============
def wallet_to_wallet_transfer_internal(sender_id, receiver_id, receiver_upi, amount):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ================= UPI MANDATORY CHECK =================
        c.execute("""
            SELECT upi_id
            FROM registered_students
            WHERE id = %s
        """, (sender_id,))
        sender_upi = c.fetchone()

        if not sender_upi or not sender_upi["upi_id"]:
            _log_txn(
                c,
                sender_id,
                receiver_id,
                receiver_upi,
                amount,
                "failed",
                "UPI_NOT_CREATED",
                "transfer",
                "wallet"
            )
            conn.commit()
            return {"message": "UPI_REQUIRED"}, 403

        # ================= LOCK SENDER WALLET =================
        c.execute("""
            SELECT balance, status
            FROM wallets
            WHERE registered_student_id = %s
            FOR UPDATE
        """, (sender_id,))
        sender_wallet = c.fetchone()

        if not sender_wallet or sender_wallet["status"] != "active":
            _log_txn(
                c,
                sender_id,
                receiver_id,
                receiver_upi,
                amount,
                "failed",
                "WALLET_INACTIVE",
                "transfer",
                "wallet"
            )
            conn.commit()
            return {"message": "WALLET_INACTIVE"}, 403

        if sender_wallet["balance"] < amount:
            _log_txn(
                c,
                sender_id,
                receiver_id,
                receiver_upi,
                amount,
                "failed",
                "INSUFFICIENT_BALANCE",
                "transfer",
                "wallet"
            )
            conn.commit()
            return {"message": "INSUFFICIENT_BALANCE"}, 400

        # ================= DEBIT SENDER =================
        c.execute("""
            UPDATE wallets
            SET balance = balance - %s
            WHERE registered_student_id = %s
        """, (amount, sender_id))

        # ================= CREDIT RECEIVER =================
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id = %s
        """, (amount, receiver_id))

        # ================= LOG SUCCESS TXN =================
        _log_txn(
            c,
            sender_id,
            receiver_id,
            receiver_upi,
            amount,
            "success",
            None,
            "transfer",
            "wallet"
        )
        update_user_tier(conn, c, sender_id)
        conn.commit()
        return {"message": "TRANSFER_SUCCESS"}, 200

    except Exception as e:
        conn.rollback()

        _log_txn(
            c,
            sender_id,
            receiver_id,
            receiver_upi,
            amount,
            "failed",
            str(e),
            "transfer",
            "wallet"
        )
        conn.commit()

        return {"message": "TRANSFER_FAILED"}, 500

    finally:
        c.close()
        conn.close()


# ================= SEARCH BY INTERNAL UPI =================
@app.route("/api/pay/search/upi", methods=["GET"])
def search_user_by_upi():
    q = request.args.get("q", "").lower()

    if not q or "@lumepay" not in q:
        return [], 200

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
              rs.id AS reg_id,
              s.full_name AS name,
              rs.upi_id AS identifier
            FROM registered_students rs
            JOIN students s ON rs.student_id = s.id
            WHERE LOWER(rs.upi_id) LIKE %s
            LIMIT 5
        """, (f"{q}%",))

        rows = c.fetchall()
        return rows, 200

    except Exception as e:
        print("UPI SEARCH ERROR:", e)
        return [], 200

    finally:
        c.close()
        conn.close()
# ===== Helper =========
def get_reg_id_by_upi(upi_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT id
        FROM registered_students
        WHERE LOWER(upi_id) = %s
    """, (upi_id.lower(),))

    row = c.fetchone()
    c.close()
    conn.close()

    return row["id"] if row else None

# ================= TRANSACTION LOGGER =================
def _log_txn(
    c,
    sender_reg_id,
    receiver_reg_id,
    receiver_identifier,
    amount,
    status,
    failure_reason,
    txn_type,
    payment_method="wallet",
    counterparty_name=None
):
    if counterparty_name:
        counterparty_name = counterparty_name.strip()
    else:
        counterparty_name = None

    c.execute("""
        INSERT INTO wallet_transactions (
            sender_reg_id,
            receiver_reg_id,
            receiver_upi_id,
            counterparty_name,
            amount,
            status,
            failure_reason,
            txn_type,
            payment_method
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        sender_reg_id,
        receiver_reg_id,
        receiver_identifier,
        counterparty_name,
        float(amount),
        status,
        failure_reason,
        txn_type,
        payment_method
    ))


# ================= TRANSACTION HISTORY =================
@app.route("/api/transactions/<int:reg_id>", methods=["GET"])
def get_transactions(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
              wt.id,
              wt.amount,
              wt.status,
              wt.txn_type,
              wt.created_at,
              wt.failure_reason,
              wt.sender_reg_id,
              wt.receiver_reg_id,
              wt.receiver_upi_id,
              wt.counterparty_name,

              s_sender.full_name AS sender_name,
              rs_sender.upi_id AS sender_upi_id,
              s_receiver.full_name AS receiver_name

            FROM wallet_transactions wt

            LEFT JOIN registered_students rs_sender
              ON wt.sender_reg_id = rs_sender.id
            LEFT JOIN students s_sender
              ON rs_sender.student_id = s_sender.id

            LEFT JOIN registered_students rs_receiver
              ON wt.receiver_reg_id = rs_receiver.id
            LEFT JOIN students s_receiver
              ON rs_receiver.student_id = s_receiver.id

            WHERE wt.sender_reg_id = %s
               OR wt.receiver_reg_id = %s

            ORDER BY wt.created_at DESC
        """, (reg_id, reg_id))

        rows = c.fetchall()
        result = []

        for t in rows:
            txn_type = t["txn_type"]
            sender_id = t["sender_reg_id"]

            payment_type = "Wallet"
            display_name = ""
            upi_id = ""

            # ================= WALLET TOP-UP =================
            if txn_type == "add_money":
                direction = "topup"
                title = "Wallet Top-Up"
                display_name = "Wallet"
                upi_id = ""
                payment_type = "Wallet"

            # ================= PAID (DEBIT) =================
            elif sender_id == reg_id:
                direction = "debit"
                display_name = (
                    t["counterparty_name"]
                    or t["receiver_name"]
                    or "Unknown"
                )

                title = f"Paid to {display_name}"
                upi_id = t["receiver_upi_id"] or ""
                payment_type = "Wallet" if txn_type == "transfer" else "UPI"

            # ================= RECEIVED (CREDIT) =================
            else:
                direction = "credit"

                display_name = (
                    t["sender_name"]
                    or t["counterparty_name"]
                    or "Unknown"
                )

                title = f"Received from {display_name}"
                upi_id = t["sender_upi_id"] or ""
                payment_type = "Wallet" if txn_type == "transfer" else "UPI"

            # ================= STATUS TEXT =================
            if t["status"] == "success":
                status_text = "Success"
            elif t["status"] == "failed":
                if t["failure_reason"] == "USER_CANCELLED":
                    status_text = "Cancelled"
                elif t["failure_reason"] == "AUTO_CANCELLED_TIMEOUT":
                    status_text = "Expired"
                else:
                    status_text = "Failed"
            else:
                status_text = "Pending"

            result.append({
                "id": t["id"],
                "amount": float(t["amount"]),
                "direction": direction,
                "display_name": display_name,
                "upi_id": upi_id,

                "title": title,
                "payment_type": payment_type,
                "status": t["status"],
                "status_text": status_text,
                "failure_reason": t["failure_reason"],
                "created_at": (
                    t["created_at"].isoformat()
                    if t["created_at"]
                    else None
                ),
            })

        return result, 200

    except Exception as e:
        print("GET TRANSACTIONS ERROR:", e)
        return {"message": "FAILED_TO_FETCH_TRANSACTIONS"}, 500

    finally:
        c.close()
        conn.close()
# ================= ADD MONEY TO WALLET =================
@app.route("/api/wallet/add-money", methods=["POST"])
def add_money_to_wallet():
    d = request.json

    # -------- VALIDATION --------
    if not d or "registered_student_id" not in d or "amount" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    reg_id = d["registered_student_id"]
    amount = float(d["amount"])

    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # -------- CHECK WALLET --------
        c.execute("""
            SELECT balance, status
            FROM wallets
            WHERE registered_student_id=%s
            FOR UPDATE
        """, (reg_id,))

        wallet = c.fetchone()

        if not wallet:
            return {"message": "WALLET_NOT_FOUND"}, 404

        if wallet["status"] != "active":
            _log_add_money_txn(
                c, reg_id, amount, "failed", "WALLET_INACTIVE"
            )
            conn.commit()
            return {"message": "WALLET_INACTIVE"}, 403

        # -------- ADD MONEY --------
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
        """, (amount, reg_id))

        # -------- TRANSACTION LOG --------
        _log_add_money_txn(
            c, reg_id, amount, "success", None
        )

        conn.commit()

        return {
            "message": "ADD_MONEY_SUCCESS",
            "added_amount": amount
        }, 200

    except Exception as e:
        conn.rollback()
        _log_add_money_txn(
            c, reg_id, amount, "failed", str(e)
        )
        conn.commit()
        return {
            "message": "ADD_MONEY_FAILED",
            "error": str(e)
        }, 500

    finally:
        c.close()
        conn.close()


# ================= ADD MONEY TXN LOGGER =================
def _log_add_money_txn(
    c,
    reg_id,
    amount,
    status,
    failure_reason
):
    c.execute("""
        INSERT INTO wallet_transactions (
            sender_reg_id,
            receiver_reg_id,
            receiver_upi_id,
            amount,
            status,
            failure_reason,
            txn_type
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (
        reg_id,          # sender
        reg_id,          # receiver (self)
        None,            # receiver_upi_id → allowed now
        float(amount),
        status,
        failure_reason,
        "add_money"
    ))


# =================  Notifications ======================
@app.route("/api/notifications/unread-count/<int:reg_id>", methods=["GET"])
def unread_notifications_count(reg_id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT COUNT(*) AS unread
        FROM notifications
        WHERE reg_id = %s AND is_read = 0
    """, (reg_id,))

    count = cursor.fetchone()["unread"]

    cursor.close()
    conn.close()

    return jsonify({
        "unread": count
    }), 200
# ================= Reset PIN ==================
@app.route("/api/pin/set", methods=["POST"])
def set_pin():
    d = request.json
    reg_id = d["reg_id"]
    pin_type = d["type"]  # wallet | card
    pin = d["pin"]

    conn = get_db_connection()
    c = conn.cursor()

    hashed = hash_pin(pin)

    if pin_type == "wallet":
        c.execute("""
            INSERT INTO wallet_security (reg_id, wallet_pin_hash)
            VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE
              wallet_pin_hash=%s,
              wallet_pin_attempts=0,
              wallet_pin_locked=FALSE
        """, (reg_id, hashed, hashed))

    else:
        c.execute("""
            INSERT INTO wallet_security (reg_id, card_pin_hash)
            VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE
              card_pin_hash=%s,
              card_pin_attempts=0,
              card_pin_locked=FALSE
        """, (reg_id, hashed, hashed))

    conn.commit()
    return {"message": "PIN_SET_SUCCESS"}, 200

# ============ PIN STATUS  ===============
@app.route("/api/pin/status/<int:reg_id>", methods=["GET"])
def get_pin_status(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            wallet_pin_hash IS NOT NULL AS wallet_pin_set,
            card_pin_hash IS NOT NULL AS card_pin_set
        FROM wallet_security
        WHERE reg_id=%s
    """, (reg_id,))

    row = c.fetchone()
    c.close()
    conn.close()

    if not row:
        return {
            "wallet_pin_set": False,
            "card_pin_set": False
        }, 200

    return {
        "wallet_pin_set": bool(row["wallet_pin_set"]),
        "card_pin_set": bool(row["card_pin_set"])
    }, 200

# ==================== Verify PIN ======================
@app.route("/api/pin/verify", methods=["POST"])
def verify_pin_api():
    d = request.json

    required = ["reg_id", "type", "pin"]
    if not all(k in d for k in required):
        return {"message": "INVALID_REQUEST"}, 400

    reg_id = d["reg_id"]
    pin_type = d["type"]  # wallet | card
    pin = d["pin"]

    if pin_type not in ["wallet", "card"]:
        return {"message": "INVALID_PIN_TYPE"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT *
            FROM wallet_security
            WHERE reg_id=%s
            FOR UPDATE
        """, (reg_id,))
        sec = c.fetchone()

        if not sec:
            return {"message": "PIN_NOT_SET"}, 400

        # ---------------- WALLET PIN ----------------
        if pin_type == "wallet":
            if sec["wallet_pin_locked"]:
                return {
                    "message": "WALLET_PIN_LOCKED",
                    "action": "RESET_REQUIRED"
                }, 423

            valid = verify_pin(pin, sec["wallet_pin_hash"])

            if not valid:
                attempts = sec["wallet_pin_attempts"] + 1
                locked = attempts >= 3

                c.execute("""
                    UPDATE wallet_security
                    SET wallet_pin_attempts=%s,
                        wallet_pin_locked=%s
                    WHERE reg_id=%s
                """, (attempts, locked, reg_id))
                conn.commit()

                return {
                    "message": "INVALID_PIN",
                    "attempts_left": max(0, 3 - attempts),
                    "locked": locked
                }, 401

            #  SUCCESS → RESET ATTEMPTS
            c.execute("""
                UPDATE wallet_security
                SET wallet_pin_attempts=0
                WHERE reg_id=%s
            """, (reg_id,))
            conn.commit()

            return {"message": "PIN_VERIFIED"}, 200

        # ---------------- CARD PIN ----------------
        else:
            if sec["card_pin_locked"]:
                return {
                    "message": "CARD_PIN_LOCKED",
                    "action": "RESET_REQUIRED"
                }, 423

            valid = verify_pin(pin, sec["card_pin_hash"])

            if not valid:
                attempts = sec["card_pin_attempts"] + 1
                locked = attempts >= 3

                c.execute("""
                    UPDATE wallet_security
                    SET card_pin_attempts=%s,
                        card_pin_locked=%s
                    WHERE reg_id=%s
                """, (attempts, locked, reg_id))
                conn.commit()

                return {
                    "message": "INVALID_PIN",
                    "attempts_left": max(0, 3 - attempts),
                    "locked": locked
                }, 401

            #  SUCCESS → RESET ATTEMPTS
            c.execute("""
                UPDATE wallet_security
                SET card_pin_attempts=0
                WHERE reg_id=%s
            """, (reg_id,))
            conn.commit()

            return {"message": "PIN_VERIFIED"}, 200

    except Exception as e:
        conn.rollback()
        print("VERIFY PIN ERROR:", e)
        return {"message": "PIN_VERIFY_FAILED"}, 500

    finally:
        c.close()
        conn.close()
# ==== PIN  OTP ===========
@app.route("/api/pin/send-otp", methods=["POST"])
def send_pin_otp():
    d = request.json
    reg_id = d.get("reg_id")

    if not reg_id:
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT s.mobile
        FROM registered_students rs
        JOIN students s ON rs.student_id = s.id
        WHERE rs.id = %s
    """, (reg_id,))

    user = c.fetchone()
    c.close()
    conn.close()

    if not user:
        return {"message": "USER_NOT_FOUND"}, 404

    send_mobile_otp(user["mobile"])
    return {"message": "OTP_SENT"}, 200
# ============  PIN verify OTp ======
@app.route("/api/pin/verify-otp", methods=["POST"])
def verify_pin_otp():
    d = request.json
    otp = d.get("otp")

    if not otp:
        return {"message": "OTP_REQUIRED"}, 400

    if not verify_otp(otp):
        return {"message": "INVALID_OTP"}, 400

    return {"message": "OTP_VERIFIED"}, 200
      
# =============== Add money =================
@app.route("/api/wallet/add-money/init", methods=["POST"])
def init_add_money():
    d = request.json

    if not d or "reg_id" not in d or "amount" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    amount = float(d["amount"])
    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    # 🔹 Fetch mobile
    c.execute("""
        SELECT s.mobile
        FROM registered_students rs
        JOIN students s ON rs.student_id = s.id
        WHERE rs.id = %s
    """, (d["reg_id"],))

    user = c.fetchone()
    if not user:
        c.close()
        conn.close()
        return {"message": "USER_NOT_FOUND"}, 404

    send_mobile_otp(user["mobile"])

    c.execute("""
        INSERT INTO wallet_transactions (
            sender_reg_id,
            receiver_reg_id,
            amount,
            payment_method,
            status,
            txn_type,
            card_id
        )
        VALUES (%s, %s, %s, 'card', 'pending', 'add_money', %s)
    """, (
        d["reg_id"],
        d["reg_id"],
        amount,
        d.get("saved_card_id")
    ))

    txn_id = c.lastrowid
    conn.commit()
    c.close()
    conn.close()

    return {"txn_id": txn_id}, 200

# ============= get cards ===============
@app.route("/api/cards/<int:reg_id>", methods=["GET"])
def get_cards_by_reg_id(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            id,
            last4,
            card_brand,
            card_type
        FROM saved_cards
        WHERE reg_id=%s AND is_active=1
    """, (reg_id,))

    cards = c.fetchall()
    c.close()
    conn.close()

    return cards, 200

# =============== Get Saved Cards ==================
@app.route("/api/cards/saved/<int:reg_id>", methods=["GET"])
def get_saved_cards(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            id,
            last4,
            card_brand,
            card_type
        FROM saved_cards
        WHERE reg_id=%s AND is_active=1
    """, (reg_id,))

    cards = c.fetchall()
    c.close()
    conn.close()

    return cards, 200
# ============== Cancel add money =================
@app.route("/api/wallet/add-money/cancel", methods=["POST"])
def cancel_add_money():
    d = request.json
    txn_id = d.get("txn_id")

    if not txn_id:
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT status
            FROM wallet_transactions
            WHERE id=%s
            FOR UPDATE
        """, (txn_id,))

        txn = c.fetchone()
        if not txn:
            return {"message": "INVALID_TXN"}, 404

        if txn["status"] != "pending":
            return {
                "message": "TXN_ALREADY_PROCESSED",
                "status": txn["status"]
            }, 200

        c.execute("""
            UPDATE wallet_transactions
            SET status='failed',
                failure_reason='USER_CANCELLED'
            WHERE id=%s
        """, (txn_id,))

        conn.commit()
        return {"message": "PAYMENT_CANCELLED"}, 200

    except Exception as e:
        conn.rollback()
        return {"message": "CANCEL_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# ============== Verify add money =============
@app.route("/api/wallet/add-money/verify", methods=["POST"])
def verify_add_money():
    auto_cancel_expired_pending_transactions()
    d = request.json
    txn_id = d.get("txn_id")

    if not txn_id or "otp" not in d:
        return {"status": "failed", "reason": "INVALID_REQUEST"}, 400

    if not verify_otp(d["otp"]):
        _update_txn_status(txn_id, "failed", "INVALID_OTP")
        return {"status": "failed"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT sender_reg_id, amount, status
            FROM wallet_transactions
            WHERE id=%s
            FOR UPDATE
        """, (txn_id,))

        txn = c.fetchone()
        if not txn:
            return {"status": "failed", "reason": "INVALID_TXN"}, 400

        if txn["status"] != "pending":
            return {
                "status": txn["status"],
                "reason": txn.get("failure_reason")
            }, 200

        # Credit wallet
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
        """, (txn["amount"], txn["sender_reg_id"]))

        #  Mark success
        c.execute("""
            UPDATE wallet_transactions
            SET status='success', failure_reason=NULL
            WHERE id=%s
        """, (txn_id,))
        update_user_tier(conn, c, txn["sender_reg_id"])


        #  Save card ONLY if checkbox selected
        if d.get("save_card") is True:
            save_card_token(d.get("card_data", {}), txn["sender_reg_id"])

        conn.commit()
        return {"status": "success"}, 200

    except Exception as e:
        conn.rollback()
        _update_txn_status(txn_id, "failed", str(e))
        return {"status": "failed"}, 500

    finally:
        c.close()
        conn.close()


# helpers
def _update_txn_status(txn_id, status, reason):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        UPDATE wallet_transactions
        SET status=%s, failure_reason=%s
        WHERE id=%s
    """, (status, reason, txn_id))
    conn.commit()
    c.close()
    conn.close()


def save_card_token(card_data, reg_id):
    if not card_data:
        return

    card_number = card_data.get("card_number", "")
    if len(card_number) < 4:
        return

    last4 = card_number[-4:]

    brand = card_data.get("brand", "unknown")
    card_type = card_data.get("cardType") or card_data.get("card_type") or "debit"

    token = "tok_" + last4

    conn = get_db_connection()
    c = conn.cursor()

    c.execute("""
        INSERT INTO saved_cards (
            reg_id,
            last4,
            card_token,
            card_brand,
            card_type
        )
        VALUES (%s, %s, %s, %s, %s)
    """, (
        reg_id,
        last4,
        token,
        brand,
        card_type
    ))

    conn.commit()
    c.close()
    conn.close()



# ================== Save cards ===================
@app.route("/api/cards/save", methods=["POST"])
def save_card():
    d = request.json

    last4 = d["card_number"][-4:]
    brand = d.get("brand", "unknown")
    card_type = d.get("cardType", "debit") 

    conn = get_db_connection()
    c = conn.cursor()

    c.execute("""
        INSERT INTO saved_cards (reg_id, last4, card_brand, card_type)
        VALUES (%s, %s, %s, %s)
    """, (
        d["reg_id"],
        last4,
        brand,
        card_type
    ))

    conn.commit()
    c.close()
    conn.close()

    return {"status": "success"}, 200

# ==================== delete saved cards ===============
@app.route("/api/cards/<int:card_id>", methods=["DELETE"])
def delete_card(card_id):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("DELETE FROM saved_cards WHERE id=%s", (card_id,))
    conn.commit()
    c.close()
    conn.close()
    return {"status": "deleted"}, 200
# ================= AUTO CANCEL PENDING TXNS =================
def auto_cancel_expired_pending_transactions():
    conn = get_db_connection()
    c = conn.cursor()

    try:
        c.execute("""
            UPDATE wallet_transactions
            SET
                status = 'failed',
                failure_reason = 'AUTO_CANCELLED_TIMEOUT'
            WHERE status = 'pending'
              AND txn_type = 'add_money'
              AND created_at <= (NOW() - INTERVAL 6 HOUR)
        """)
        conn.commit()
    finally:
        c.close()
        conn.close()
        
# ==== Tier =====
def update_user_tier(conn, c, reg_id):
    c.execute("""
        SELECT IFNULL(SUM(CAST(amount AS DECIMAL(10,2))), 0) AS total
        FROM wallet_transactions
        WHERE sender_reg_id = %s
          AND status = 'success'
          AND (
                txn_type IN ('transfer', 'upi')
          )
    """, (reg_id,))

    total = float(c.fetchone()["total"] or 0)

    if total >= 75000:
        tier = "platinum"
    elif total >= 25000:
        tier = "gold"
    else:
        tier = "silver"

    c.execute("""
        UPDATE registered_students
        SET total_spent=%s,
            tier=%s
        WHERE id=%s
    """, (total, tier, reg_id))


#========================= RUN=========================

"""if __name__ == "__main__":
    app.run(debug=True)"""
if __name__ == "__main__":
    app.run(
    host="0.0.0.0",
    port=5000,
    debug=True
)