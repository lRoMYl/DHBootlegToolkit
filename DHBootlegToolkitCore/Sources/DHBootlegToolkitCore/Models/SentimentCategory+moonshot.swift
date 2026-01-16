//
//  SentimentCategory+moonshot.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - MOONSHOT Commentary (80 total: 24 witty + 56 positive)

  /// Witty MOONSHOT templates (24 total)
  static let moonshotWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Up 8% but still down 83% from €145 - moral victories count",
    "From €145 to €14.92 to {currentPrice} - redemption arc loading",
    "Green candles after losing €18.1B - everyone loves a comeback story",

    // THEME: Talabat IPO Success - 4 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat $10.2B valuation making parent look cheap - family dynamics",
    "$2B IPO raise and parent still -80% from peak - irony isn't dead",
    "When subsidiary IPOs better than you ever did - passing the torch",
    "Talabat -6.9% debut, DHER up 5%+ today - character development",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Three buyers walked away but stock goes up anyway - rejection is projection",
    "Uber paid $250M to NOT buy us - that's called leverage",
    "Grab said no, Meituan said no, market says yes - pick your validator",

    // THEME: Successful M&A History - 2 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$4B Baemin → $6.2B at close - at least SOMETHING appreciated",
    "Bought Yemeksepeti for $589M, now it's a crown jewel - patience pays",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M EU fine paid, stock up 6% - immune to bad news now",
    "When regulators fine you €329M and you moon anyway - built different",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF after 13 years of losses - slow learners finish strong",
    "Lost €2.3B in 2023, €882M in 2024, green today - linear progress",
    "First profitable quarter and market acts shocked - ye of little faith",
    "€693M EBITDA and suddenly everyone's a DHER bull - where were you at €14.92?",

    // THEME: Shareholder Activism - 2 commentaries
    "Activists demand strategic review, stock moons - threats work",
    "Sachem Head bought 3.6% stake - smart money or last bagholders?",

    // THEME: Geographic Performance - 2 commentaries
    // SOURCE: https://ir.talabat.com/
    "MENA carrying so hard even Asia losses can't stop this - regional excellence",
    "Korea 90% share + MENA breakeven = unstoppable combo apparently",

    // THEME: Investment Moves - 1 commentary
    "Sold Deliveroo at £77M, kept Talabat worth $10.2B - portfolio management clinic",

    // THEME: General Observations - 1 commentary
    "Chart says moon, memory says €145, reality says we'll take it"
  ]

  /// Positive MOONSHOT templates (56 total)
  static let moonshotPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Strong momentum from €14.92 lows - recovery trajectory accelerating",
    "Trading volume surge confirms renewed investor confidence",
    "Breaking resistance levels not seen since Q2 2023 - technical strength",

    // THEME: Talabat IPO Success - 8 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat priced AED 1.60 at range top - execution excellence rewarded",
    "$2B IPO proceeds strengthen DHER balance sheet significantly",
    "Gulf's largest 2024 IPO validates MENA strategy completely",
    "Talabat GMV $7.4B (+23% YoY) drives parent valuation rerating",
    "8-country MENA leadership demonstrates scalable regional model",
    "68,000+ restaurant partners create defensible network moat",
    "6.5M active customers across MENA - user base growing double-digits",
    "22% food delivery penetration in MENA - massive runway ahead",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "$950M Foodpanda Taiwan valuation proves asset quality",
    "Uber's $250M termination fee adds non-dilutive capital",
    "Multiple suitor interest validates strategic asset value",

    // THEME: Successful M&A History - 6 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$4B Woowa investment delivered 90% Korea market dominance",
    "Baemin value jumped $4B→$6.2B between announcement and close",
    "Yemeksepeti $589M acquisition (2015) remains Turkey's top platform",
    "M&A track record: Baemin, Talabat, Yemeksepeti all market leaders",
    "Strategic acquisitions built three regional champions",
    "Woowa 21.74M users make Baemin Korea's super-app",

    // THEME: Regulatory Challenges - 3 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "Regulatory scrutiny confirms market-leading position",
    "€329M EU fine fully provisioned - no earnings surprise",
    "Compliance framework strengthened post-settlement",

    // THEME: Financial Turnaround - 12 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M positive FCF in 2024 - inflection point achieved",
    "First profitable free cash flow after 13-year investment phase",
    "€693M adjusted EBITDA vs €254M prior year - 173% growth",
    "Losses cut 62%: €882M (2024) from €2.3B (2023) - momentum clear",
    "Revenue €12.8B, up 22% YoY - top line acceleration intact",
    "GMV €48.8B (+8.3%) demonstrates platform scale",
    "€2.2B cash + €0.8B RCF provides multi-year runway",
    "Adjusted EBITDA improved €900M over 24 months - execution delivering",
    "MENA segment reached EBITDA breakeven - proof of concept",
    "Operating leverage building: EBITDA growing faster than revenue",
    "Path to profitability visible with FCF already positive",
    "Unit economics improving across all core markets",

    // THEME: Shareholder Activism - 3 commentaries
    "Major shareholders Sachem Head (3.6%) and Aspex (5%+) push value unlock",
    "Strategic review process catalyzes management action",
    "Activist engagement accelerates portfolio optimization",

    // THEME: Geographic Performance - 6 commentaries
    // SOURCE: https://ir.talabat.com/
    "MENA achieved EBITDA breakeven while maintaining growth",
    "Korea 90% market share via Baemin - unassailable position",
    "Three-continent footprint diversifies risk and opportunity",
    "Talabat Q3 GMV $2.4B (+26% YoY) - fastest growth region",
    "Korea and MENA both now EBITDA positive - portfolio maturing",
    "Geographic diversification proving strategic during recovery",

    // THEME: Investment Moves - 3 commentaries
    "Talabat IPO unlocked €1.5B for parent - financial flexibility restored",
    "Strategic asset sales fund core market investments",
    "Portfolio rationalization complete - capital efficiently deployed",

    // THEME: General Observations - 9 commentaries
    "Market recognizing sum-of-parts valuation gap closing",
    "Institutional buyers returning after FCF inflection",
    "Turnaround narrative gaining credibility with results",
    "Multiple catalysts align: FCF positive, Talabat IPO, activist pressure",
    "Parent trades below Talabat value alone - mispricing correcting",
    "Strong quarterly results validate multi-year transformation",
    "Management execution improving across all metrics",
    "From growth-at-all-costs to disciplined profitability - strategy shift working",
    "Every key metric trending right: FCF, EBITDA, revenue growth, loss reduction"
  ]
}
