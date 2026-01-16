//
//  SentimentCategory+losses.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - LOSSES Commentary (80 total: 24 witty + 56 positive)

  /// Witty LOSSES templates (24 total)
  static let lossesWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Down 2% today, down {percentFromPeak}% forever - consistency",
    "€145 → {currentPrice} - the long road to enlightenment",
    "Red is the new black in this portfolio",

    // THEME: Talabat IPO Success - 4 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat IPO'd for $10.2B, parent bleeds - life isn't fair",
    "Subsidiary worth more than parent - awkward family dinner",
    "$2B raised, stock falls - market says 'not enough'",
    "Dubai celebrated, Frankfurt mourned - tale of two cities",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Uber walked, Grab walked, Meituan walked - unanimous verdict",
    "$950M valuation, zero buyers - asset or liability?",
    "Three rejections and stock agrees - validation hurts",

    // THEME: Successful M&A History - 2 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$4B Baemin can't save parent company - too much damage",
    "Even 90% Korea share can't stop this bleed",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine on top of losses - kick while down",
    "Italian €57M equals 57% of FCF - math is cruel",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF, €882M loss - one step forward, eight steps back",
    "Revenue up 22%, stock down - market sees through it",
    "€693M EBITDA doesn't mean profit - accounting is hard",
    "13 years to break even, stock says 'too little too late'",

    // THEME: Shareholder Activism - 2 commentaries
    "Strategic review means 'we're desperate' - reading between lines",
    "Activists pushing for sale - even they want out",

    // THEME: Geographic Performance - 2 commentaries
    "Asia down 8% YoY - portfolio optimization = giving up",
    "MENA breakeven, Asia bleeds, parent falls - net negative",

    // THEME: Investment Moves - 1 commentary
    "Sold Deliveroo for £77M loss - genius investing",

    // THEME: General Observations - 1 commentary
    "Buy high sell low - the DHER investor playbook"
  ]

  /// Positive LOSSES templates (56 total)
  static let lossesPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 3 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "Short-term volatility doesn't change long-term fundamentals",
    "Recovery from €14.92 remains intact despite today",
    "Turnaround stories include setbacks - part of process",

    // THEME: Talabat IPO Success - 8 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat $10.2B value highlights parent discount",
    "MENA IPO success validates strategy despite stock move",
    "$2B proceeds strengthen parent regardless of price",
    "Talabat GMV growth 23% continues unaffected",
    "Regional leadership position remains unchanged",
    "68,000 merchant relationships provide value floor",
    "MENA 22% penetration upside intact",
    "IPO unlocked €1.5B value for strategic use",

    // THEME: Failed M&A Attempts - 3 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "$250M termination fee offsets transaction costs",
    "Strategic assets retained for better timing",
    "No deal better than dilutive deal - discipline",

    // THEME: Successful M&A History - 6 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Baemin 90% Korea share - strategic cornerstone",
    "Woowa acquisition delivering consistent cash flow",
    "Yemeksepeti provides Turkey market stability",
    "M&A portfolio generating positive returns",
    "Three regional leaders buffer market swings",
    "21.74M Baemin users represent durable asset",

    // THEME: Regulatory Challenges - 3 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine fully resolved - future clarity",
    "Compliance investments prevent future issues",
    "Regulatory challenges manageable at scale",

    // THEME: Financial Turnaround - 12 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF represents structural improvement",
    "Loss reduction 62% shows momentum continues",
    "€693M EBITDA demonstrates operating model",
    "Revenue growth 22% maintains trajectory",
    "GMV €48.8B confirms platform strength",
    "€2.2B cash provides downside protection",
    "MENA breakeven validates regional strategy",
    "Every quarter improves financial profile",
    "Path to profitability remains on track",
    "Operating metrics improving consistently",
    "Turnaround fundamentals unchanged",
    "Management execution continues delivering",

    // THEME: Shareholder Activism - 3 commentaries
    "Strategic review explores value maximization",
    "Major shareholders aligned on value creation",
    "Board committed to shareholder returns",

    // THEME: Geographic Performance - 6 commentaries
    "MENA and Korea both cash positive",
    "Portfolio focus on profitable regions",
    "Asia rationalization improving margins",
    "Three-region strategy provides balance",
    "Core markets performing to expectations",
    "Geographic diversification reducing risk",

    // THEME: Investment Moves - 3 commentaries
    "Portfolio optimization ongoing systematically",
    "Capital allocation improving quarter by quarter",
    "Strategic asset sales fund growth investments",

    // THEME: General Observations - 9 commentaries
    "Today's price doesn't reflect improving fundamentals",
    "Long-term value creation process continues",
    "Market sentiment volatile but business stable",
    "Operational improvements proceeding regardless",
    "Every turnaround includes difficult days",
    "Focus remains on controllable execution",
    "Business quality improving despite stock move",
    "Patience required for full value recognition",
    "Short-term noise versus long-term signal"
  ]
}
