import Foundation

/// Sentiment categories based on price change thresholds
public enum SentimentCategory: String, Sendable, CaseIterable {
    case moonshot   // >= +5%
    case gains      // +1% to +4.99%
    case flat       // -0.99% to +0.99%
    case losses     // -1% to -4.99%
    case crash      // <= -5%

    /// Emoji representation for this sentiment
    public var emoji: String {
        switch self {
        case .moonshot:
            return "🚀📈"
        case .gains:
            return "📈"
        case .flat:
            return "😴"
        case .losses:
            return "📉"
        case .crash:
            return "💸📉"
        }
    }

    /// Human-readable label
    public var label: String {
        switch self {
        case .moonshot:
            return "Moonshot"
        case .gains:
            return "Gains"
        case .flat:
            return "Flat"
        case .losses:
            return "Losses"
        case .crash:
            return "Crash"
        }
    }

    /// Determine category from price change percentage (using fixed thresholds)
    public static func from(priceChangePercent: Double) -> SentimentCategory {
        return from(priceChangePercent: priceChangePercent, thresholds: .fixed)
    }

    /// Determine category from price change percentage with dynamic thresholds
    /// - Parameters:
    ///   - priceChangePercent: Price change as percentage (e.g., 2.5 for +2.5%)
    ///   - thresholds: Dynamic threshold values (or .fixed for baseline thresholds)
    /// - Returns: Appropriate sentiment category based on thresholds
    public static func from(
        priceChangePercent: Double,
        thresholds: DynamicThreshold
    ) -> SentimentCategory {
        switch priceChangePercent {
        case thresholds.moonshot...:
            return .moonshot
        case thresholds.gainsLower..<thresholds.moonshot:
            return .gains
        case thresholds.flatLower..<thresholds.flatUpper:
            return .flat
        case thresholds.lossesLower..<thresholds.flatLower:
            return .losses
        default: // <= crash threshold
            return .crash
        }
    }

    /// Witty, sarcastic commentary templates
    /// Placeholders: {percentFromPeak}, {allTimeHigh}, {currentPrice}, {currency}, {symbol}
    public var wittyCommentaryTemplates: [String] {
        switch self {
        case .moonshot:
            return Self.moonshotWittyTemplates
        case .gains:
            return Self.gainsWittyTemplates
        case .flat:
            return Self.flatWittyTemplates
        case .losses:
            return Self.lossesWittyTemplates
        case .crash:
            return Self.crashWittyTemplates
        }
    }

    /// Positive, encouraging commentary templates (news-grounded & contextual)
    /// Placeholders: {percentFromPeak}, {allTimeHigh}, {currentPrice}, {currency}, {symbol}
    public var positiveCommentaryTemplates: [String] {
        switch self {
        case .moonshot:
            return Self.moonshotPositiveTemplates
        case .gains:
            return Self.gainsPositiveTemplates
        case .flat:
            return Self.flatPositiveTemplates
        case .losses:
            return Self.lossesPositiveTemplates
        case .crash:
            return Self.crashPositiveTemplates
        }
    }

    /// Combined commentary templates (witty + positive)
    /// Used by CommentaryEngine for random selection
    public var commentaryTemplates: [String] {
        return wittyCommentaryTemplates + positiveCommentaryTemplates
    }

    /// Witty, cynical special templates (contextual)
    public static var wittySpecialTemplates: [String] {
        return specialWittyTemplates
    }

    /// Positive, inspirational special templates (contextual & news-grounded)
    public static var positiveSpecialTemplates: [String] {
        return specialPositiveTemplates
    }

    /// Special contextual commentary templates (10% chance to show)
    /// Combined witty and positive for variety
    public static var specialContextualTemplates: [String] {
        return wittySpecialTemplates + positiveSpecialTemplates
    }

    /// Commentary source URLs for UI display
    /// Maps commentary text (with placeholders) to source URL
    /// Returns nil if commentary has no specific source
    public static func sourceURL(for commentary: String) -> URL? {
        return commentarySourceMap[commentary]
    }

