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

    public(package) fun suilend_withdraw<P, T>(
        lending_market_instance: &mut LendingMarket<P>,
        reserve_array_index: u64,
        clock: &Clock,
        rate_limiter_exemption: Option<RateLimiterExemption<P, T>>,
        amount: u64,
        suilend_ob: &ObligationOwnerCap<P>,
        price_info: &PriceInfoObject,
        ctx: &mut TxContext
    ): Coin<T> {
        lending_market::refresh_reserve_price(lending_market_instance, reserve_array_index, clock, price_info);
        let coin = lending_market::withdraw_ctokens(lending_market_instance, reserve_array_index, suilend_ob, clock, amount, ctx);
        lending_market::redeem_ctokens_and_withdraw_liquidity<P, T>(
            lending_market_instance,
            reserve_array_index,
            clock,
            coin,
            rate_limiter_exemption,
            ctx
        )
    }
}