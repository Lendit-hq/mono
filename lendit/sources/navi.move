module lendit::navi{

    use sui::coin::{Self, Coin};
    use sui::clock::{Clock};

    use lending_core::logic;
    use lending_core::calculator;
    use lending_core::pool::{Pool};
    use oracle::oracle::{PriceOracle};
    use lending_core::storage::{Storage};
    use lending_core::account::{AccountCap};
    use lending_core::incentive_v2::{Incentive};
    use lending_core::incentive::{Incentive as IncentiveV1};

    public(package) fun navi_deposit<T> (
        clock: &Clock,
        storage: &mut Storage,
        pool: &mut Pool<T>,
        asset: u8,
        account_cap: &AccountCap,
        deposit_coin: Coin<T>,
        inc_v1: &mut IncentiveV1,
        inc_v2: &mut Incentive,
    ) {
        lending_core::incentive_v2::deposit_with_account_cap(clock, storage, pool, asset, deposit_coin, inc_v1, inc_v2, account_cap);
    }

    public(package) fun navi_withdraw<T> (
        clock: &Clock,
        oracle: &PriceOracle,
        storage: &mut Storage,
        pool: &mut Pool<T>,
        asset: u8,
        amount: u64,
        inc_v1: &mut IncentiveV1,
        inc_v2: &mut Incentive,
        account_cap: &AccountCap,
        ctx: &mut TxContext
    ): Coin<T> {
        let withdrawn_balance = lending_core::incentive_v2::withdraw_with_account_cap(clock, oracle, storage, pool, asset, amount, inc_v1, inc_v2, account_cap);
        coin::from_balance(withdrawn_balance, ctx)
    }

    public(package) fun navi_balance<T>(account_cap: &AccountCap, pool: &Pool<T>, asset: u8, storage: &mut Storage): u64 {
        let deposited_balance = logic::user_collateral_balance(storage, asset, account_cap.account_owner());
        pool.unnormal_amount(deposited_balance as u64)
    }

    public(package) fun navi_apr(storage: &mut Storage, asset: u8): u256 {
        let borrow_rate = calculator::calculate_borrow_rate(storage, asset);
        let supply_rate = calculator::calculate_supply_rate(storage, asset, borrow_rate);
        let scaled_supply_rate = supply_rate / 1_000_000_000; 
        scaled_supply_rate
    }

}