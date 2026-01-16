//
//  SentimentCategory+crashes.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - CRASH Commentary (80 total: 24 witty + 56 positive)

  /// Witty CRASH templates (24 total)
  static let crashWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "€18.1B vaporized - at least the tax loss harvest is epic",
    "€145 to {currentPrice} - the masterclass nobody wanted",
    "Down {percentFromPeak}% - we don't talk about the glory days",

    // THEME: Talabat IPO Success - 4 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "$10.2B subsidiary, crashing parent - generational wealth transfer",
    "Talabat IPO success couldn't save this - not even close",
    "$2B raised, €2B lost - perfect equilibrium of pain",
    "Dubai's pride, Frankfurt's shame - geographic arbitrage failed",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "THREE buyers said no, market says hell no - consensus",
    "Uber paid $250M to NOT own this - smartest money",
    "Grab, Meituan, Uber all passed - they knew something",

    // THEME: Successful M&A History - 2 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$4B Baemin drowning with parent ship - no lifeboat big enough",
    "90% Korea share, -10% stock today - dominance isn't enough",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine, €882M loss, -8% day - triple threat",
    "When EU fines you AND market dumps you - global rejection",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF can't stop -10% crash - rearranging deck chairs",
    "13 years to FCF positive, 1 day to wipe gains - cruel efficiency",
    "€693M EBITDA meets reality - market unimpressed",
    "Revenue up 22%, stock down 10% - market sees future",

    // THEME: Shareholder Activism - 2 commentaries
    "Strategic review = last-ditch hail mary - desperation",
    "Activists demand action, market demands exit - alignment",

    // THEME: Geographic Performance - 2 commentaries
    "MENA can't carry, Asia sinking, Korea drowning - all regions red",
    "Portfolio optimization = abandoning ship systematically",

    // THEME: Investment Moves - 1 commentary
    "Talabat IPO'd at peak, parent crashes - timing is everything",

    // THEME: General Observations - 1 commentary
    "{currency}0 speedrun any% WR attempt - new PB loading"
  ]

  /// Positive CRASH templates (56 total)
  static let crashPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Survived €14.92 low and subsequent recovery - resilience proven",
    "Business fundamentals disconnected from daily volatility",
    "Historic crashes often precede strongest recoveries",

    // THEME: Talabat IPO Success - 8 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat $10.2B valuation independent of parent stock price",
    "$2B IPO proceeds already received and deployed",
    "MENA platform value unchanged by market sentiment",
    "Talabat GMV growth 23% continues regardless",
    "68,000 merchant network intact and growing",
    "Regional leadership unaffected by Frankfurt trading",
    "22% MENA penetration opportunity still massive",
    "IPO success validates long-term strategy",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "$250M termination fee secured regardless of stock",
    "Strategic assets remain available for optimal timing",
    "Multiple suitor interest proves underlying value",

    // THEME: Successful M&A History - 6 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Baemin 90% Korea share - cash generation unchanged",
    "Woowa 21.74M users continue driving revenue",
    "Yemeksepeti Turkey leadership position solid",
    "M&A portfolio value exceeds current market cap",
    "Three regional champions operate independently",
    "Strategic acquisitions delivering regardless of stock",

    // THEME: Regulatory Challenges - 3 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine already paid and resolved",
    "Regulatory matters behind company now",
    "Compliance framework prevents future issues",

    // THEME: Financial Turnaround - 12 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M positive FCF - structural breakpoint achieved",
    "€693M EBITDA demonstrates business viability",
    "Loss reduction 62% YoY momentum continues",
    "Revenue €12.8B (+22%) growth trajectory intact",
    "GMV €48.8B shows platform scale maintained",
    "€2.2B cash provides significant downside buffer",
    "MENA breakeven proves regional model works",
    "Operating improvements proceeding on schedule",
    "Profitability path clear despite stock volatility",
    "Every financial metric improving consistently",
    "Business transformation succeeding fundamentally",
    "Cash generation removes existential risk",

    // THEME: Shareholder Activism - 3 commentaries
    "Strategic review may unlock significant value",
    "Board exploring all value maximization options",
    "Major shareholders committed to turnaround",

    // THEME: Geographic Performance - 6 commentaries
    "MENA and Korea both EBITDA positive",
    "Portfolio focused on cash-generating markets",
    "Three-continent presence provides diversification",
    "Core regions performing operationally well",
    "Asia rationalization improving unit economics",
    "Geographic strategy unchanged by stock move",

    // THEME: Investment Moves - 3 commentaries
    "Talabat IPO proceeds available for opportunities",
    "Portfolio optimization creating capital flexibility",
    "Strategic asset base remains valuable",

    // THEME: General Observations - 9 commentaries
    "Crashes create asymmetric opportunity for patient capital",
    "Business worth more than current market cap",
    "Operational progress continues regardless of stock",
    "Downturn likely temporary given fundamentals",
    "Sum-of-parts valuation significantly higher",
    "Market panic creates long-term value entry",
    "Strong businesses survive crashes and thrive",
    "Historic lows often mark turnaround inflections",
    "Focus on fundamentals not daily fluctuations"
  ]
}
