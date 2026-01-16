//
//  SentimentCateogyr+gains.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - GAINS Commentary (80 total: 24 witty + 56 positive)

  /// Witty GAINS templates (24 total)
  static let gainsWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Up 2% today, down {percentFromPeak}% lifetime - perspective is everything",
    "Small green dildo after months of red - we celebrate tiny victories",
    "{currentPrice} looking better than €14.92 - bar is on floor",

    // THEME: Talabat IPO Success - 4 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "$10.2B Talabat valuation, €10.9B parent - math isn't mathing but ok",
    "Talabat closed -6.9% at debut, parent up 3% today - evolution",
    "When your kid's IPO makes you look undervalued - parenting win",
    "Dubai's biggest 2024 IPO carrying the parent company - role reversal",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Grab walked but stock up anyway - your loss buddy",
    "Three rejections and still rising - resilience or delusion?",
    "$250M breakup fee from Uber - getting paid to be dumped",

    // THEME: Successful M&A History - 2 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$4B Baemin bet looking smart despite everything else",
    "At least Yemeksepeti still prints money - Turkey coming through",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine paid, still going up - numb to pain",
    "Italian €57M labor hit, stock green - what's another fine?",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF and you're excited? Standards have fallen",
    "€882M loss down from €2.3B - we call this winning now",
    "Revenue up 22% but still losing hundreds of millions - growth!",
    "First positive FCF ever, stock up 1.5% - seems fair",

    // THEME: Shareholder Activism - 2 commentaries
    "Activists bought in at higher prices - misery loves company",
    "Strategic review = fancy words for 'anyone buying?'",

    // THEME: Geographic Performance - 2 commentaries
    "MENA breakeven offsets Asia bleeding - portfolio balance is real",
    "Korea 90% share can't carry everything but it's trying",

    // THEME: Investment Moves - 1 commentary
    "Sold Deliveroo at massive loss, Talabat IPO'd at premium - luck matters",

    // THEME: General Observations - 1 commentary
    "Gains feel different when you bought at {allTimeHigh} 🤡"
  ]

  /// Positive GAINS templates (56 total)
  static let gainsPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Steady upward trend from February 2024 lows continues",
    "Volatility declining as fundamentals improve",
    "Base-building phase establishing support levels",

    // THEME: Talabat IPO Success - 8 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat $2B raise demonstrates MENA platform strength",
    "IPO success highlights value embedded in parent portfolio",
    "MENA 22% food penetration shows early-stage growth opportunity",
    "Talabat 68,000 merchants create strong network effects",
    "Q3 GMV $2.4B (+26% YoY) confirms MENA momentum",
    "Market leadership across 8 countries drives pricing power",
    "Talabat GMV growth accelerating while improving margins",
    "Strong IPO demand validates DHER's asset quality",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "$950M Foodpanda valuation benchmarks asset worth",
    "Retained strategic assets provide future optionality",
    "Multiple bidders confirm competitive positioning",

    // THEME: Successful M&A History - 6 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Baemin 90% Korea market share - acquisition delivered",
    "Woowa 21.74M users represent massive scale",
    "Yemeksepeti maintains Turkey market leadership since 2015",
    "B-rated humor marketing creates brand differentiation in Korea",
    "M&A created market leaders across three continents",
    "Strategic acquisitions now generating positive cash flow",

    // THEME: Regulatory Challenges - 3 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine resolved - regulatory overhang removed",
    "Compliance investment strengthens long-term position",
    "Market leadership worth regulatory attention",

    // THEME: Financial Turnaround - 12 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF marks critical inflection point",
    "13-year investment phase yielding cash generation",
    "€693M adjusted EBITDA shows operating leverage",
    "Loss reduction 62% YoY - trajectory sustained",
    "Revenue €12.8B (+22%) with margin expansion",
    "GMV €48.8B demonstrates platform network effects",
    "€2.2B cash provides strategic flexibility",
    "All key metrics improving simultaneously",
    "MENA EBITDA breakeven proves regional model",
    "Operating margins improving across segments",
    "Path to sustained profitability now clear",
    "Management executing turnaround playbook effectively",

    // THEME: Shareholder Activism - 3 commentaries
    "Major shareholders advocate for value maximization",
    "Strategic review driving operational improvements",
    "Activist involvement accelerates decision-making",

    // THEME: Geographic Performance - 6 commentaries
    "MENA breakeven with 26% growth - sustainable model",
    "Korea remains cash-generating anchor asset",
    "Portfolio optimization focusing capital on winners",
    "Three-region strategy diversifying revenue streams",
    "Geographic footprint provides growth optionality",
    "Regional leadership positions defensible long-term",

    // THEME: Investment Moves - 3 commentaries
    "Talabat IPO proceeds enable strategic investments",
    "Portfolio simplification improving capital efficiency",
    "Asset monetization funding core market expansion",

    // THEME: General Observations - 9 commentaries
    "Turnaround story gaining investor recognition",
    "Valuation discount to Talabat alone narrowing",
    "Multiple positive catalysts supporting momentum",
    "Management credibility improving with results delivery",
    "Market sentiment shifting as fundamentals improve",
    "Risk/reward profile improving with FCF generation",
    "Every quarter builds evidence of sustainable turnaround",
    "From crisis to stability phase transition underway",
    "Operational improvements translating to shareholder value"
  ]
}
