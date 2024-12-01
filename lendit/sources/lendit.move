module lendit::lendit {

    use sui::coin;
    use sui::coin::Coin;
    use sui::coin::TreasuryCap;
    use sui::clock::Clock;

    // navi imports
    use lending_core::lending;
    use lending_core::pool::{Pool};
    use lending_core::storage::{Storage};
    use lending_core::account::{AccountCap};
    use lending_core::incentive_v2::{Incentive};
    use lending_core::incentive::{Incentive as IncentiveV1};
    use oracle::oracle::{PriceOracle};

    // suilend imports
    use suilend::lending_market;
    use pyth::price_info::PriceInfoObject;
    use suilend::lending_market::{LendingMarket, RateLimiterExemption, ObligationOwnerCap};

    public struct LENDIT has drop {}
    const E_INSUFFICIENT_LIQUIDITY: u64 = 0x1001;
    const E_ZERO_AMOUNT: u64 = 0x1002;

    public struct TreasuryCapHolder<phantom T> has key, store {
        id: UID,
        treasury: TreasuryCap<LENDIT>
    }

    public struct AccountCapHolder has key, store{
        id: UID,
        account_cap: AccountCap
    }

    public struct ObligationOwnerCapHolder<phantom P> has key, store {
        id: UID,
        obligation: ObligationOwnerCap<P>
    }

    public struct Reserve<phantom T> has key, store {
        id: UID,
        available_balance: Coin<T>
    }

    fun init(witness: LENDIT, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"LUSDC",
            b"LendItUSDC",
            b"",
            option::none(),
            ctx,
        );
        transfer::public_freeze_object(metadata);
        
        let treasury_holder = TreasuryCapHolder<LENDIT> {
            id: object::new(ctx),
            treasury: treasury
        };
        transfer::share_object(treasury_holder);
    }

    public fun init_admin<P, T>(
        suilend_lending_market: &mut LendingMarket<P>,
        ctx: &mut TxContext
    ) {
        let account_cap = lending::create_account(ctx);
        let account_cap_holder = AccountCapHolder {
            id: object::new(ctx),
            account_cap: account_cap
        };
        transfer::share_object(account_cap_holder);
        
        let obligation = lending_market::create_obligation(suilend_lending_market, ctx);
        let obligation_holder = ObligationOwnerCapHolder {
            id: object::new(ctx),
            obligation: obligation
        };
        transfer::share_object(obligation_holder);

        let reserve = Reserve {
            id: object::new(ctx),
            available_balance: coin::zero<T>(ctx)
        };
        transfer::share_object(reserve);
    }

    fun convert_to_shares(
        treasury_cap_holder: &TreasuryCapHolder<LENDIT>,
        assets: u64,
        total_assets: u64
    ): u64 {
        if (total_assets == 0) {
            return assets
        };
        let total_supply = coin::total_supply(&treasury_cap_holder.treasury);
        (assets * total_supply) / total_assets
    }

    fun convert_to_assets(
        treasury_cap_holder: &TreasuryCapHolder<LENDIT>,
        shares: u64,
        total_assets: u64
    ): u64 {
        let total_supply = coin::total_supply(&treasury_cap_holder.treasury);
        if (total_supply == 0) {
            return shares
        };
        (shares * total_assets) / total_supply
    }

    fun mint(
        treasury_cap_holder: &mut TreasuryCapHolder<LENDIT>,
        asset_value: u64,
        total_assets: u64,
        ctx: &mut TxContext
    ): Coin<LENDIT> {
        let shares_to_mint = convert_to_shares(treasury_cap_holder, asset_value, total_assets);
        coin::mint(&mut treasury_cap_holder.treasury, shares_to_mint, ctx)
    }

    public fun optimise<P, T>(
        clock: &Clock,
        reserve: &mut Reserve<T>,
        navi_pool: &mut Pool<T>,
        navi_storage: &mut Storage,
        navi_asset: u8,
        navi_account_cap_holder: &AccountCapHolder,
        navi_inc_v1: &mut IncentiveV1,
        navi_inc_v2: &mut Incentive,
        navi_oracle: &PriceOracle,
        suilend_lending_market: &mut LendingMarket<P>,
        suilend_obligation_cap_holder: &ObligationOwnerCapHolder<P>,
        suilend_reserve_array_index: u64,
        suilend_price_info: &PriceInfoObject,
        ctx: &mut TxContext
    ) {
        let navi_balance = lendit::navi::navi_balance(
            &navi_account_cap_holder.account_cap,
            navi_pool,
            navi_asset,
            navi_storage
        );
        let suilend_balance = lendit::suilend::suilend_balance<P, T>(
            suilend_lending_market,
            suilend_reserve_array_index,
            &suilend_obligation_cap_holder.obligation
        );
        let available_balance = coin::value(&reserve.available_balance);

        let navi_apr = lendit::navi::navi_apr(navi_storage, navi_asset);
        let suilend_apr = lendit::suilend::suilend_apr<P, T>(suilend_lending_market);

        let best_vault = if (navi_apr >= suilend_apr) { 1 } else { 2 };

        if (available_balance == 0 && navi_balance == 0 && suilend_balance == 0) {
            return
        };

        let mut withdraw_coin = withdraw(
            clock,
            0,
            navi_pool,
            navi_asset,
            navi_storage,
            navi_account_cap_holder,
            navi_inc_v1,
            navi_inc_v2,
            suilend_reserve_array_index,
            suilend_obligation_cap_holder,
            suilend_lending_market,
            suilend_price_info,
            navi_oracle,
            ctx
        );

        let available_balance_coin = coin::split(&mut reserve.available_balance, available_balance, ctx);
        coin::join(&mut withdraw_coin, available_balance_coin);

        if (best_vault == 1) {
            lendit::navi::navi_deposit(
                clock,
                navi_storage,
                navi_pool,
                navi_asset,
                &navi_account_cap_holder.account_cap,
                withdraw_coin,
                navi_inc_v1,
                navi_inc_v2
            );
        } else {
            lendit::suilend::suilend_deposit<P, T>(
                suilend_lending_market,
                suilend_reserve_array_index,
                clock,
                withdraw_coin,
                &suilend_obligation_cap_holder.obligation,
                ctx
            );
        }
    }

    fun current_balance<P, T>(
        reserve: &Reserve<T>,
        navi_pool: &Pool<T>,
        navi_storage: &mut Storage,
        navi_asset: u8,
        navi_account_cap_holder: &AccountCapHolder,
        suilend_lending_market: &LendingMarket<P>,
        suilend_reserve_array_index: u64,
        suilend_obligation_cap_holder: &ObligationOwnerCapHolder<P>
    ): u64 {
        let suilend_balance = lendit::suilend::suilend_balance<P, T>(
            suilend_lending_market,
            suilend_reserve_array_index,
            &suilend_obligation_cap_holder.obligation
        );

        let navi_balance = lendit::navi::navi_balance(
            &navi_account_cap_holder.account_cap,
            navi_pool,
            navi_asset,
            navi_storage
        );
        let available_balance = coin::value(&reserve.available_balance);
        navi_balance + suilend_balance + available_balance
    }

    public fun deposit<P, T>(
        clock: &Clock,
        asset: Coin<T>,
        treasury_cap_holder: &mut TreasuryCapHolder<LENDIT>,
        reserve: &mut Reserve<T>,
        navi_pool: &mut Pool<T>,
        navi_storage: &mut Storage,
        navi_asset: u8,
        navi_account_cap_holder: &AccountCapHolder,
        navi_inc_v1: &mut IncentiveV1,
        navi_inc_v2: &mut Incentive,
        navi_oracle: &PriceOracle,
        suilend_lending_market: &mut LendingMarket<P>,
        suilend_obligation_cap_holder: &ObligationOwnerCapHolder<P>,
        suilend_reserve_array_index: u64,
        suilend_price_info: &PriceInfoObject,
        ctx: &mut TxContext
    ): Coin<LENDIT> {
        let asset_value = coin::value(&asset);
        let current_balance = current_balance(
            reserve,
            navi_pool,
            navi_storage,
            navi_asset,
            navi_account_cap_holder,
            suilend_lending_market,
            suilend_reserve_array_index,
            suilend_obligation_cap_holder
        );
        coin::join(&mut reserve.available_balance, asset);
        let share_coin = mint(treasury_cap_holder, asset_value, current_balance, ctx);
        optimise(
            clock,
            reserve,
            navi_pool,
            navi_storage,
            navi_asset,
            navi_account_cap_holder,
            navi_inc_v1,
            navi_inc_v2,
            navi_oracle,
            suilend_lending_market,
            suilend_obligation_cap_holder,
            suilend_reserve_array_index,
            suilend_price_info,
            ctx
        );
        share_coin
    }

    public fun withdraw<P, T>(
        clock: &Clock,
        amount: u64,
        navi_pool: &mut Pool<T>,
        navi_asset: u8,
        navi_storage: &mut Storage,
        navi_account_cap_holder: &AccountCapHolder,
        navi_inc_v1: &mut IncentiveV1,
        navi_inc_v2: &mut Incentive,
        suilend_reserve_array_index: u64,
        suilend_obligation_cap_holder: &ObligationOwnerCapHolder<P>,
        suilend_lending_market: &mut LendingMarket<P>,
        suilend_price_info: &PriceInfoObject,
        navi_oracle: &PriceOracle,
        ctx: &mut TxContext
    ): Coin<T> {
        let navi_balance = lendit::navi::navi_balance(
            &navi_account_cap_holder.account_cap,
            navi_pool,
            navi_asset,
            navi_storage
        );

        if (navi_balance > 0) {
            let withdraw_amount = if (amount == 0) { navi_balance } else { amount };
            if (withdraw_amount > navi_balance) {
                abort E_INSUFFICIENT_LIQUIDITY
            };
            let navi_withdrawn = lendit::navi::navi_withdraw<T>(
                clock,
                navi_oracle,
                navi_storage,
                navi_pool,
                navi_asset,
                withdraw_amount,
                navi_inc_v1,
                navi_inc_v2,
                &navi_account_cap_holder.account_cap,
                ctx
            );
            return navi_withdrawn
        } else {
            let suilend_balance = lendit::suilend::suilend_balance<P, T>(
                suilend_lending_market,
                suilend_reserve_array_index,
                &suilend_obligation_cap_holder.obligation
            );
            if (suilend_balance > 0) {
                let withdraw_amount = if (amount == 0) { suilend_balance } else { amount };
                if (withdraw_amount > suilend_balance) {
                    abort E_INSUFFICIENT_LIQUIDITY
                };
                let conv_amount = lendit::suilend::conv_to_ctoken<P, T>(
                    suilend_lending_market,
                    withdraw_amount
                );
                let suilend_withdrawn = lendit::suilend::suilend_withdraw<P, T>(
                    suilend_lending_market,
                    suilend_reserve_array_index,
                    clock,
                    std::option::none<RateLimiterExemption<P, T>>(),
                    conv_amount,
                    &suilend_obligation_cap_holder.obligation,
                    suilend_price_info,
                    ctx
                );
                return suilend_withdrawn
            } else {
                return coin::zero<T>(ctx)
            }
        }
    }

    public fun redeem<P, T>(
        clock: &Clock,
        share_coin: Coin<LENDIT>,
        treasury_cap_holder: &mut TreasuryCapHolder<LENDIT>,
        reserve: &mut Reserve<T>,
        navi_pool: &mut Pool<T>,
        navi_storage: &mut Storage,
        navi_asset: u8,
        navi_account_cap_holder: &AccountCapHolder,
        navi_inc_v1: &mut IncentiveV1,
        navi_inc_v2: &mut Incentive,
        navi_oracle: &PriceOracle,
        suilend_lending_market: &mut LendingMarket<P>,
        suilend_obligation_cap_holder: &ObligationOwnerCapHolder<P>,
        suilend_reserve_array_index: u64,
        suilend_price_info: &PriceInfoObject,
        ctx: &mut TxContext
    ): Coin<T> {
        let shares = coin::value(&share_coin);
        coin::burn(&mut treasury_cap_holder.treasury, share_coin);
        let total_assets = current_balance(
            reserve,
            navi_pool,
            navi_storage,
            navi_asset,
            navi_account_cap_holder,
            suilend_lending_market,
            suilend_reserve_array_index,
            suilend_obligation_cap_holder
        );
        let amount_to_withdraw = convert_to_assets(treasury_cap_holder, shares, total_assets);
        if (amount_to_withdraw == 0) {
            abort E_ZERO_AMOUNT
        };
        let withdrawn_assets = withdraw(
            clock,
            amount_to_withdraw,
            navi_pool,
            navi_asset,
            navi_storage,
            navi_account_cap_holder,
            navi_inc_v1,
            navi_inc_v2,
            suilend_reserve_array_index,
            suilend_obligation_cap_holder,
            suilend_lending_market,
            suilend_price_info,
            navi_oracle,
            ctx
        );
        optimise(
            clock,
            reserve,
            navi_pool,
            navi_storage,
            navi_asset,
            navi_account_cap_holder,
            navi_inc_v1,
            navi_inc_v2,
            navi_oracle,
            suilend_lending_market,
            suilend_obligation_cap_holder,
            suilend_reserve_array_index,
            suilend_price_info,
            ctx
        );
        withdrawn_assets
    }

}
