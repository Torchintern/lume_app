enum CardBrand { visa, mastercard, rupay, amex, unknown }
enum CardType { credit, debit, unknown }

CardBrand detectCardBrand(String input) {
  final n = input.replaceAll(' ', '');

  if (n.startsWith('4')) return CardBrand.visa;

  if (n.length >= 2) {
    final first2 = int.tryParse(n.substring(0, 2));
    if (first2 != null && first2 >= 51 && first2 <= 55) {
      return CardBrand.mastercard;
    }
  }

  if (n.length >= 4) {
    final first4 = int.tryParse(n.substring(0, 4));
    if (first4 != null && first4 >= 2221 && first4 <= 2720) {
      return CardBrand.mastercard;
    }
  }

  if (n.startsWith('34') || n.startsWith('37')) {
    return CardBrand.amex;
  }

  if (n.startsWith('60') ||
      n.startsWith('65') ||
      n.startsWith('81') ||
      n.startsWith('82') ||
      n.startsWith('508')) {
    return CardBrand.rupay;
  }

  return CardBrand.unknown;
}

CardType detectCardType(CardBrand brand, String number) {
  // amex is always credit
  if (brand == CardBrand.amex) {
    return CardType.credit;
  }
  // all others default to debit (industry safe)
  return CardType.debit;
}


String cardTypeLabel(CardType type) {
  switch (type) {
    case CardType.credit:
      return "Credit Card";
    case CardType.debit:
      return "Debit Card";
    default:
      return "";
  }
}

String cardBrandSvg(CardBrand brand) {
  switch (brand) {
    case CardBrand.visa:
      return 'assets/card_brands/visa.svg';
    case CardBrand.mastercard:
      return 'assets/card_brands/mastercard.svg';
    case CardBrand.amex:
      return 'assets/card_brands/amex.svg';
    case CardBrand.rupay:
      return 'assets/card_brands/rupay.svg';
    default:
      return '';
  }
}


