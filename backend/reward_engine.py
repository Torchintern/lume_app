import random
import uuid

def generate_reward(c, reg_id, txn_id, amount, tier):

    chances = {
        "silver": (60,30,10),
        "gold": (55,30,15),
        "platinum": (50,30,20),
        "diamond": (45,25,30)
    }

    cashbackChance, couponChance, voucherChance = chances.get(tier, (60,30,10))

    r = random.randint(1,100)

    if r <= cashbackChance:
        reward_type = "cashback"

        percent = min(0.015, 0.005 + (amount / 100000))
        value = round(amount * percent, 2)

    elif r <= cashbackChance + couponChance:
        reward_type = "coupon"
        value = "CPN" + str(random.randint(10000,99999))

    else:
        reward_type = "voucher"
        value = "VCH" + str(random.randint(10000,99999))

    token = str(uuid.uuid4())

    c.execute("""
    INSERT INTO reward_reveals
    (reg_id, txn_id, reward_type, reward_value, status, reveal_token)
    VALUES (%s,%s,%s,%s,'pending',%s)
    """,(reg_id, txn_id, reward_type, str(value), token))

    return token
