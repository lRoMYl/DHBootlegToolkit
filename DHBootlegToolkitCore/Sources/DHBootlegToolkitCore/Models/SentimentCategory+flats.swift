//
//  SentimentCategory+.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - FLAT Commentary (80 total: 24 witty + 56 positive)

  /// Witty FLAT templates (24 total)
  static let flatWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Flat at {currentPrice}, memories at €145 - reconciliation pending",
    "Zero movement but still down {percentFromPeak}% - context matters",
    "Sideways is the new up when you've lost €18.1B",

    // THEME: Talabat IPO Success - 4 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat worth $10.2B, parent flat - market needs calculator",
    "Subsidiary IPO'd, parent didn't move - family dysfunction",
    "$2B raised and we're trading sideways - enthusiasm gap",
    "When your kid succeeds but you still feel nothing - emotional flatline",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Three buyers walked, stock flat - nobody knows what to feel",
    "$250M termination fee, zero stock reaction - completely numb",
    "Failed deals are Tuesday's news - desensitized to disappointment",

    // THEME: Successful M&A History - 2 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Baemin worth billions, parent flat - market is confused",
    "90% Korea share doesn't move needle anymore - expectations broken",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine is just background noise now",
    "Italian €57M hit, market shrugs - priced in everything",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF doesn't excite anyone - standards too high",
    "€693M EBITDA, stock flat - good news is boring",
    "Lost €882M, market yawns - expectations managed to zero",
    "Revenue up 22%, market unmoved - show me profit",

    // THEME: Shareholder Activism - 2 commentaries
    "Strategic review announced, stock flat - seen this movie before",
    "Activists make demands, nothing happens - theater",

    // THEME: Geographic Performance - 2 commentaries
    "MENA breakeven, market indifferent - been hearing this for years",
    "Asia down 8%, nobody cares - portfolio optimization fatigue",

    // THEME: Investment Moves - 1 commentary
    "Talabat unlocked €1.5B, parent sideways - market needs more",

    // THEME: General Observations - 1 commentary
    "Consolidating between hope and despair - purgatory pricing"
  ]

  /// Positive FLAT templates (56 total)
  static let flatPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Consolidation creates foundation for next move higher",
    "Stability after recovery from €14.92 lows is healthy",
    "Range-bound trading allows fundamentals to catch up",

    // THEME: Talabat IPO Success - 8 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat IPO success validates long-term MENA strategy",
    "$10.2B valuation highlights embedded parent company value",
    "Market digesting implications of successful IPO",
    "MENA platform worth more than market currently recognizes",
    "Talabat $7.4B GMV establishes regional leadership",
    "68,000 merchants demonstrate ecosystem strength",
    "22% MENA penetration leaves significant growth runway",
    "Time needed to assess full strategic value of IPO",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Asset retention preserves strategic flexibility",
    "$250M termination fee provides non-dilutive capital",
    "Failed transactions preserve valuable optionality",

    // THEME: Successful M&A History - 6 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Baemin, Talabat, Yemeksepeti all performing well",
    "M&A strategy built three regional champions",
    "Korea 90% market share remains defensible",
    "Portfolio quality evident in stable performance",
    "Strategic acquisitions delivering long-term value",
    "Regional market leaders provide earnings stability",

    // THEME: Regulatory Challenges - 3 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "Regulatory matters resolved and behind company",
    "Compliance framework now industry-leading",
    "Fines fully provisioned with no additional exposure",

    // THEME: Financial Turnaround - 12 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF sustaining into subsequent quarters",
    "€693M EBITDA provides stable earnings base",
    "€2.2B cash ensures balance sheet strength",
    "Loss reduction continuing at steady pace",
    "Revenue growth 22% demonstrates top-line momentum",
    "GMV €48.8B shows platform scale maintained",
    "Operating metrics all trending positively",
    "MENA breakeven shows model replicability",
    "Financial stability achieved after turnaround",
    "Profitability path now well-defined",
    "Management executing consistently on targets",
    "Turnaround entering consolidation phase",

    // THEME: Shareholder Activism - 3 commentaries
    "Strategic review process ongoing constructively",
    "Major shareholders engaged on value creation",
    "Board evaluating all options methodically",

    // THEME: Geographic Performance - 6 commentaries
    "Three-region strategy providing stability",
    "MENA and Korea both EBITDA positive",
    "Geographic diversification managing risks",
    "Portfolio rationalization completed successfully",
    "Core markets all performing to plan",
    "Regional focus improving capital efficiency",

    // THEME: Investment Moves - 3 commentaries
    "Talabat IPO proceeds deployed strategically",
    "Portfolio optimization complete",
    "Capital allocation improving steadily",

    // THEME: General Observations - 9 commentaries
    "Sideways trading normal during digestion phase",
    "Fundamentals improving while stock consolidates",
    "Base-building creates platform for appreciation",
    "Market awaiting next catalyst patiently",
    "Turnaround story requires time to unfold",
    "Stability preferable to previous volatility",
    "All elements aligning for next leg higher",
    "Patient investors being rewarded over time",
    "Consolidation phase typical in turnaround stories"
  ]
}
