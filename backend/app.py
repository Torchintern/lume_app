from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db_connection
from otp_service import send_mobile_otp, send_email_otp, verify_otp
import bcrypt
import os
from flask import send_from_directory
from datetime import datetime
import math
import traceback
from reward_engine import generate_reward
import random
from dateutil.relativedelta import relativedelta


def hash_pin(pin: str) -> str:
    return bcrypt.hashpw(pin.encode(), bcrypt.gensalt()).decode()

def verify_pin(pin: str, hashed: str) -> bool:
    return bcrypt.checkpw(pin.encode(), hashed.encode())

import re

def mask_pan(pan: str) -> str:
    """
    Masks PAN digits, keeps alphabets.
    Example: ABCDE1234F → ABCDEXXXXF
    """
    return re.sub(r'\d', 'X', pan.upper())

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
        upi_id,
        reward_points,
        tier,
        tier_cycle_start
    )
    VALUES (%s,0,0,NULL,0,'silver',%s)
    """, (student["id"],
          get_cycle_start().date()
          ))

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
                rs.profile_image,
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

    timestamp = int(datetime.now().timestamp())
    filename = f"profile_{reg_id}_{timestamp}.jpg"
    path = os.path.join(upload_dir, filename)

    file.save(path)

    conn = get_db_connection()
    c = conn.cursor()
    image_url = f"http://192.168.0.3:5000/{path}"

    c.execute("""
        UPDATE registered_students
        SET profile_image=%s
        WHERE id=%s
    """, (image_url, reg_id))
    conn.commit()
    c.close()
    conn.close()

    image_url = f"http://192.168.0.3:5000/{path}"
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
        u.name AS college,
        rs.profile_image,
        rs.upi_id,
        rs.aadhaar_verified,
        rs.pan_verified,
        rs.aadhaar_last4,
        rs.pan_masked,
        rs.kyc_completion_percent,
        rs.tier,
        rs.reward_points,
        rs.tier_cycle_start,
        rs.total_spent AS total_spent,
        w.status AS wallet_status
        FROM registered_students rs
        JOIN students s ON rs.student_id = s.id
        JOIN universities u ON s.university_id = u.id 
        JOIN wallets w ON rs.id = w.registered_student_id
        WHERE rs.id=%s
    """, (reg_id,))

    data = c.fetchone()

    # ================= GREETING DATA =================
    if data:
        # Server Time
        data["server_time"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        # TEMP Weather (Later can replace with real API)
        data["weather_temp"] = 26
        data["weather_condition"] = "Partly Cloudy"

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

    # ---------------- BASIC VALIDATION ----------------
    if not d or "registered_student_id" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # FETCH MOBILE + STATUS FROM DB (DO NOT TRUST FRONTEND)
        c.execute("""
            SELECT
                s.mobile,
                rs.aadhaar_verified
            FROM registered_students rs
            JOIN students s ON rs.student_id = s.id
            WHERE rs.id = %s
        """, (d["registered_student_id"],))

        row = c.fetchone()
        if not row:
            return {"message": "INVALID_USER"}, 404

        mobile = row["mobile"]

        # ---------------- SEND OTP MODE ----------------
        if "otp" not in d or not d["otp"]:
            send_mobile_otp(mobile)
            return {"message": "AADHAAR_OTP_SENT"}, 200

        # ---------------- VERIFY OTP ----------------
        if not verify_otp(d["otp"]):
            return {"message": "INVALID_OTP"}, 400

        # ---------------- ALREADY VERIFIED ----------------
        if row["aadhaar_verified"] == 1:
            return {"message": "AADHAAR_ALREADY_VERIFIED"}, 200

        # ---------------- VALIDATE AADHAAR NUMBER ----------------
        aadhaar_number = d.get("aadhaar_number")
        if not aadhaar_number or len(aadhaar_number) != 12 or not aadhaar_number.isdigit():
            return {"message": "INVALID_AADHAAR_NUMBER"}, 400

        #  STORE ONLY LAST 4 DIGITS
        aadhaar_last4 = aadhaar_number[-4:]

        # ---------------- UPDATE REGISTERED STUDENT ----------------
        c.execute("""
            UPDATE registered_students
            SET
                aadhaar_verified = 1,
                aadhaar_last4 = %s,
                kyc_completion_percent = 75
            WHERE id = %s
        """, (
            aadhaar_last4,
            d["registered_student_id"]
        ))

        # ---------------- ACTIVATE WALLET ----------------
        c.execute("""
            UPDATE wallets
            SET status = 'active'
            WHERE registered_student_id = %s
        """, (d["registered_student_id"],))

        conn.commit()

        return {
            "message": "AADHAAR_VERIFIED_WALLET_ACTIVE",
            "aadhaar_verified": 1,
            "aadhaar_last4": aadhaar_last4,
            "wallet_status": "active"
        }, 200

    except Exception as e:
        conn.rollback()
        print("AADHAAR KYC ERROR:", e)
        return {"message": "AADHAAR_KYC_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# ================= PAN KYC (SEND + VERIFY OTP) =================
@app.route("/api/kyc/pan", methods=["POST"])
def pan_kyc():
    d = request.json

    # ---------------- BASIC VALIDATION ----------------
    if not d or "registered_student_id" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # 🔹 FETCH MOBILE + PAN STATUS FROM DB
        c.execute("""
            SELECT
                s.mobile,
                rs.pan_verified
            FROM registered_students rs
            JOIN students s ON rs.student_id = s.id
            WHERE rs.id = %s
        """, (d["registered_student_id"],))

        row = c.fetchone()
        if not row:
            return {"message": "INVALID_USER"}, 404

        mobile = row["mobile"]

        # ---------------- SEND OTP MODE ----------------
        if "otp" not in d or not d["otp"]:
            send_mobile_otp(mobile)
            return {"message": "PAN_OTP_SENT"}, 200

        # ---------------- VERIFY OTP ----------------
        if not verify_otp(d["otp"]):
            return {"message": "INVALID_OTP"}, 400

        # ---------------- ALREADY VERIFIED ----------------
        if row["pan_verified"] == 1:
            return {"message": "PAN_ALREADY_VERIFIED"}, 200

        # ---------------- VALIDATE PAN NUMBER ----------------
        pan_number = d.get("pan_number", "").upper()

        # PAN regex: 5 letters + 4 digits + 1 letter
        if not re.match(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$', pan_number):
            return {"message": "INVALID_PAN_NUMBER"}, 400

        # MASK PAN (digits only)
        pan_masked = mask_pan(pan_number)

        # ---------------- UPDATE REGISTERED STUDENT ----------------
        c.execute("""
            UPDATE registered_students
            SET
                pan_verified = 1,
                pan_masked = %s,
                kyc_completion_percent = 100
            WHERE id = %s
        """, (
            pan_masked,
            d["registered_student_id"]
        ))
        
        # AUTO CREATE CARD AFTER KYC 100%
        create_card_for_user(
            d["registered_student_id"],
            conn,
            c
        )


        conn.commit()

        return {
            "message": "PAN_VERIFIED",
            "pan_verified": 1
        }, 200

    except Exception as e:
        conn.rollback()
        print("PAN KYC ERROR:", e)
        return {"message": "PAN_KYC_FAILED"}, 500

    finally:
        c.close()
        conn.close()

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
    conn.close()
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
        rs.id AS reg_id,
        s.full_name AS name,
        s.mobile AS identifier,
        rs.profile_image
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
        txn_id = c.lastrowid
        reward = update_user_points_and_tier(
                conn, c, sender_reg_id, amount
            )
        token = generate_reward(
            c,
            sender_reg_id,
            txn_id,
            amount,
            reward["tier"]
        )
        # ===== REWARD EARNED NOTIFICATION (DEDUP SAFE) =====
        c.execute("""
        SELECT id FROM notifications
        WHERE reg_id=%s AND ref_id=%s AND type='reward_earned'
        LIMIT 1
        """,(sender_reg_id, txn_id))

        if not c.fetchone():

            c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                amount,
                ref_id,
                is_read
            )
            VALUES (%s,%s,%s,%s,%s,%s,0)
            """, (
                sender_reg_id,
                "Reward Earned 🎉",
                "You earned a reward. Reveal now!",
                "reward_earned",
                amount,
                txn_id
            ))



        conn.commit()
        return {
        "message": "TRANSFER_SUCCESS",
        "earned_points": reward.get("earned_points", 0),
        "total_points": reward["total_points"],
        "tier": reward["tier"],
        "reward_token": token
        }, 200

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
            "transfer",
            "wallet"
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
                "upi_payment",
                "upi",
                upi_name
            )
        txn_id = c.lastrowid
        reward = update_user_points_and_tier(
            conn, c, sender_id, amount
        )
        
        token = generate_reward(
            c,
            sender_id,
            txn_id,
            amount,
            reward["tier"]
        )
       # ===== REWARD EARNED NOTIFICATION (DEDUP SAFE) =====
        c.execute("""
        SELECT id FROM notifications
        WHERE reg_id=%s AND ref_id=%s AND type='reward_earned'
        LIMIT 1
        """,(sender_id, txn_id))

        if not c.fetchone():

            c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                amount,
                ref_id,
                is_read
            )
            VALUES (%s,%s,%s,%s,%s,%s,0)
            """, (
                sender_id,
                "Reward Earned 🎉",
                "You earned a reward. Reveal now!",
                "reward_earned",
                amount,
                txn_id
            ))


    

        conn.commit()
        return {
        "message": "UPI_PAYMENT_SUCCESS",
        "earned_points": reward.get("earned_points", 0),
        "total_points": reward["total_points"],
        "tier": reward["tier"],
        "reward_token": token
        }, 200


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
            "upi_payment",
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
        reward = update_user_points_and_tier(conn, c, sender_id, amount)
        conn.commit()
        return {
            "message": "TRANSFER_SUCCESS",
            "earned_points": reward.get("earned_points", 0),
            "total_points": reward["total_points"],
            "tier": reward["tier"]
        }, 200

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

def _log_card_txn(
    c,
    reg_id,
    card_id,
    amount,
    merchant_name,
    txn_type,
    status,
    merchant_category=None,
    merchant_reference=None,
    payment_source="in_app",
    transaction_reference=None
):
    c.execute("""
        INSERT INTO card_transactions (
            reg_id,
            card_id,
            amount,
            merchant_name,
            txn_type,
            status,
            merchant_category,
            merchant_reference,
            payment_source,
            transaction_reference
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        reg_id,
        card_id,
        float(amount),
        merchant_name,
        txn_type,
        status,
        merchant_category,
        merchant_reference,
        payment_source,
        transaction_reference
    ))


    txn_id = c.lastrowid

    # ===== REWARD ONLY IF SPEND =====
    if status == "success" and txn_type == "spend":
        create_card_spend_reward(
            None,
            c,
            reg_id,
            txn_id,
            amount,
            merchant_name
        )

    # ===== SPEND NOTIFICATION ONLY ON SUCCESS (WITH DUPLICATE PROTECTION) =====
    if status == "success" and txn_type == "spend":
        c.execute("""
        SELECT id FROM notifications
        WHERE reg_id=%s AND ref_id=%s AND type='card_spend'
        LIMIT 1
        """, (reg_id, txn_id))

        exists = c.fetchone()

        if not exists:
            c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                amount,
                ref_id,
                is_read
            )
            VALUES (%s,%s,%s,%s,%s,%s,0)
            """, (
                reg_id,
                "Payment Successful",
                f"₹{float(amount):.2f} spent at {merchant_name}",
                "card_spend",
                float(amount),
                txn_id
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
              wt.payment_method,

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
            split_note = None
            txn_type = t.get("txn_type")
            sender_id = t.get("sender_reg_id")
            payment_method = t.get("payment_method")

            payment_type = "Wallet"
            display_name = ""
            upi_id = ""
            title = ""
            direction = ""

            # ================= ADD MONEY (TOP-UP) =================
            if txn_type == "add_money":
                direction = "topup"

                if payment_method == "card":
                    payment_type = "Card"
                    title = "Card Top-Up"
                    display_name = "Card Top-Up"
                elif payment_method == "upi":
                    payment_type = "UPI"
                    title = "UPI Top-Up"
                    display_name = "UPI Top-Up"
                else:
                    payment_type = "Wallet"
                    title = "Wallet Top-Up"
                    display_name = "Wallet Top-Up"

                upi_id = ""

            # ================= CARD SPEND (if exists) =================
            elif txn_type == "spend":
                direction = "debit"
                payment_type = "Card"

                display_name = (
                    t.get("counterparty_name")
                    or "Card Payment"
                )

                title = f"Card Payment to {display_name}"
                upi_id = ""

            # ================= PAID (DEBIT) =================
            elif sender_id == reg_id:
                direction = "debit"

                raw_name = (
                    t.get("counterparty_name")
                    or t.get("receiver_name")
                    or "Unknown"
                )

                display_name = raw_name

                if raw_name and " | Split - " in raw_name:
                    parts = raw_name.split(" | Split - ")
                    display_name = parts[0]
                    split_note = parts[1] if len(parts) > 1 else None

                title = f"Paid to {display_name}"
                upi_id = t.get("receiver_upi_id") or ""

                if txn_type == "transfer":
                    payment_type = "Wallet"
                elif txn_type == "upi_payment":
                    payment_type = "UPI"
                else:
                    payment_type = "UPI"

            # ================= RECEIVED (CREDIT) =================
            else:
                direction = "credit"

                display_name = (
                    t.get("sender_name")
                    or t.get("counterparty_name")
                    or "Unknown"
                )

                title = f"Received from {display_name}"
                upi_id = t.get("sender_upi_id") or ""

                if txn_type == "transfer":
                    payment_type = "Wallet"
                else:
                    payment_type = "UPI"

            # ================= STATUS TEXT =================
            if t.get("status") == "success":
                status_text = "Success"
            elif t.get("status") == "failed":
                if t.get("failure_reason") == "USER_CANCELLED":
                    status_text = "Cancelled"
                elif t.get("failure_reason") == "AUTO_CANCELLED_TIMEOUT":
                    status_text = "Expired"
                else:
                    status_text = "Failed"
            else:
                status_text = "Pending"

            result.append({
                "id": t.get("id"),
                "amount": float(t.get("amount") or 0),
                "direction": direction,
                "display_name": display_name,
                "upi_id": upi_id,
                "split_note": split_note,
                "title": title,
                "payment_type": payment_type,
                "status": t.get("status"),
                "status_text": status_text,
                "failure_reason": t.get("failure_reason"),
                "txn_type": txn_type,
                "created_at": (
                    t["created_at"].isoformat() + "Z"
                    if t.get("created_at")
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
            txn_type,
            payment_method
        )

        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (
        reg_id,          # sender
        reg_id,          # receiver (self)
        None,            # receiver_upi_id → allowed now
        float(amount),
        status,
        failure_reason,
        "add_money",
        "card"
    ))


# =================  Notifications ======================

# ================= ALL Notifications ======================
@app.route("/api/notifications/<int:reg_id>", methods=["GET"])
def get_all_notifications(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                id,
                title,
                message,
                type,
                amount,
                ref_id,
                is_read,
                created_at
            FROM notifications
            WHERE reg_id = %s
            ORDER BY created_at DESC
        """, (reg_id,))

        rows = c.fetchall()

        for r in rows:
            if r["created_at"]:
                r["created_at"] = r["created_at"].isoformat()

        return jsonify(rows), 200

    except Exception as e:
        print("GET ALL NOTIFICATIONS ERROR:", e)
        return jsonify([]), 200

    finally:
        c.close()
        conn.close()

# ============ Unread Notifications =====================
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
    
@app.route("/api/notifications/unread/<int:reg_id>", methods=["GET"])
def get_unread_notifications(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT id, title, message, created_at, is_read
            FROM notifications
            WHERE reg_id = %s AND is_read = 0
            ORDER BY created_at DESC
        """, (reg_id,))

        rows = c.fetchall()

        for r in rows:
            if r["created_at"]:
                r["created_at"] = r["created_at"].isoformat()

        return jsonify(rows), 200

    except Exception as e:
        print("UNREAD NOTIFICATION ERROR:", e)
        return jsonify([]), 200

    finally:
        c.close()
        conn.close()

@app.route("/api/notifications/mark-read/<int:reg_id>", methods=["POST"])
def mark_notifications_read(reg_id):

    conn = get_db_connection()
    c = conn.cursor()

    c.execute("""
        UPDATE notifications
        SET is_read = 1
        WHERE reg_id = %s
    """, (reg_id,))

    conn.commit()
    c.close()
    conn.close()

    return {"message": "MARKED_READ"}, 200

@app.route("/api/notifications/read/<int:notif_id>", methods=["POST"])
def mark_single_notification_read(notif_id):

    conn = get_db_connection()
    c = conn.cursor()

    c.execute("""
        UPDATE notifications
        SET is_read = 1
        WHERE id = %s
    """, (notif_id,))

    conn.commit()
    c.close()
    conn.close()

    return {"message": "READ"}, 200

@app.route("/api/notifications/delete/<int:notif_id>", methods=["DELETE"])
def delete_notification(notif_id):

    conn = get_db_connection()
    c = conn.cursor()

    c.execute("""
        DELETE FROM notifications
        WHERE id=%s
    """, (notif_id,))

    conn.commit()
    c.close()
    conn.close()

    return {"message": "DELETED"}, 200



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
        "wallet": bool(row["wallet_pin_set"]),
        "card": bool(row["card_pin_set"]),
        "wallet_locked": bool(row.get("wallet_pin_locked", 0)),
        "card_locked": bool(row.get("card_pin_locked", 0))
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

    try:
        amount = float(d["amount"])
    except (ValueError, TypeError):
        return {"message": "INVALID_AMOUNT"}, 400

    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # Fetch mobile
        c.execute("""
            SELECT s.mobile
            FROM registered_students rs
            JOIN students s ON rs.student_id = s.id
            WHERE rs.id = %s
        """, (d["reg_id"],))

        user = c.fetchone()
        if not user:
            return {"message": "USER_NOT_FOUND"}, 404

        send_mobile_otp(user["mobile"])

        # Decide payment method
        payment_method = d.get("funding_source", "card")

        # Insert pending transaction
        c.execute("""
            INSERT INTO wallet_transactions (
                sender_reg_id,
                receiver_reg_id,
                amount,
                payment_method,
                status,
                txn_type
            )
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            d["reg_id"],          # sender
            d["reg_id"],          # receiver (self top-up)
            amount,
            payment_method,       # card / upi
            "pending",
            "add_money"
        ))

        txn_id = c.lastrowid
        conn.commit()

        return {"txn_id": txn_id}, 200

    except Exception as e:
        print("ADD MONEY INIT ERROR:", e)
        conn.rollback()
        return {"message": "FAILED_TO_INIT_ADD_MONEY"}, 500

    finally:
        c.close()
        conn.close()


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

    # OTP Validation
    if not verify_otp(d["otp"]):
        _update_txn_status(txn_id, "failed", "INVALID_OTP")
        return {"status": "failed"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ===== LOCK TRANSACTION =====
        c.execute("""
            SELECT id, sender_reg_id, amount, status
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

        reg_id = txn["sender_reg_id"]
        amount = float(txn["amount"])

        # ===== CREDIT WALLET =====
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
        """, (amount, reg_id))

        # ===== MARK WALLET TXN SUCCESS =====
        c.execute("""
            UPDATE wallet_transactions
            SET status='success',
                failure_reason=NULL
            WHERE id=%s
        """, (txn_id,))

        # ===== SAVE CARD IF CHECKED =====
        if d.get("save_card") is True:
            save_card_token(
                d.get("card_data", {}),
                reg_id
            )

        conn.commit()

        return {
            "status": "success",
            "credited_amount": amount
        }, 200

    except Exception as e:
        conn.rollback()
        print("VERIFY ADD MONEY ERROR:", e)

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
        
# ============= Create Scholar Application =================    
@app.route("/api/scholar/application", methods=["POST"])
def create_scholar_application():
    d = request.json

    required_fields = [
        "full_name",
        "email",
        "phone",
        "loan_amount",
        "city",
        "country",
        "admission_status",
        "target_intake"
    ]

    if not d or not all(k in d for k in required_fields):
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        SELECT id
        FROM students
        WHERE mobile = %s OR email = %s
        LIMIT 1
    """, (d["phone"], d["email"]))

    student = c.fetchone()

    if not student:
        c.close()
        conn.close()
        return {"message": "STUDENT_NOT_FOUND"}, 400

    student_id = student[0]
    c.execute("""
        SELECT id
        FROM registered_students
        WHERE student_id = %s
        LIMIT 1
    """, (student_id,))

    reg = c.fetchone()

    if not reg:
        c.close()
        conn.close()
        return {"message": "REGISTERED_STUDENT_NOT_FOUND"}, 400

    registered_student_id = reg[0]
    c.execute("""
        INSERT INTO scholar_applications (
            registered_student_id,
            full_name,
            email,
            phone,
            loan_amount,
            city,
            country,
            admission_status,
            target_intake,
            status
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,'pending')
    """, (
        registered_student_id,
        d["full_name"],
        d["email"],
        d["phone"],
        d["loan_amount"],
        d["city"],
        d["country"],
        d["admission_status"],
        d["target_intake"],
    ))

    conn.commit()
    c.close()
    conn.close()

    return {"message": "APPLICATION_CREATED"}, 201



# ======== get scholar status =============
@app.route("/api/scholar/application/status/<int:reg_id>", methods=["GET"])
def get_scholar_application_status(reg_id):
    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT status
        FROM scholar_applications
        WHERE registered_student_id = %s
        ORDER BY created_at DESC
        LIMIT 1
    """, (reg_id,))

    row = c.fetchone()
    c.close()
    conn.close()

    if not row:
        return {
            "hasApplication": False,
            "status": None
        }, 200

    return {
        "hasApplication": True,
        "status": row["status"]  
    }, 200
# ======== Tier =========
def update_user_points_and_tier(conn, c, reg_id, amount, is_spend=True):

    reset_cycle_if_needed(conn, c, reg_id)

    earned_points = 0

    if is_spend:
        # Update total spent
        c.execute("""
            UPDATE registered_students
            SET total_spent = IFNULL(total_spent,0) + %s
            WHERE id = %s
        """, (amount, reg_id))

        # Calculate earned points
        earned_points = max(1, calculate_points(amount))

        # Add points
        c.execute("""
            UPDATE registered_students
            SET reward_points = reward_points + %s
            WHERE id = %s
        """, (earned_points, reg_id))

        # Fetch updated total
        c.execute("""
            SELECT reward_points
            FROM registered_students
            WHERE id=%s
        """, (reg_id,))

        total_points = c.fetchone()["reward_points"]

        tier = tier_from_points(total_points)

        c.execute("""
            UPDATE registered_students
            SET tier=%s
            WHERE id=%s
        """, (tier, reg_id))

        return {
            "earned_points": earned_points,
            "total_points": total_points,
            "tier": tier
        }

    return {
        "earned_points": 0
    }


# ===== Tier Cycle Helper =====
def get_cycle_start():
    today = datetime.now()

    month = today.month

    if month <= 3:
        return datetime(today.year, 1, 1)
    elif month <= 6:
        return datetime(today.year, 4, 1)
    elif month <= 9:
        return datetime(today.year, 7, 1)
    else:
        return datetime(today.year, 10, 1)
    
# ===== Reset Cycle =====
def reset_cycle_if_needed(conn, c, reg_id):
    cycle_start = get_cycle_start().date()

    c.execute("""
        SELECT tier_cycle_start
        FROM registered_students
        WHERE id=%s
    """, (reg_id,))

    row = c.fetchone()

    # FIRST TIME USER → SET CYCLE ONLY
    if row and row["tier_cycle_start"] is None:
        c.execute("""
            UPDATE registered_students
            SET tier_cycle_start = %s
            WHERE id = %s
        """, (cycle_start, reg_id))
        return

    # NEW CYCLE → RESET
    if row and row["tier_cycle_start"] != cycle_start:
        c.execute("""
            UPDATE registered_students
            SET
                reward_points = 0,
                tier = 'silver',
                tier_cycle_start = %s
            WHERE id = %s
        """, (cycle_start, reg_id))


# ====== Calculate Points ======
def calculate_points(amount):
    try:
        amount = float(amount)

        if amount < 200:
            return 2

        elif amount < 500:
            return 5

        elif amount < 1000:
            return 10

        elif amount < 2000:
            return 15

        else:
            return 20  

    except:
        return 0


# ===== Points from tier =====
def tier_from_points(points):
    if points >= 1501:
        return "diamond"
    elif points >= 901:
        return "platinum"
    elif points >= 401:
        return "gold"
    return "silver"


# ====== Create split Req =========
@app.route("/api/split/create", methods=["POST"])
def create_split():

    d = request.json

    required = ["creator_reg_id", "members", "total_amount", "split_type"]

    if not d or not all(k in d for k in required):
        return {"message": "INVALID_REQUEST"}, 400

    creator = d["creator_reg_id"]
    members = d["members"]
    total = float(d["total_amount"])
    split_type = d["split_type"]
    note = d.get("note")
    individual_amounts = d.get("individual_amounts")

    if len(members) < 1:
        return {"message": "MIN_ONE_MEMBER_REQUIRED"}, 400

    # ================= EVEN SPLIT FALLBACK =================
    if not individual_amounts or len(individual_amounts) != len(members):
        per_person = round(total / len(members), 2)
        individual_amounts = [per_person] * len(members)
    else:
        per_person = round(total / len(members), 2)

    # ================= VALIDATE SUM =================
    if round(sum(individual_amounts), 2) != round(total, 2):
        return {"message": "AMOUNT_MISMATCH"}, 400

    conn = get_db_connection()
    c = conn.cursor()

    try:
        # ================= CREATE SPLIT GROUP =================
        c.execute("""
        INSERT INTO split_groups
        (creator_reg_id, total_amount, per_person_amount, note, split_type, status, paid_amount)
        VALUES (%s,%s,%s,%s,%s,'pending',0)
        """, (creator, total, per_person, note, split_type))

        split_id = c.lastrowid

        # ================= INSERT MEMBERS =================
        creator_paid_amount = 0  

        for reg_id, amt in zip(members, individual_amounts):

            if reg_id == creator:
                status = "paid"
                paid_at = datetime.now()
                creator_paid_amount += float(amt)   
            else:
                status = "pending"
                paid_at = None

            c.execute("""
                INSERT INTO split_members
                (split_group_id, member_reg_id, amount, status, paid_at)
                VALUES (%s,%s,%s,%s,%s)
            """, (
                split_id,
                reg_id,
                float(amt),
                status,
                paid_at
            ))

            # ---- Notification Insert (Skip Creator) ----
            if reg_id != creator:
                c.execute("""
                INSERT INTO notifications (
                    reg_id,
                    title,
                    message,
                    type,
                    amount,
                    ref_id,
                    is_read
                )
                VALUES (%s,%s,%s,%s,%s,%s,0)
                """, (
                    reg_id,
                    "Split Request",
                    f"You have a split request of ₹{float(amt):.2f}",
                    "system",
                    float(amt),
                    split_id
                ))

        # ================= UPDATE GROUP PAID AMOUNT =================
        if creator_paid_amount > 0:
            c.execute("""
                UPDATE split_groups
                SET paid_amount = %s,
                    status = 'partial'
                WHERE id = %s
            """, (creator_paid_amount, split_id))

        conn.commit()

        return {
            "message": "SPLIT_CREATED",
            "split_id": split_id,
            "per_person_amount": per_person
        }, 200

    except Exception as e:
        conn.rollback()
        print("Split Create FULL ERROR:")
        traceback.print_exc()

        return {"message": "SPLIT_CREATE_FAILED"}, 500

    finally:
        c.close()
        conn.close()


# ========= Get My splits ===========
@app.route("/api/split/my/<int:reg_id>", methods=["GET"])
def get_my_splits(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            sm.id,
            sm.split_group_id,
            sm.amount,
            sm.status,
            sg.creator_reg_id,
            sg.created_at
        FROM split_members sm
        JOIN split_groups sg
          ON sg.id = sm.split_group_id
        WHERE sm.member_reg_id = %s
        ORDER BY sg.created_at DESC
    """, (reg_id,))

    rows = c.fetchall()

    c.close()
    conn.close()

    return rows, 200

# ============ splt requests =============
@app.route("/api/split/requests/<int:reg_id>", methods=["GET"])
def get_split_requests(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:

        c.execute("""
        SELECT
            sm.id AS split_member_id,
            sm.amount,
            sm.status,
            sg.id AS split_id,
            sg.total_amount,
            sg.note,
            sg.split_type,
            sg.status AS group_status,
            sg.closed,
            sg.creator_reg_id,
            sg.created_at,

            s.full_name AS creator_name,
            s.mobile AS creator_mobile,
            rs.upi_id AS creator_upi,
            rs.profile_image AS creator_image

        FROM split_groups sg

        LEFT JOIN split_members sm
        ON sm.split_group_id = sg.id
        AND sm.member_reg_id = %s

        JOIN registered_students rs ON rs.id = sg.creator_reg_id
        JOIN students s ON s.id = rs.student_id

        WHERE sg.creator_reg_id = %s
        OR sm.member_reg_id = %s

        ORDER BY sg.created_at DESC
        """, (reg_id, reg_id, reg_id))


        splits = c.fetchall()

        for split in splits:

            c.execute("""
            SELECT
                sm.id,
                sm.member_reg_id AS reg_id,
                sm.amount,
                sm.status,
                s.full_name AS name,
                rs.profile_image
            FROM split_members sm
            JOIN registered_students rs ON rs.id = sm.member_reg_id
            JOIN students s ON s.id = rs.student_id
            WHERE sm.split_group_id = %s
            """, (split["split_id"],))

            members = c.fetchall()

            for m in members:
                m["paid"] = m["status"] == "paid"

            split["members"] = members

        return jsonify(splits), 200

    except Exception as e:
        print("GET SPLIT REQUEST ERROR:", e)
        return jsonify([]), 200

    finally:
        c.close()
        conn.close()
        
        
# ===== Split Member Eligibility =====
@app.route("/api/split/member-status/<int:reg_id>", methods=["GET"])
def get_split_member_status(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                rs.aadhaar_verified,
                rs.pan_verified,
                w.status AS wallet_status,
                w.balance
            FROM registered_students rs
            JOIN wallets w ON rs.id = w.registered_student_id
            WHERE rs.id=%s
        """, (reg_id,))

        user = c.fetchone()

        if not user:
            return {"message": "USER_NOT_FOUND"}, 404

        return {
            "aadhaar_verified": user["aadhaar_verified"] == 1,
            "wallet_active": user["wallet_status"] == "active",
            "balance": float(user["balance"]),
            "can_pay": (
                user["aadhaar_verified"] == 1
                and user["wallet_status"] == "active"
            )
        }, 200

    finally:
        c.close()
        conn.close()

# ======== Pay Split ========
@app.route("/api/split/pay", methods=["POST"])
def pay_split():

    d = request.json

    if not d or "split_member_id" not in d or "payer_reg_id" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)
    amount = 0

    try:
        # ===== LOCK SPLIT MEMBER =====
        c.execute("""
        SELECT 
            sm.*,
            sg.creator_reg_id,
            sg.id AS split_group_id,
            sg.note,
            s.full_name AS creator_name
        FROM split_members sm
        JOIN split_groups sg ON sg.id = sm.split_group_id
        JOIN registered_students rs ON rs.id = sg.creator_reg_id
        JOIN students s ON s.id = rs.student_id
        WHERE sm.id=%s
        FOR UPDATE
        """, (d["split_member_id"],))

        sm = c.fetchone()

        if not sm:
            return {"message": "SPLIT_NOT_FOUND"}, 404

        # ===== BLOCK IF SPLIT CLOSED =====
        c.execute("""
        SELECT IFNULL(closed,0) as closed
        FROM split_groups
        WHERE id=%s
        """, (sm["split_group_id"],))

        closed_row = c.fetchone()

        if closed_row and closed_row["closed"] == 1:
            return {"message": "SPLIT_ALREADY_CLOSED"}, 400

        note = sm.get("note")
        creator_name = sm.get("creator_name")

        amount = float(sm["amount"])
        creator = sm["creator_reg_id"]

        # ===== FETCH CREATOR IDENTIFIER =====
        c.execute("""
        SELECT s.mobile, rs.upi_id
        FROM registered_students rs
        JOIN students s ON s.id = rs.student_id
        WHERE rs.id=%s
        """, (creator,))

        creator_row = c.fetchone()

        creator_identifier = (
            creator_row["upi_id"]
            if creator_row and creator_row.get("upi_id")
            else creator_row.get("mobile") if creator_row else None
        )

        # ===== KYC CHECK =====
        c.execute("""
        SELECT aadhaar_verified, pan_verified
        FROM registered_students
        WHERE id=%s
        """, (d["payer_reg_id"],))

        kyc = c.fetchone()

        if not kyc or kyc["aadhaar_verified"] != 1:
            return {"message": "AADHAAR_REQUIRED"}, 403

        # ===== LOCK WALLET =====
        c.execute("""
            SELECT balance, status
            FROM wallets
            WHERE registered_student_id=%s
            FOR UPDATE
        """, (d["payer_reg_id"],))

        wallet = c.fetchone()

        split_display_name = (
            f"{creator_name} | Split - {note}"
            if note else creator_name
        )

        # ===== WALLET INACTIVE =====
        if not wallet or wallet["status"] != "active":

            _log_txn(
                c,
                d["payer_reg_id"],
                creator,
                creator_identifier,
                amount,
                "failed",
                "WALLET_INACTIVE",
                "transfer",
                "wallet",
                split_display_name
            )

            conn.commit()
            return {"message": "WALLET_INACTIVE"}, 403

        # ===== DEBIT PAYER =====
        c.execute("""
            UPDATE wallets
            SET balance = balance - %s
            WHERE registered_student_id=%s
        """, (amount, d["payer_reg_id"]))

        # ===== CREDIT CREATOR =====
        c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
        """, (amount, creator))

        # ===== MARK MEMBER PAID =====
        c.execute("""
            UPDATE split_members
            SET status='paid', paid_at=NOW()
            WHERE id=%s
        """, (d["split_member_id"],))

        # ===== UPDATE GROUP PAID AMOUNT =====
        c.execute("""
            UPDATE split_groups
            SET paid_amount = paid_amount + %s
            WHERE id=%s
        """, (amount, sm["split_group_id"]))

        # ===== CHECK GROUP STATUS =====
        c.execute("""
            SELECT COUNT(*) AS pending_count
            FROM split_members
            WHERE split_group_id=%s AND status='pending'
        """, (sm["split_group_id"],))

        pending = c.fetchone()["pending_count"]

        if pending == 0:
            c.execute("""
                UPDATE split_groups
                SET status='completed'
                WHERE id=%s
            """, (sm["split_group_id"],))
        else:
            c.execute("""
                UPDATE split_groups
                SET status='partial'
                WHERE id=%s
            """, (sm["split_group_id"],))

        # ===== TRANSACTION HISTORY SUCCESS =====
        _log_txn(
            c,
            d["payer_reg_id"],
            creator,
            creator_identifier,
            amount,
            "success",
            None,
            "transfer",
            "wallet",
            split_display_name
        )

        txn_id = c.lastrowid

        # ===== REWARDS UPDATE =====
        reward = update_user_points_and_tier(
            conn,
            c,
            d["payer_reg_id"],
            amount
        )

        token = generate_reward(
            c,
            d["payer_reg_id"],
            txn_id,
            amount,
            reward["tier"]
        )

        # ===== REWARD EARNED NOTIFICATION (DEDUP SAFE) =====
        c.execute("""
        SELECT id FROM notifications
        WHERE reg_id=%s AND ref_id=%s AND type='reward_earned'
        LIMIT 1
        """, (d["payer_reg_id"], txn_id))

        if not c.fetchone():

            c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                amount,
                ref_id,
                is_read
            )
            VALUES (%s,%s,%s,%s,%s,%s,0)
            """, (
                d["payer_reg_id"],
                "Reward Earned 🎉",
                "You earned a reward. Reveal now!",
                "reward_earned",
                amount,
                txn_id
            ))

        conn.commit()

        return {
            "message": "SPLIT_PAID",
            "earned_points": reward.get("earned_points", 0),
            "total_points": reward["total_points"],
            "tier": reward["tier"],
            "creator_name": creator_name,
            "note": note,
            "payment_method": "wallet",
            "paid_at": datetime.now().isoformat(),
            "reward_token": token
        }, 200

    except Exception as e:
        conn.rollback()

        safe_creator_name = locals().get("creator_name")
        safe_note = locals().get("note")
        safe_creator_identifier = locals().get("creator_identifier")

        split_display_name = (
            f"{safe_creator_name} | Split - {safe_note}"
            if safe_creator_name and safe_note
            else safe_creator_name
        )

        _log_txn(
            c,
            d.get("payer_reg_id"),
            None,
            safe_creator_identifier,
            amount,
            "failed",
            str(e),
            "transfer",
            "wallet",
            split_display_name
        )

        conn.commit()

        return {"message": "SPLIT_PAYMENT_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# ======== Close Split ===========
@app.route("/api/split/close", methods=["POST"])
def close_split():

    data = request.json
    split_id = data.get("split_id")
    creator_reg_id = data.get("creator_reg_id")

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:

        # ===== VERIFY CREATOR =====
        c.execute("""
            SELECT creator_reg_id
            FROM split_groups
            WHERE id=%s
        """, (split_id,))
        group = c.fetchone()

        if not group:
            return {"message": "SPLIT_NOT_FOUND"}, 404

        if group["creator_reg_id"] != creator_reg_id:
            return {"message": "NOT_ALLOWED"}, 403

        # ===== CHECK ALL PAID =====
        c.execute("""
            SELECT COUNT(*) as unpaid
            FROM split_members
            WHERE split_group_id=%s
            AND status!='paid'
        """, (split_id,))
        unpaid = c.fetchone()["unpaid"]

        if unpaid > 0:
            return {"message": "ALL_NOT_PAID"}, 400

        # ===== CLOSE SPLIT =====
        c.execute("""
            UPDATE split_groups
            SET closed=1
            WHERE id=%s
        """, (split_id,))

        conn.commit()

        return {"message": "SPLIT_CLOSED"}, 200

    except Exception as e:
        conn.rollback()
        return {"message": str(e)}, 500

    finally:
        conn.close()

 # Create splits       
@app.route("/api/split/created/<int:reg_id>", methods=["GET"])
def get_created_splits(reg_id):

    split_type = request.args.get("type")

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
    SELECT *
    FROM split_groups
    WHERE creator_reg_id=%s
    AND (%s IS NULL OR split_type=%s)
    ORDER BY created_at DESC
    """, (reg_id, split_type, split_type))

    rows = c.fetchall()

    c.close()
    conn.close()

    return rows, 200

# Split members
@app.route("/api/split/members/<int:split_id>", methods=["GET"])
def get_split_members(split_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
    SELECT
    sm.*,
    s.full_name,
    rs.profile_image
    FROM split_members sm
    JOIN registered_students rs ON rs.id = sm.member_reg_id
    JOIN students s ON s.id = rs.student_id
    WHERE sm.split_group_id=%s
    """, (split_id,))

    rows = c.fetchall()

    c.close()
    conn.close()

    return rows, 200

# =========== Rewards ===============
@app.route("/api/rewards/reveal", methods=["POST"])
def reveal_reward():

    d = request.json

    if not d:
        return {"message": "INVALID_REQUEST"}, 400

    token = d.get("token")
    reg_id_from_request = d.get("reg_id")

    if not token:
        return {"message": "TOKEN_REQUIRED"}, 400

    if not reg_id_from_request:
        return {"message": "REG_ID_REQUIRED"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ================= FETCH + LOCK REWARD =================
        c.execute("""
        SELECT *
        FROM reward_reveals
        WHERE reveal_token=%s AND reg_id=%s
        FOR UPDATE
        """,(token, reg_id_from_request))

        reward = c.fetchone()
        c.fetchall()

        if not reward:
            return {"message":"INVALID_TOKEN"},400

        # ================= IDEMPOTENT RETURN =================
        if reward["status"] == "revealed":
            return {
                "type": reward["reward_type"],
                "value": reward["reward_value"],
                "already_revealed": True
            }

        reg_id = reward["reg_id"]
        txn_id = reward["txn_id"]
        reward_type = reward["reward_type"]
        reward_value = reward["reward_value"]

        # Normalize cashback value
        if reward_type == "cashback":
            reward_value = float(reward_value)

        # ================= CASHBACK =================
        if reward_type == "cashback":

            amount = float(reward_value)

            # LOCK WALLET FIRST
            c.execute("""
            SELECT balance
            FROM wallets
            WHERE registered_student_id=%s
            FOR UPDATE
            """,(reg_id,))
            c.fetchone()

            # Credit Wallet
            c.execute("""
            UPDATE wallets
            SET balance = balance + %s
            WHERE registered_student_id=%s
            """,(amount, reg_id))

            # Ledger Entry
            c.execute("""
            INSERT INTO cashback_ledger
            (reg_id, txn_id, amount)
            VALUES (%s,%s,%s)
            """,(reg_id, txn_id, amount))

            # Prevent duplicate notification
            c.execute("""
            SELECT id FROM notifications
            WHERE reg_id=%s AND ref_id=%s AND type='reward'
            LIMIT 1
            """,(reg_id, txn_id))

            if not c.fetchone():
                c.execute("""
                INSERT INTO notifications
                (reg_id, title, message, type, amount, ref_id, is_read)
                VALUES (%s,%s,%s,%s,%s,%s,0)
                """,(
                    reg_id,
                    "Cashback Received",
                    f"₹{amount:.2f} cashback added to your wallet",
                    "reward",
                    amount,
                    txn_id
                ))

        # ================= COUPON =================
        elif reward_type == "coupon":

            # Insert coupon
            c.execute("""
            INSERT INTO user_coupons
            (reg_id, coupon_code, txn_id, status)
            VALUES (%s,%s,%s,'active')
            """,(reg_id, reward_value, txn_id))

            # Prevent duplicate notification
            c.execute("""
            SELECT id FROM notifications
            WHERE reg_id=%s AND ref_id=%s AND type='reward'
            LIMIT 1
            """,(reg_id, txn_id))

            if not c.fetchone():
                c.execute("""
                INSERT INTO notifications
                (reg_id, title, message, type, ref_id, is_read)
                VALUES (%s,%s,%s,%s,%s,0)
                """,(
                    reg_id,
                    "Coupon Unlocked 🎉",
                    f"You received coupon {reward_value}",
                    "reward",
                    txn_id
                ))

        # ================= VOUCHER =================
        elif reward_type == "voucher":

            # Insert voucher
            c.execute("""
            INSERT INTO user_vouchers
            (reg_id, voucher_code, txn_id, status)
            VALUES (%s,%s,%s,'active')
            """,(reg_id, reward_value, txn_id))

            # Prevent duplicate notification
            c.execute("""
            SELECT id FROM notifications
            WHERE reg_id=%s AND ref_id=%s AND type='reward'
            LIMIT 1
            """,(reg_id, txn_id))

            if not c.fetchone():
                c.execute("""
                INSERT INTO notifications
                (reg_id, title, message, type, ref_id, is_read)
                VALUES (%s,%s,%s,%s,%s,0)
                """,(
                    reg_id,
                    "Voucher Unlocked",
                    f"You received voucher {reward_value}",
                    "reward",
                    txn_id
                ))

        else:
            return {"message": "INVALID_REWARD_TYPE"}, 400

        # ================= MARK REVEALED =================
        c.execute("""
        UPDATE reward_reveals
        SET status='revealed'
        WHERE id=%s
        """,(reward["id"],))

        conn.commit()

        return {
            "type": reward_type,
            "value": reward_value
        }

    except Exception as e:
        conn.rollback()
        print("REVEAL REWARD ERROR:", e)
        return {"message": "REVEAL_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# ====== Cash won ===============
@app.route("/api/rewards/cashwon/<int:reg_id>", methods=["GET"])
def get_cashwon(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            id,
            txn_id,
            amount,
            created_at
        FROM cashback_ledger
        WHERE reg_id=%s
        ORDER BY created_at DESC
    """, (reg_id,))

    data = c.fetchall()

    c.close()
    conn.close()

    return {"cashwon": data}

# ============== Coupons Won ==============
@app.route("/api/rewards/coupons/<int:reg_id>", methods=["GET"])
def get_coupons(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            id,
            coupon_code,
            txn_id,
            status,
            created_at
        FROM user_coupons
        WHERE reg_id=%s
        ORDER BY created_at DESC
    """, (reg_id,))

    data = c.fetchall()

    c.close()
    conn.close()

    return {"coupons": data}

# ============= Vouchers won =================
@app.route("/api/rewards/vouchers/<int:reg_id>", methods=["GET"])
def get_vouchers(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            id,
            voucher_code,
            txn_id,
            status,
            created_at
        FROM user_vouchers
        WHERE reg_id=%s
        ORDER BY created_at DESC
    """, (reg_id,))

    data = c.fetchall()

    c.close()
    conn.close()

    return {"vouchers": data}

# ================= PENDING DRAG REWARDS =================
@app.route("/api/rewards/pending-drag/<int:reg_id>", methods=["GET"])
def get_pending_drag_rewards(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                reveal_token AS reward_token,
                txn_id,
                created_at
            FROM reward_reveals
            WHERE reg_id = %s
            AND status = 'pending'
            ORDER BY created_at DESC
        """, (reg_id,))

        rows = c.fetchall()

        return {
            "rewards": rows
        }, 200

    except Exception as e:
        print("PENDING DRAG REWARD ERROR:", e)
        return {"rewards": []}, 200

    finally:
        c.close()
        conn.close()

# ========== CARD ================

# ==== Helpers ======
def generate_card_number():
    prefix = "4"
    remaining = "".join(str(random.randint(0,9)) for _ in range(15))
    return prefix + remaining

def generate_cvv():
    return str(random.randint(100,999))

def mask_card(card_number):
    return "**** **** **** " + card_number[-4:]

def calculate_card_cashback(amount, merchant_name):

    name = (merchant_name or "").lower()

    # CATEGORY DETECTION
    if any(k in name for k in ["amazon","flipkart","myntra","shopping"]):
        percent = 0.01

    elif any(k in name for k in ["zomato","swiggy","food","restaurant","cafe"]):
        percent = 0.01

    elif any(k in name for k in ["college","university","tuition","fee","education"]):
        percent = 0.05

    elif any(k in name for k in ["bookmyshow","pvr","inox","movie","cinema"]):
        percent = 0.02

    else:
        percent = 0.005

    return round(float(amount) * percent, 2)


def create_card_spend_reward(conn, c, reg_id, txn_id, amount, merchant_name):

    cashback = calculate_card_cashback(amount, merchant_name)

    if cashback <= 0:
        return None

    token = generate_reward(
        c,
        reg_id,
        txn_id,
        cashback,
        "card_spend"
    )

    # ===== REWARD EARNED NOTIFICATION =====
    c.execute("""
    SELECT id FROM notifications
    WHERE reg_id=%s AND ref_id=%s AND type='reward_earned'
    LIMIT 1
    """,(reg_id, txn_id))

    if not c.fetchone():

        c.execute("""
        INSERT INTO notifications (
            reg_id,
            title,
            message,
            type,
            amount,
            ref_id,
            is_read
        )
        VALUES (%s,%s,%s,%s,%s,%s,0)
        """, (
            reg_id,
            "Reward Earned 🎉",
            f"You earned ₹{cashback:.2f} cashback. Reveal now!",
            "reward_earned",
            cashback,
            txn_id
        ))


    return token


# ==== Card Details =========
def create_card_for_user(reg_id, conn, c):

    # Check if card already exists
    c.execute("""
        SELECT id FROM lume_cards
        WHERE reg_id=%s
    """, (reg_id,))

    if c.fetchone():
        return

    # Generate data
    card_number = generate_card_number()
    cvv = generate_cvv()

    # Temporary expiry (3 years default)
    expiry_date = datetime.now() + relativedelta(years=3)

    c.execute("""
        INSERT INTO lume_cards (
            reg_id,
            card_number,
            card_last4,
            expiry_month,
            expiry_year,
            cvv,
            card_status
        )
        VALUES (%s,%s,%s,%s,%s,%s,'active')
    """, (
        reg_id,
        card_number,
        card_number[-4:],
        expiry_date.month,
        expiry_date.year,
        cvv
    ))

# =========== Get Lume Card ================
@app.route("/api/lume-card/<int:reg_id>", methods=["GET"])
def get_lume_card(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    c.execute("""
        SELECT
            card_last4,
            expiry_month,
            expiry_year,
            card_status,
            is_locked,
            is_blocked,
            daily_limit,
            monthly_limit
        FROM lume_cards
        WHERE reg_id=%s
    """, (reg_id,))

    card = c.fetchone()

    c.close()
    conn.close()

    if not card:
        return {"card_exists": False}

    return {
        "card_exists": True,
        "card": card
    }
 # ==== LOCK CARD ======
@app.route("/api/lume-card/lock", methods=["POST"])
def lock_card():
    d = request.json

    if not d or "reg_id" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    reg_id = d["reg_id"]

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ===== LOCK CARD ROW =====
        c.execute("""
            SELECT id, is_locked, card_last4
            FROM lume_cards
            WHERE reg_id=%s
            FOR UPDATE
        """, (reg_id,))

        card = c.fetchone()

        if not card:
            return {"message": "CARD_NOT_FOUND"}, 404
        
        # ===== REQUIRE CARD PIN =====
        c.execute("""
            SELECT card_pin_hash
            FROM wallet_security
            WHERE reg_id=%s
        """, (reg_id,))

        pin = c.fetchone()

        if not pin or not pin["card_pin_hash"]:
            return {"message": "CARD_PIN_NOT_SET"}, 403


        # ===== TOGGLE LOCK =====
        new_state = 0 if card["is_locked"] == 1 else 1

        c.execute("""
            UPDATE lume_cards
            SET is_locked=%s
            WHERE reg_id=%s
        """, (new_state, reg_id))

        # ===== CREATE NOTIFICATION =====
        status_text = "locked" if new_state == 1 else "unlocked"
        last4 = card["card_last4"]

        c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                is_read
            )
            VALUES (%s,%s,%s,%s,0)
        """, (
            reg_id,
            "Card Security Update",
            f"Your card ending with {last4} has been {status_text}.",
            "card_security"
        ))

        conn.commit()

        return {
            "message": "CARD_LOCK_UPDATED",
            "is_locked": new_state == 1
        }, 200

    except Exception as e:
        conn.rollback()
        print("LOCK CARD ERROR:", e)
        return {"message": "LOCK_FAILED"}, 500

    finally:
        c.close()
        conn.close()

# ==== Get Card Details ========
@app.route("/api/card/details/<int:reg_id>", methods=["GET"])
def get_card_details(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                card_number,
                expiry_month,
                expiry_year,
                cvv
            FROM lume_cards
            WHERE reg_id=%s
        """, (reg_id,))

        card = c.fetchone()

        if not card:
            return {"message": "CARD_NOT_FOUND"}, 404

        return card, 200

    except Exception as e:
        print("CARD DETAILS ERROR:", e)
        return {"message": "SERVER_ERROR"}, 500

    finally:
        c.close()
        conn.close()
        
# ======= Get Card Transactions =========
@app.route("/api/card/transactions/<int:reg_id>", methods=["GET"])
def get_card_transactions(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT
                id,
                amount,
                merchant_name,
                txn_type,
                status,
                merchant_category,
                payment_source,
                transaction_reference,
                created_at
            FROM card_transactions
            WHERE reg_id=%s
            ORDER BY created_at DESC
        """, (reg_id,))

        rows = c.fetchall()
        result = []

        for r in rows:

            # Format timestamp
            created_at = (
                r["created_at"].isoformat() + "Z"
                if r["created_at"] else None
            )

            # Status Text
            if r["status"] == "success":
                status_text = "Success"
            elif r["status"] == "failed":
                status_text = "Failed"
            else:
                status_text = "Pending"

            # Display Title
            if r["txn_type"] == "wallet_topup":
                display_title = "Wallet Top-Up"
            elif r["txn_type"] == "spend":
                display_title = r["merchant_name"]
            else:
                display_title = r["merchant_name"] or "Card Transaction"

            result.append({
                "id": r["id"],
                "amount": float(r["amount"]),
                "merchant_name": r["merchant_name"],
                "display_title": display_title,
                "txn_type": r["txn_type"],
                "status": r["status"],
                "status_text": status_text,
                "merchant_category": r.get("merchant_category"),
                "payment_source": r.get("payment_source"),
                "transaction_reference": r.get("transaction_reference"),
                "created_at": created_at
            })

        return jsonify(result), 200

    except Exception as e:
        print("CARD TXN ERROR:", e)
        return jsonify([]), 200

    finally:
        c.close()
        conn.close()

# ====== Card Status ===========
@app.route("/api/lume-card/status/<int:reg_id>", methods=["GET"])
def get_card_status(reg_id):

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        c.execute("""
            SELECT is_locked, is_blocked
            FROM lume_cards
            WHERE reg_id=%s
        """, (reg_id,))

        card = c.fetchone()

        if not card:
            return {"message": "CARD_NOT_FOUND"}, 404

        return {
            "is_locked": card["is_locked"] == 1,
            "is_blocked": card["is_blocked"] == 1
        }, 200

    finally:
        c.close()
        conn.close()
# ======== Card Pay =======
# ================= CARD PAYMENT =================
@app.route("/api/card/pay", methods=["POST"])
def card_payment():
    d = request.json

    if not d or "reg_id" not in d or "amount" not in d:
        return {"message": "INVALID_REQUEST"}, 400

    reg_id = d["reg_id"]
    amount = float(d["amount"])

    if amount <= 0:
        return {"message": "INVALID_AMOUNT"}, 400

    conn = get_db_connection()
    c = conn.cursor(dictionary=True)

    try:
        # ================= CHECK CARD EXISTS =================
        c.execute("""
            SELECT id, is_locked
            FROM lume_cards
            WHERE reg_id=%s
            FOR UPDATE
        """, (reg_id,))
        card = c.fetchone()

        if not card:
            return {"message": "CARD_NOT_FOUND"}, 404

        # ================= BLOCK IF CARD LOCKED =================
        if card["is_locked"] == 1:
            return {"message": "CARD_LOCKED"}, 403

        # ================= CHECK CARD PIN LOCK =================
        c.execute("""
            SELECT card_pin_locked
            FROM student_pins
            WHERE reg_id=%s
        """, (reg_id,))
        pin_data = c.fetchone()

        if pin_data and pin_data["card_pin_locked"] == 1:
            return {"message": "CARD_PIN_LOCKED"}, 403

        # ================= CHECK WALLET BALANCE =================
        c.execute("""
            SELECT wallet_balance
            FROM registered_students
            WHERE id=%s
            FOR UPDATE
        """, (reg_id,))
        user = c.fetchone()

        if not user:
            return {"message": "USER_NOT_FOUND"}, 404

        if float(user["wallet_balance"]) < amount:
            return {"message": "INSUFFICIENT_BALANCE"}, 400

        # ================= DEDUCT BALANCE =================
        new_balance = float(user["wallet_balance"]) - amount

        c.execute("""
            UPDATE registered_students
            SET wallet_balance=%s
            WHERE id=%s
        """, (new_balance, reg_id))

        # ================= INSERT TRANSACTION =================
        c.execute("""
            INSERT INTO wallet_transactions (
                sender_reg_id,
                receiver_reg_id,
                amount,
                status,
                txn_type,
                payment_method
            )
            VALUES (%s, NULL, %s, 'success', 'spend', 'card')
        """, (
            reg_id,
            amount
        ))

        txn_id = c.lastrowid

        # ================= CREATE NOTIFICATION =================
        c.execute("""
            INSERT INTO notifications (
                reg_id,
                title,
                message,
                type,
                is_read
            )
            VALUES (%s, %s, %s, %s, 0)
        """, (
            reg_id,
            "Card Payment Successful",
            f"₹{amount:.2f} spent using your Lume Card.",
            "card_spend"
        ))

        conn.commit()

        return {
            "message": "PAYMENT_SUCCESS",
            "txn_id": txn_id,
            "new_balance": new_balance
        }, 200

    except Exception as e:
        conn.rollback()
        print("CARD PAYMENT ERROR:", e)
        return {"message": "CARD_PAYMENT_FAILED"}, 500

    finally:
        c.close()
        conn.close()

#========================= RUN=========================
"""if __name__ == "__main__":
    app.run(debug=True)"""
if __name__ == "__main__":
    app.run(
    host="0.0.0.0",
    port=5000,
    debug=True
)