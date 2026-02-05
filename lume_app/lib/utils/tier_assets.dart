String getTierAsset(String tier) {
  switch (tier.toLowerCase()) {
    case "diamond":
      return "assets/tier/diamond.png";
    case "platinum":
      return "assets/tier/platinum.png";
    case "gold":
      return "assets/tier/gold.png";
    default:
      return "assets/tier/silver.png";
  }
}
