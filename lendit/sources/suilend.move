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

    public(package) fun suilend_balance<P, T> (lending_market: &LendingMarket<P>, reserve_array_index: u64, ob_cap: &ObligationOwnerCap<P>): u64 {
        let obligation = lending_market::obligation(lending_market, ob_cap.obligation_id());
        let deposits = suilend::obligation::deposits(obligation);
        let length = vector::length(deposits);
        let mut i = 0u64;
        while (i < length) {
            let deposit_ref = vector::borrow(deposits, i);
                if (deposit_ref.reserve_array_index() == reserve_array_index) {
                    let reserve = lending_market::reserve<P, T>(lending_market);
                    let ctoken_ratio = suilend::reserve::ctoken_ratio(reserve);
                    return suilend::decimal::floor(suilend::decimal::mul(
                        suilend::decimal::from( deposit_ref.deposited_ctoken_amount()),
                        ctoken_ratio
                    ))
                };
            i = i + 1;
        };
        abort 0
    }

    public(package) fun conv_to_ctoken<P, T> (lending_market: &LendingMarket<P>, amount: u64): u64 {
        let reserve = lending_market::reserve<P, T>(lending_market);
        let ctoken_ratio = suilend::reserve::ctoken_ratio(reserve);
        suilend::decimal::floor(suilend::decimal::div(
            suilend::decimal::from( amount),
            ctoken_ratio
        ))
    }

    public(package) fun suilend_apr<P, T>(lending_market: &LendingMarket<P>): u256 {
        let reserve = suilend::lending_market::reserve<P, T>(lending_market);
        let cur_util = suilend::reserve::calculate_utilization_rate(reserve);
        let borrow_apr = suilend::reserve_config::calculate_apr(config(reserve), cur_util);
        let supply_apr = suilend::reserve_config::calculate_supply_apr(config(reserve), cur_util, borrow_apr);
        suilend::decimal::to_scaled_val(supply_apr)
    }

}