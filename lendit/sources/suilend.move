module lendit::suilend {

    use sui::clock::Clock;
    use sui::coin::Coin;

    use suilend::lending_market;
    use suilend::reserve::{config};
    use pyth::price_info::PriceInfoObject;
    use suilend::lending_market::{LendingMarket, RateLimiterExemption, ObligationOwnerCap};

    public(package) fun suilend_deposit<P, T>(
        lending_market_instance: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        deposit: Coin<T>,
        suilend_ob: &ObligationOwnerCap<P>,
        ctx: &mut TxContext
    ) {
        let ctoken = lending_market::deposit_liquidity_and_mint_ctokens<P, T>(
            lending_market_instance,
            reserve_array_index,
            clock,
            deposit,
            ctx
        );
        lending_market::deposit_ctokens_into_obligation(lending_market_instance, reserve_array_index, suilend_ob, clock, ctoken, ctx);
    }
}