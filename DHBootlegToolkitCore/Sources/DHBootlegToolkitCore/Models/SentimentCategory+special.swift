//
//  SentimeryCategory+special.swift
//  DHOpsToolsCore
//
//  Created by Romy Cheah on 16/1/26.
//

extension SentimentCategory {
  // MARK: - SPECIAL Contextual Templates (53 total: 32 witty + 21 positive)

  /// Witty special templates (32 total)
  static let specialWittyTemplates: [String] = [
    // THEME: Stock Performance Journey - 4 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "€145 peak → €14.92 bottom → {currentPrice} now - the full DeliveryHero experience™",
    "POV: Still holding since {allTimeHigh} 💀",
    "{percentFromPeak}% down from peak - we don't use that emoji anymore",
    "IPO €25.50 → €145 peak → below IPO again - full circle of pain",

    // THEME: Talabat IPO Success - 5 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat -6.9% debut was actually good - perspective adjustment complete",
    "$10.2B child, €10.9B parent - kids worth almost as much as parents",
    "When subsidiary IPOs better than parent ever did - passing torch or shade?",
    "Dubai's biggest 2024 IPO, Frankfurt's biggest disappointment - geographic arbitrage",
    "$2B raised, Talabat GMV $7.4B - maybe MENA was the play all along",

    // THEME: Failed M&A Attempts - 5 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Uber + Foodpanda Taiwan = 90% share = regulators said NOPE",
    "Grab, Meituan, AND Uber all swiped left 👈",
    "Three potential buyers, zero deals - Foodpanda's Tinder profile",
    "$250M termination fee - getting paid to be rejected is the ultimate flex",
    "When THREE bidders walk away, maybe it's not them, it's us 🤔",

    // THEME: Successful M&A History - 4 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "$589M Yemeksepeti → $4B Baemin → $10.2B Talabat - M&A inflation is real",
    "Baemin 90% Korea share - monopolies are illegal unless you're really good",
    "$4B→$6.2B Baemin by closing - some bets hit, most don't",
    "Bought Woowa for $4B, parent worth €10.9B - tail wagging dog",

    // THEME: Regulatory Challenges - 4 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M EU fine for no-poach with Glovo - cartels are expensive",
    "Italian labor ruling €57M - that's 57% of your €99M FCF",
    "Korea: 'Sell Yogiyo or no Baemin' - regulators don't negotiate",
    "€329M fine + €57M labor + $250M termination = compliance is the new COGS",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "13 years to positive FCF - at this rate, profitable by 2037",
    "€2.3B loss → €882M loss - we call this 'progress' now",
    "€99M FCF, €882M net loss - GAAP and cash flow live in different universes",
    "Revenue €12.8B (+22%), still losing €882M - scale doesn't always save you",

    // THEME: Shareholder Activism - 2 commentaries
    "Strategic review = corporate Tinder - swipe right if interested",
    "Sachem Head 3.6%, Aspex 5%+ - activists accumulating or catching knives?",

    // THEME: Geographic Performance - 2 commentaries
    "MENA breakeven, Asia down 8% - portfolio balance is fragile",
    "Korea 90% share can't carry the whole empire - ask Rome",

    // THEME: Investment Moves - 1 commentary
    "Deliveroo £284M buy → £77M sell - reverse Midas touch",

    // THEME: General Observations - 1 commentary
    "Food delivery: high revenue, low margins, brutal competition - picked great industry"
  ]

  /// Positive special templates (21 total)
  static let specialPositiveTemplates: [String] = [
    // THEME: Stock Performance Journey - 2 commentaries
    // SOURCE: https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
    "From €14.92 low to {currentPrice} - recovery trajectory established",
    "€18.1B lost but infrastructure worth more - value disconnect",

    // THEME: Talabat IPO Success - 3 commentaries
    // SOURCE: https://www.menabytes.com/talabat-final-ipo-price/
    "Talabat: $2B raised, $10.2B valued, 8 countries led - MENA dominance blueprint",
    "$7.4B GMV (+23% YoY) shows subsidiary quality - parent contains more",
    "IPO unlocked €1.5B while retaining 75% ownership - financial engineering worked",

    // THEME: Failed M&A Attempts - 2 commentaries
    // SOURCE: https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
    "Multiple $950M valuations despite no deal - market anchoring achieved",
    "$250M termination fee = strategic optionality has tangible value",

    // THEME: Successful M&A History - 4 commentaries
    // SOURCE: https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
    "Yemeksepeti $589M (2015), Baemin $4B (2019), Talabat $10.2B (2024) - M&A built empire",
    "Three regional champions: Korea 90%, MENA leader, Turkey dominant",
    "Woowa 21.74M users + Talabat 6.5M customers = 28M+ captive base",
    "$4B Baemin valued $6.2B at close - strategic M&A creates value",

    // THEME: Regulatory Challenges - 2 commentaries
    // SOURCE: https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
    "€329M fine resolved - regulatory overhang eliminated",
    "Regulatory scrutiny confirms market leadership position",

    // THEME: Financial Turnaround - 4 commentaries
    // SOURCE: https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
    "€99M FCF (first ever) + €693M EBITDA - dual inflection achieved",
    "GMV €38B→€50B (32% growth) while turning FCF positive - scale + efficiency",
    "Loss cut 62% YoY while revenue +22% - operating leverage materializing",
    "€2.2B cash + €0.8B RCF - runway to execute multi-year plan",

    // THEME: Shareholder Activism - 1 commentary
    "Sachem Head + Aspex ownership >8% - aligned shareholders pushing value",

    // THEME: Geographic Performance - 2 commentaries
    "MENA breakeven + Korea cash positive = 2 of 3 regions profitable",
    "Three-continent portfolio diversifies risk while maintaining leadership",

    // THEME: General Observations - 1 commentary
    "Sum-of-parts: Talabat $10.2B + Baemin $6B+ + Turkey > parent €10.9B market cap"
  ]
}
