// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./JaxOwnable.sol";
import "./JaxProtection.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IPancakeRouter.sol";

contract JaxStakeAdmin is JaxOwnable, Initializable, JaxProtection {
    
    IERC20 public wjxn;
    IERC20 public usdt;

    JaxProtection jaxProtection;
    IPancakeRouter01 router;

    uint public min_unlocked_deposit_amount;
    uint public max_unlocked_deposit_amount;

    uint public min_locked_deposit_amount;
    uint public max_locked_deposit_amount;

    uint public collateral_ratio;

    uint public referral_ratio;

    uint public wjxn_default_discount_ratio;

    uint public minimum_wjxn_price; // 1e18

    uint[] public lock_plans;
    uint[] public apys;

    uint public max_unlocked_stake_amount;

    uint public max_locked_stake_amount;

    bool public is_deposit_freezed;

    address[] public referrers;
    mapping(uint => bool) public referrer_status;
    mapping(address => uint) public referrer_to_ids;

    event Set_Stake_APY(uint plan, uint amount);
    event Set_Collateral_Ratio(uint collateral_ratio);
    event Set_Minimum_Wjxn_Price(uint price);
    event Set_Referral_Ratio(uint ratio);
    event Set_Wjxn_Default_Discount_Ratio(uint ratio);
    event Set_Max_Unlocked_Stake_Amount(uint amount);
    event Set_Max_Locked_Stake_Amount(uint amount);
    event Set_Unlocked_Deposit_Amount_Limit(uint min_amount, uint max_amount);
    event Set_Locked_Deposit_Amount_Limit(uint min_amount, uint max_amount);
    event Freeze_Deposit(bool flag);
    event Add_Referrers(address[] referrers);
    event Delete_Referrers(uint[] referrer_ids);
    event Withdraw_By_Admin(address token, uint amount);

    modifier checkZeroAddress(address account) {
        require(account != address(0x0), "Only non-zero address");
        _;
    }

    function initialize(IERC20 _wjxn, IERC20 _usdt, IPancakeRouter01 _router) external initializer 
        checkZeroAddress(address(_wjxn)) checkZeroAddress(address(_usdt)) checkZeroAddress(address(_router))
    {
        wjxn = _wjxn;
        usdt = _usdt;

        router = _router;

        uint decimals = 10 ** usdt.decimals();

        min_unlocked_deposit_amount = 1 * decimals;  // 1 USDT
        max_unlocked_deposit_amount = 1000 * decimals; // 1K USDT

        min_locked_deposit_amount = 100 * decimals; // 100 USDT
        max_locked_deposit_amount = 1e6 * decimals; // 1M USDT

        collateral_ratio = 150; // 150%

        referral_ratio = 1.25 * 1e6; //1.25 % 8 decimals

        wjxn_default_discount_ratio = 10; // 10%

        minimum_wjxn_price = 1.5 * 1e18;

        lock_plans = [360 days, 90 days, 180 days, 270 days, 360 days];
        apys = [20, 24, 28, 32, 36];

        max_unlocked_stake_amount = 1e6 * decimals; //  1M USDT

        max_locked_stake_amount = 1e7 * decimals; // 10M USDT

        is_deposit_freezed = false;

        referrers.push(address(0));

        _transferOwnership(msg.sender);
    }

    function set_stake_apy(uint plan, uint apy) external onlyOwner runProtection {
        if(plan == 0) {
            require(apy >= 1 && apy <= 24, "Invalid apy");
        }
        else {
            require(apy >= 12 && apy <= 36, "Invalid apy");
        }
        apys[plan] = apy;
        emit Set_Stake_APY(plan, apy);
    }

    function set_collateral_ratio(uint _collateral_ratio) external onlyOwner runProtection {
        require(_collateral_ratio >= 100 && _collateral_ratio <= 200, "Collateral ratio should be 100% - 200%");
        collateral_ratio = _collateral_ratio;
        emit Set_Collateral_Ratio(_collateral_ratio);
    }

    function get_wjxn_price() public view returns(uint) {
        uint dex_price = _get_wjxn_dex_price();
        if(dex_price < minimum_wjxn_price)
            return minimum_wjxn_price;
        return dex_price;
    }

    function _get_wjxn_dex_price() internal view returns(uint) {
        address pairAddress = IPancakeFactory(router.factory()).getPair(address(wjxn), address(usdt));
        (uint res0, uint res1,) = IPancakePair(pairAddress).getReserves();
        res0 *= 10 ** (18 - IERC20(IPancakePair(pairAddress).token0()).decimals());
        res1 *= 10 ** (18 - IERC20(IPancakePair(pairAddress).token1()).decimals());
        if(IPancakePair(pairAddress).token0() == address(usdt)) {
            if(res1 > 0)
                return 1e18 * res0 / res1;
        } 
        else {
            if(res0 > 0)
                return 1e18 * res1 / res0;
        }
        return 0;
    }


    function set_minimum_wjxn_price(uint price) external onlyOwner runProtection {
        require(price >= 1.5 * 1e18, "Minimum wjxn price should be above 1.5 USD");
        minimum_wjxn_price = price;
        emit Set_Minimum_Wjxn_Price(price);
    }

    function set_wjxn_default_discount_ratio(uint ratio) external onlyOwner runProtection {
        require(ratio >= 10 && ratio <= 30, "Discount ratio should be 10% - 30%");
        wjxn_default_discount_ratio = ratio;
        emit Set_Wjxn_Default_Discount_Ratio(ratio);
    }

    function _add_referrer(address referrer) internal checkZeroAddress(referrer) {
        uint referrer_id = referrer_to_ids[referrer];
        if( referrer_id == 0) {
            referrer_id = referrers.length;
            referrers.push(referrer);
            referrer_to_ids[referrer] = referrer_id;
        }
        referrer_status[referrer_id] = true;
    }

    function add_referrers(address[] memory _referrers) external onlyOwner runProtection {
        uint i = 0;
        for(; i < _referrers.length; i += 1) {
            _add_referrer(_referrers[i]);
        }
        emit Add_Referrers(_referrers);
    }

    function delete_referrers(uint[] memory _referrer_ids) external onlyOwner runProtection {
        uint i = 0;
        for(; i < _referrer_ids.length; i += 1) {
            referrer_status[_referrer_ids[i]] = false;
        }
        emit Delete_Referrers(_referrer_ids);
    }

    function set_referral_ratio(uint ratio) external onlyOwner runProtection {
        require(ratio >= 0.25 * 1e6 && ratio <= 1.25 * 1e6, "Referral ratio should be 0.25% ~ 1.25%");
        referral_ratio = ratio;
        emit Set_Referral_Ratio(ratio);
    }

    function freeze_deposit(bool flag) external onlyOwner runProtection {
        is_deposit_freezed = flag;
        emit Freeze_Deposit(flag);
    }

    function set_unlocked_stake_amount_limit(uint max_amount) external onlyOwner runProtection {
        max_unlocked_stake_amount = max_amount;
        emit Set_Max_Unlocked_Stake_Amount(max_amount);
    }

    function set_locked_stake_amount_limit(uint max_amount) external onlyOwner runProtection {
        require(max_amount >= _usdt_decimals(1e6), "Max amount >= 1M USD");
        max_locked_stake_amount = max_amount;
        emit Set_Max_Locked_Stake_Amount(max_amount);
    }

    function set_unlocked_deposit_amount_limit(uint min_amount, uint max_amount) external onlyOwner runProtection {
        require(min_amount >= _usdt_decimals(1) && min_amount <= _usdt_decimals(100), "1 USD <= Min amount <= 100 USD");
        require(max_amount <= _usdt_decimals(1e4), "Max amount <= 10K USD");
        min_unlocked_deposit_amount = min_amount;
        max_unlocked_deposit_amount = max_amount;
        emit Set_Unlocked_Deposit_Amount_Limit(min_amount, max_amount);
    }

    function set_locked_deposit_amount_limit(uint min_amount, uint max_amount) external onlyOwner runProtection {
        require(min_amount >= _usdt_decimals(100), "Min amount >= 100 USD");
        require(max_amount >= _usdt_decimals(1e4), "Max amount >= 10K USD");
        min_locked_deposit_amount = min_amount;
        max_locked_deposit_amount = max_amount;
        emit Set_Locked_Deposit_Amount_Limit(min_amount, max_amount);
    }

    function _usdt_decimals(uint amount) internal view returns(uint) {
        return amount * (10 ** usdt.decimals());
    }
}