    /// Internal map of commentary to source URLs
    private static let commentarySourceMap: [String: URL] = {
        var map: [String: URL] = [:]

        // Stock crash history - https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html
        if let stockHistory = URL(string: "https://finance.yahoo.com/news/delivery-hero-etr-dher-investor-three-year-losses-grow-to-68-as-the-stock-sheds-%E2%82%AC279m-this-past-week-090124503.html") {
            // Moonshot - 6 mappings
            map["Up 8% but still down 83% from €145 - moral victories count"] = stockHistory
            map["From €145 to €14.92 to {currentPrice} - redemption arc loading"] = stockHistory
            map["Green candles after losing €18.1B - everyone loves a comeback story"] = stockHistory
            map["Strong momentum from €14.92 lows - recovery trajectory accelerating"] = stockHistory
            map["Trading volume surge confirms renewed investor confidence"] = stockHistory
            map["Breaking resistance levels not seen since Q2 2023 - technical strength"] = stockHistory

            // Gains - 6 mappings
            map["Up 2% today, down {percentFromPeak}% lifetime - perspective is everything"] = stockHistory
            map["Small green dildo after months of red - we celebrate tiny victories"] = stockHistory
            map["{currentPrice} looking better than €14.92 - bar is on floor"] = stockHistory
            map["Steady upward trend from February 2024 lows continues"] = stockHistory
            map["Volatility declining as fundamentals improve"] = stockHistory
            map["Base-building phase establishing support levels"] = stockHistory

            // Flat - 6 mappings
            map["Flat at {currentPrice}, memories at €145 - reconciliation pending"] = stockHistory
            map["Zero movement but still down {percentFromPeak}% - context matters"] = stockHistory
            map["Sideways is the new up when you've lost €18.1B"] = stockHistory
            map["Consolidation creates foundation for next move higher"] = stockHistory
            map["Stability after recovery from €14.92 lows is healthy"] = stockHistory
            map["Range-bound trading allows fundamentals to catch up"] = stockHistory

            // Losses - 6 mappings
            map["Down 2% today, down {percentFromPeak}% forever - consistency"] = stockHistory
            map["€145 → {currentPrice} - the long road to enlightenment"] = stockHistory
            map["Red is the new black in this portfolio"] = stockHistory
            map["Short-term volatility doesn't change long-term fundamentals"] = stockHistory
            map["Recovery from €14.92 remains intact despite today"] = stockHistory
            map["Turnaround stories include setbacks - part of process"] = stockHistory

            // Crash - 6 mappings
            map["€18.1B vaporized - at least the tax loss harvest is epic"] = stockHistory
            map["€145 to {currentPrice} - the masterclass nobody wanted"] = stockHistory
            map["Down {percentFromPeak}% - we don't talk about the glory days"] = stockHistory
            map["Survived €14.92 low and subsequent recovery - resilience proven"] = stockHistory
            map["Business fundamentals disconnected from daily volatility"] = stockHistory
            map["Historic crashes often precede strongest recoveries"] = stockHistory

            // Special - 6 mappings
            map["€145 peak → €14.92 bottom → {currentPrice} now - the full DeliveryHero experience™"] = stockHistory
            map["POV: Still holding since {allTimeHigh} 💀"] = stockHistory
            map["{percentFromPeak}% down from peak - we don't use that emoji anymore"] = stockHistory
            map["IPO €25.50 → €145 peak → below IPO again - full circle of pain"] = stockHistory
            map["From €14.92 low to {currentPrice} - recovery trajectory established"] = stockHistory
            map["€18.1B lost but infrastructure worth more - value disconnect"] = stockHistory
        }

        // Talabat IPO - https://www.menabytes.com/talabat-final-ipo-price/
        if let talabatIPO = URL(string: "https://www.menabytes.com/talabat-final-ipo-price/") {
            // Moonshot - 12 mappings
            map["Talabat $10.2B valuation making parent look cheap - family dynamics"] = talabatIPO
            map["$2B IPO raise and parent still -80% from peak - irony isn't dead"] = talabatIPO
            map["When subsidiary IPOs better than you ever did - passing the torch"] = talabatIPO
            map["Talabat -6.9% debut, DHER up 5%+ today - character development"] = talabatIPO
            map["Talabat priced AED 1.60 at range top - execution excellence rewarded"] = talabatIPO
            map["$2B IPO proceeds strengthen DHER balance sheet significantly"] = talabatIPO
            map["Gulf's largest 2024 IPO validates MENA strategy completely"] = talabatIPO
            map["Talabat GMV $7.4B (+23% YoY) drives parent valuation rerating"] = talabatIPO
            map["8-country MENA leadership demonstrates scalable regional model"] = talabatIPO
            map["68,000+ restaurant partners create defensible network moat"] = talabatIPO
            map["6.5M active customers across MENA - user base growing double-digits"] = talabatIPO
            map["22% food delivery penetration in MENA - massive runway ahead"] = talabatIPO

            // Gains - 12 mappings
            map["$10.2B Talabat valuation, €10.9B parent - math isn't mathing but ok"] = talabatIPO
            map["Talabat closed -6.9% at debut, parent up 3% today - evolution"] = talabatIPO
            map["When your kid's IPO makes you look undervalued - parenting win"] = talabatIPO
            map["Dubai's biggest 2024 IPO carrying the parent company - role reversal"] = talabatIPO
            map["Talabat $2B raise demonstrates MENA platform strength"] = talabatIPO
            map["IPO success highlights value embedded in parent portfolio"] = talabatIPO
            map["MENA 22% food penetration shows early-stage growth opportunity"] = talabatIPO
            map["Talabat 68,000 merchants create strong network effects"] = talabatIPO
            map["Q3 GMV $2.4B (+26% YoY) confirms MENA momentum"] = talabatIPO
            map["Market leadership across 8 countries drives pricing power"] = talabatIPO
            map["Talabat GMV growth accelerating while improving margins"] = talabatIPO
            map["Strong IPO demand validates DHER's asset quality"] = talabatIPO

            // Flat - 12 mappings
            map["Talabat worth $10.2B, parent flat - market needs calculator"] = talabatIPO
            map["Subsidiary IPO'd, parent didn't move - family dysfunction"] = talabatIPO
            map["$2B raised and we're trading sideways - enthusiasm gap"] = talabatIPO
            map["When your kid succeeds but you still feel nothing - emotional flatline"] = talabatIPO
            map["Talabat IPO success validates long-term MENA strategy"] = talabatIPO
            map["$10.2B valuation highlights embedded parent company value"] = talabatIPO
            map["Market digesting implications of successful IPO"] = talabatIPO
            map["MENA platform worth more than market currently recognizes"] = talabatIPO
            map["Talabat $7.4B GMV establishes regional leadership"] = talabatIPO
            map["68,000 merchants demonstrate ecosystem strength"] = talabatIPO
            map["22% MENA penetration leaves significant growth runway"] = talabatIPO
            map["Time needed to assess full strategic value of IPO"] = talabatIPO

            // Losses - 12 mappings
            map["Talabat IPO'd for $10.2B, parent bleeds - life isn't fair"] = talabatIPO
            map["Subsidiary worth more than parent - awkward family dinner"] = talabatIPO
            map["$2B raised, stock falls - market says 'not enough'"] = talabatIPO
            map["Dubai celebrated, Frankfurt mourned - tale of two cities"] = talabatIPO
            map["Talabat $10.2B value highlights parent discount"] = talabatIPO
            map["MENA IPO success validates strategy despite stock move"] = talabatIPO
            map["$2B proceeds strengthen parent regardless of price"] = talabatIPO
            map["Talabat GMV growth 23% continues unaffected"] = talabatIPO
            map["Regional leadership position remains unchanged"] = talabatIPO
            map["68,000 merchant relationships provide value floor"] = talabatIPO
            map["MENA 22% penetration upside intact"] = talabatIPO
            map["IPO unlocked €1.5B value for strategic use"] = talabatIPO

            // Crash - 12 mappings
            map["$10.2B subsidiary, crashing parent - generational wealth transfer"] = talabatIPO
            map["Talabat IPO success couldn't save this - not even close"] = talabatIPO
            map["$2B raised, €2B lost - perfect equilibrium of pain"] = talabatIPO
            map["Dubai's pride, Frankfurt's shame - geographic arbitrage failed"] = talabatIPO
            map["Talabat $10.2B valuation independent of parent stock price"] = talabatIPO
            map["$2B IPO proceeds already received and deployed"] = talabatIPO
            map["MENA platform value unchanged by market sentiment"] = talabatIPO
            map["Talabat GMV growth 23% continues regardless"] = talabatIPO
            map["68,000 merchant network intact and growing"] = talabatIPO
            map["Regional leadership unaffected by Frankfurt trading"] = talabatIPO
            map["22% MENA penetration opportunity still massive"] = talabatIPO
            map["IPO success validates long-term strategy"] = talabatIPO

            // Special - 8 mappings
            map["Talabat -6.9% debut was actually good - perspective adjustment complete"] = talabatIPO
            map["$10.2B child, €10.9B parent - kids worth almost as much as parents"] = talabatIPO
            map["When subsidiary IPOs better than parent ever did - passing torch or shade?"] = talabatIPO
            map["Dubai's biggest 2024 IPO, Frankfurt's biggest disappointment - geographic arbitrage"] = talabatIPO
            map["$2B raised, Talabat GMV $7.4B - maybe MENA was the play all along"] = talabatIPO
            map["Talabat: $2B raised, $10.2B valued, 8 countries led - MENA dominance blueprint"] = talabatIPO
            map["$7.4B GMV (+23% YoY) shows subsidiary quality - parent contains more"] = talabatIPO
            map["IPO unlocked €1.5B while retaining 75% ownership - financial engineering worked"] = talabatIPO
        }

        // Uber-Foodpanda deal - https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/
        if let uberDeal = URL(string: "https://techcrunch.com/2025/03/11/uber-terminates-foodpanda-taiwan-acquisition-citing-regulatory-hurdles/") {
            // Moonshot - 6 mappings
            map["Three buyers walked away but stock goes up anyway - rejection is projection"] = uberDeal
            map["Uber paid $250M to NOT buy us - that's called leverage"] = uberDeal
            map["Grab said no, Meituan said no, market says yes - pick your validator"] = uberDeal
            map["$950M Foodpanda Taiwan valuation proves asset quality"] = uberDeal
            map["Uber's $250M termination fee adds non-dilutive capital"] = uberDeal
            map["Multiple suitor interest validates strategic asset value"] = uberDeal

            // Gains - 6 mappings
            map["Grab walked but stock up anyway - your loss buddy"] = uberDeal
            map["Three rejections and still rising - resilience or delusion?"] = uberDeal
            map["$250M breakup fee from Uber - getting paid to be dumped"] = uberDeal
            map["$950M Foodpanda valuation benchmarks asset worth"] = uberDeal
            map["Retained strategic assets provide future optionality"] = uberDeal
            map["Multiple bidders confirm competitive positioning"] = uberDeal

            // Flat - 6 mappings
            map["Three buyers walked, stock flat - nobody knows what to feel"] = uberDeal
            map["$250M termination fee, zero stock reaction - completely numb"] = uberDeal
            map["Failed deals are Tuesday's news - desensitized to disappointment"] = uberDeal
            map["Asset retention preserves strategic flexibility"] = uberDeal
            map["$250M termination fee provides non-dilutive capital"] = uberDeal
            map["Failed transactions preserve valuable optionality"] = uberDeal

            // Losses - 6 mappings
            map["Uber walked, Grab walked, Meituan walked - unanimous verdict"] = uberDeal
            map["$950M valuation, zero buyers - asset or liability?"] = uberDeal
            map["Three rejections and stock agrees - validation hurts"] = uberDeal
            map["$250M termination fee offsets transaction costs"] = uberDeal
            map["Strategic assets retained for better timing"] = uberDeal
            map["No deal better than dilutive deal - discipline"] = uberDeal

            // Crash - 6 mappings
            map["THREE buyers said no, market says hell no - consensus"] = uberDeal
            map["Uber paid $250M to NOT own this - smartest money"] = uberDeal
            map["Grab, Meituan, Uber all passed - they knew something"] = uberDeal
            map["$250M termination fee secured regardless of stock"] = uberDeal
            map["Strategic assets remain available for optimal timing"] = uberDeal
            map["Multiple suitor interest proves underlying value"] = uberDeal

            // Special - 7 mappings
            map["Uber + Foodpanda Taiwan = 90% share = regulators said NOPE"] = uberDeal
            map["Grab, Meituan, AND Uber all swiped left 👈"] = uberDeal
            map["Three potential buyers, zero deals - Foodpanda's Tinder profile"] = uberDeal
            map["$250M termination fee - getting paid to be rejected is the ultimate flex"] = uberDeal
            map["When THREE bidders walk away, maybe it's not them, it's us 🤔"] = uberDeal
            map["Multiple $950M valuations despite no deal - market anchoring achieved"] = uberDeal
            map["$250M termination fee = strategic optionality has tangible value"] = uberDeal
        }

        // Baemin/Woowa acquisition - https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/
        if let baeminDeal = URL(string: "https://gnss.asia/blog/delivery-hero-acquires-koreas-top-food-delivery-app-operator-for-us-4bn/") {
            // Moonshot - 8 mappings
            map["$4B Baemin → $6.2B at close - at least SOMETHING appreciated"] = baeminDeal
            map["Bought Yemeksepeti for $589M, now it's a crown jewel - patience pays"] = baeminDeal
            map["$4B Woowa investment delivered 90% Korea market dominance"] = baeminDeal
            map["Baemin value jumped $4B→$6.2B between announcement and close"] = baeminDeal
            map["Yemeksepeti $589M acquisition (2015) remains Turkey's top platform"] = baeminDeal
            map["M&A track record: Baemin, Talabat, Yemeksepeti all market leaders"] = baeminDeal
            map["Strategic acquisitions built three regional champions"] = baeminDeal
            map["Woowa 21.74M users make Baemin Korea's super-app"] = baeminDeal

            // Gains - 8 mappings
            map["$4B Baemin bet looking smart despite everything else"] = baeminDeal
            map["At least Yemeksepeti still prints money - Turkey coming through"] = baeminDeal
            map["Baemin 90% Korea market share - acquisition delivered"] = baeminDeal
            map["Woowa 21.74M users represent massive scale"] = baeminDeal
            map["Yemeksepeti maintains Turkey market leadership since 2015"] = baeminDeal
            map["B-rated humor marketing creates brand differentiation in Korea"] = baeminDeal
            map["M&A created market leaders across three continents"] = baeminDeal
            map["Strategic acquisitions now generating positive cash flow"] = baeminDeal

            // Flat - 8 mappings
            map["Baemin worth billions, parent flat - market is confused"] = baeminDeal
            map["90% Korea share doesn't move needle anymore - expectations broken"] = baeminDeal
            map["Baemin, Talabat, Yemeksepeti all performing well"] = baeminDeal
            map["M&A strategy built three regional champions"] = baeminDeal
            map["Korea 90% market share remains defensible"] = baeminDeal
            map["Portfolio quality evident in stable performance"] = baeminDeal
            map["Strategic acquisitions delivering long-term value"] = baeminDeal
            map["Regional market leaders provide earnings stability"] = baeminDeal

            // Losses - 8 mappings
            map["$4B Baemin can't save parent company - too much damage"] = baeminDeal
            map["Even 90% Korea share can't stop this bleed"] = baeminDeal
            map["Baemin 90% Korea share - strategic cornerstone"] = baeminDeal
            map["Woowa acquisition delivering consistent cash flow"] = baeminDeal
            map["Yemeksepeti provides Turkey market stability"] = baeminDeal
            map["M&A portfolio generating positive returns"] = baeminDeal
            map["Three regional leaders buffer market swings"] = baeminDeal
            map["21.74M Baemin users represent durable asset"] = baeminDeal

            // Crash - 8 mappings
            map["$4B Baemin drowning with parent ship - no lifeboat big enough"] = baeminDeal
            map["90% Korea share, -10% stock today - dominance isn't enough"] = baeminDeal
            map["Baemin 90% Korea share - cash generation unchanged"] = baeminDeal
            map["Woowa 21.74M users continue driving revenue"] = baeminDeal
            map["Yemeksepeti Turkey leadership position solid"] = baeminDeal
            map["M&A portfolio value exceeds current market cap"] = baeminDeal
            map["Three regional champions operate independently"] = baeminDeal
            map["Strategic acquisitions delivering regardless of stock"] = baeminDeal

            // Special - 8 mappings
            map["$589M Yemeksepeti → $4B Baemin → $10.2B Talabat - M&A inflation is real"] = baeminDeal
            map["Baemin 90% Korea share - monopolies are illegal unless you're really good"] = baeminDeal
            map["$4B→$6.2B Baemin by closing - some bets hit, most don't"] = baeminDeal
            map["Bought Woowa for $4B, parent worth €10.9B - tail wagging dog"] = baeminDeal
            map["Yemeksepeti $589M (2015), Baemin $4B (2019), Talabat $10.2B (2024) - M&A built empire"] = baeminDeal
            map["Three regional champions: Korea 90%, MENA leader, Turkey dominant"] = baeminDeal
            map["Woowa 21.74M users + Talabat 6.5M customers = 28M+ captive base"] = baeminDeal
            map["$4B Baemin valued $6.2B at close - strategic M&A creates value"] = baeminDeal
        }

        // EU fine - https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case
        if let euFine = URL(string: "https://www.gtlaw.com/en/insights/2025/8/european-commission-fines-delivery-hero-and-glovo-eur-329-million-in-first-labor-market-cartel-case") {
            // Moonshot - 5 mappings
            map["€329M EU fine paid, stock up 6% - immune to bad news now"] = euFine
            map["When regulators fine you €329M and you moon anyway - built different"] = euFine
            map["Regulatory scrutiny confirms market-leading position"] = euFine
            map["€329M EU fine fully provisioned - no earnings surprise"] = euFine
            map["Compliance framework strengthened post-settlement"] = euFine

            // Gains - 5 mappings
            map["€329M fine paid, still going up - numb to pain"] = euFine
            map["Italian €57M labor hit, stock green - what's another fine?"] = euFine
            map["€329M fine resolved - regulatory overhang removed"] = euFine
            map["Compliance investment strengthens long-term position"] = euFine
            map["Market leadership worth regulatory attention"] = euFine

            // Flat - 5 mappings
            map["€329M fine is just background noise now"] = euFine
            map["Italian €57M hit, market shrugs - priced in everything"] = euFine
            map["Regulatory matters resolved and behind company"] = euFine
            map["Compliance framework now industry-leading"] = euFine
            map["Fines fully provisioned with no additional exposure"] = euFine

            // Losses - 5 mappings
            map["€329M fine on top of losses - kick while down"] = euFine
            map["Italian €57M equals 57% of FCF - math is cruel"] = euFine
            map["€329M fine fully resolved - future clarity"] = euFine
            map["Compliance investments prevent future issues"] = euFine
            map["Regulatory challenges manageable at scale"] = euFine

            // Crash - 5 mappings
            map["€329M fine, €882M loss, -8% day - triple threat"] = euFine
            map["When EU fines you AND market dumps you - global rejection"] = euFine
            map["€329M fine already paid and resolved"] = euFine
            map["Regulatory matters behind company now"] = euFine
            map["Compliance framework prevents future issues"] = euFine

            // Special - 6 mappings
            map["€329M EU fine for no-poach with Glovo - cartels are expensive"] = euFine
            map["Italian labor ruling €57M - that's 57% of your €99M FCF"] = euFine
            map["Korea: 'Sell Yogiyo or no Baemin' - regulators don't negotiate"] = euFine
            map["€329M fine + €57M labor + $250M termination = compliance is the new COGS"] = euFine
            map["€329M fine resolved - regulatory overhang eliminated"] = euFine
            map["Regulatory scrutiny confirms market leadership position"] = euFine
        }

        // Financial results - https://www.deliveryhero.com/newsroom/trading-update-q4-2024/
        if let financials = URL(string: "https://www.deliveryhero.com/newsroom/trading-update-q4-2024/") {
            // Moonshot - 16 mappings
            map["€99M FCF after 13 years of losses - slow learners finish strong"] = financials
            map["Lost €2.3B in 2023, €882M in 2024, green today - linear progress"] = financials
            map["First profitable quarter and market acts shocked - ye of little faith"] = financials
            map["€693M EBITDA and suddenly everyone's a DHER bull - where were you at €14.92?"] = financials
            map["€99M positive FCF in 2024 - inflection point achieved"] = financials
            map["First profitable free cash flow after 13-year investment phase"] = financials
            map["€693M adjusted EBITDA vs €254M prior year - 173% growth"] = financials
            map["Losses cut 62%: €882M (2024) from €2.3B (2023) - momentum clear"] = financials
            map["Revenue €12.8B, up 22% YoY - top line acceleration intact"] = financials
            map["GMV €48.8B (+8.3%) demonstrates platform scale"] = financials
            map["€2.2B cash + €0.8B RCF provides multi-year runway"] = financials
            map["Adjusted EBITDA improved €900M over 24 months - execution delivering"] = financials
            map["MENA segment reached EBITDA breakeven - proof of concept"] = financials
            map["Operating leverage building: EBITDA growing faster than revenue"] = financials
            map["Path to profitability visible with FCF already positive"] = financials
            map["Unit economics improving across all core markets"] = financials

            // Gains - 16 mappings
            map["€99M FCF and you're excited? Standards have fallen"] = financials
            map["€882M loss down from €2.3B - we call this winning now"] = financials
            map["Revenue up 22% but still losing hundreds of millions - growth!"] = financials
            map["First positive FCF ever, stock up 1.5% - seems fair"] = financials
            map["€99M FCF marks critical inflection point"] = financials
            map["13-year investment phase yielding cash generation"] = financials
            map["€693M adjusted EBITDA shows operating leverage"] = financials
            map["Loss reduction 62% YoY - trajectory sustained"] = financials
            map["Revenue €12.8B (+22%) with margin expansion"] = financials
            map["GMV €48.8B demonstrates platform network effects"] = financials
            map["€2.2B cash provides strategic flexibility"] = financials
            map["All key metrics improving simultaneously"] = financials
            map["MENA EBITDA breakeven proves regional model"] = financials
            map["Operating margins improving across segments"] = financials
            map["Path to sustained profitability now clear"] = financials
            map["Management executing turnaround playbook effectively"] = financials

            // Flat - 16 mappings
            map["€99M FCF doesn't excite anyone - standards too high"] = financials
            map["€693M EBITDA, stock flat - good news is boring"] = financials
            map["Lost €882M, market yawns - expectations managed to zero"] = financials
            map["Revenue up 22%, market unmoved - show me profit"] = financials
            map["€99M FCF sustaining into subsequent quarters"] = financials
            map["€693M EBITDA provides stable earnings base"] = financials
            map["€2.2B cash ensures balance sheet strength"] = financials
            map["Loss reduction continuing at steady pace"] = financials
            map["Revenue growth 22% demonstrates top-line momentum"] = financials
            map["GMV €48.8B shows platform scale maintained"] = financials
            map["Operating metrics all trending positively"] = financials
            map["MENA breakeven shows model replicability"] = financials
            map["Financial stability achieved after turnaround"] = financials
            map["Profitability path now well-defined"] = financials
            map["Management executing consistently on targets"] = financials
            map["Turnaround entering consolidation phase"] = financials

            // Losses - 16 mappings
            map["€99M FCF, €882M loss - one step forward, eight steps back"] = financials
            map["Revenue up 22%, stock down - market sees through it"] = financials
            map["€693M EBITDA doesn't mean profit - accounting is hard"] = financials
            map["13 years to break even, stock says 'too little too late'"] = financials
            map["€99M FCF represents structural improvement"] = financials
            map["Loss reduction 62% shows momentum continues"] = financials
            map["€693M EBITDA demonstrates operating model"] = financials
            map["Revenue growth 22% maintains trajectory"] = financials
            map["GMV €48.8B confirms platform strength"] = financials
            map["€2.2B cash provides downside protection"] = financials
            map["MENA breakeven validates regional strategy"] = financials
            map["Every quarter improves financial profile"] = financials
            map["Path to profitability remains on track"] = financials
            map["Operating metrics improving consistently"] = financials
            map["Turnaround fundamentals unchanged"] = financials
            map["Management execution continues delivering"] = financials

            // Crash - 16 mappings
            map["€99M FCF can't stop -10% crash - rearranging deck chairs"] = financials
            map["13 years to FCF positive, 1 day to wipe gains - cruel efficiency"] = financials
            map["€693M EBITDA meets reality - market unimpressed"] = financials
            map["Revenue up 22%, stock down 10% - market sees future"] = financials
            map["€99M positive FCF - structural breakpoint achieved"] = financials
            map["€693M EBITDA demonstrates business viability"] = financials
            map["Loss reduction 62% YoY momentum continues"] = financials
            map["Revenue €12.8B (+22%) growth trajectory intact"] = financials
            map["GMV €48.8B shows platform scale maintained"] = financials
            map["€2.2B cash provides significant downside buffer"] = financials
            map["MENA breakeven proves regional model works"] = financials
            map["Operating improvements proceeding on schedule"] = financials
            map["Profitability path clear despite stock volatility"] = financials
            map["Every financial metric improving consistently"] = financials
            map["Business transformation succeeding fundamentally"] = financials
            map["Cash generation removes existential risk"] = financials

            // Special - 8 mappings
            map["13 years to positive FCF - at this rate, profitable by 2037"] = financials
            map["€2.3B loss → €882M loss - we call this 'progress' now"] = financials
            map["€99M FCF, €882M net loss - GAAP and cash flow live in different universes"] = financials
            map["Revenue €12.8B (+22%), still losing €882M - scale doesn't always save you"] = financials
            map["€99M FCF (first ever) + €693M EBITDA - dual inflection achieved"] = financials
            map["GMV €38B→€50B (32% growth) while turning FCF positive - scale + efficiency"] = financials
            map["Loss cut 62% YoY while revenue +22% - operating leverage materializing"] = financials
            map["€2.2B cash + €0.8B RCF - runway to execute multi-year plan"] = financials
        }

        // Talabat Investor Relations - https://ir.talabat.com/
        if let talabatIR = URL(string: "https://ir.talabat.com/") {
            // Moonshot - 2 mappings
            map["MENA carrying so hard even Asia losses can't stop this - regional excellence"] = talabatIR
            map["Korea 90% share + MENA breakeven = unstoppable combo apparently"] = talabatIR
        }

        return map
    }()
}
