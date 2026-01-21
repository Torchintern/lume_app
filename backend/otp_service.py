# otp_service.py

DUMMY_OTP = "123456"

def send_mobile_otp(mobile):
    # Dummy mode: just log OTP
    print(f"[MOBILE OTP] {mobile} -> {DUMMY_OTP}")
    return True


def send_email_otp(email):
    # Dummy mode: just log OTP
    print(f"[EMAIL OTP] {email} -> {DUMMY_OTP}")
    return True


def verify_otp(otp):
    if otp is None:
        return False
    return str(otp).strip() == DUMMY_OTP

