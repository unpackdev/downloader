// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;

pragma experimental ABIEncoderV2;







contract MainnetCurveUsdAddresses {
    address internal constant CRVUSD_CONTROLLER_FACTORY_ADDR = 0xC9332fdCB1C491Dcc683bAe86Fe3cb70360738BC;
    address internal constant CRVUSD_TOKEN_ADDR = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    address internal constant CURVE_ADDRESS_PROVIDER = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    address internal constant CURVE_ROUTER_NG = 0xF0d4c12A5768D806021F80a262B4d39d26C58b8D;
}




contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}




interface IAddressProvider {
    function admin() external view returns (address);
    function get_registry() external view returns (address);
    function get_address(uint256 _id) external view returns (address);
}





interface ICrvUsdController {
    function create_loan(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands) external payable;
    function create_loan_extended(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands, address _callbacker, uint256[] memory _callbackArgs) external payable;

    /// @dev all functions below: if _collateralAmount is 0 will just return
    function add_collateral(uint256 _collateralAmount) external payable;
    function add_collateral(uint256 _collateralAmount, address _for) external payable;

    function remove_collateral(uint256 _collateralAmount) external;
    /// @param _useEth relevant only for ETH collateral pools (currently not deployed)
    function remove_collateral(uint256 _collateralAmount, bool _useEth) external;

    /// @dev all functions below: if _debtAmount is 0 will just return
    function borrow_more(uint256 _collateralAmount, uint256 _debtAmount) external payable;

    /// @dev if _debtAmount > debt will do full repay
    function repay(uint256 _debtAmount) external payable;
    function repay(uint256 _debtAmount, address _for) external payable;
    /// @param _maxActiveBand Don't allow active band to be higher than this (to prevent front-running the repay)
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand) external payable;
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand, bool _useEth) external payable;
    function repay_extended(address _callbacker, uint256[] memory _callbackArgs) external;

    function liquidate(address user, uint256 min_x) external;
    function liquidate(address user, uint256 min_x, bool _useEth) external;
    function liquidate_extended(address user, uint256 min_x, uint256 frac, bool use_eth, address callbacker, uint256[] memory _callbackArgs) external;


    /// GETTERS
    function amm() external view returns (address);
    function monetary_policy() external view returns (address);
    function collateral_token() external view returns (address);
    function debt(address) external view returns (uint256);
    function total_debt() external view returns (uint256);
    function health_calculator(address, int256, int256, bool, uint256) external view returns (int256);
    function health_calculator(address, int256, int256, bool) external view returns (int256);
    function health(address) external view returns (int256);
    function health(address, bool) external view returns (int256);
    function max_borrowable(uint256 collateralAmount, uint256 nBands) external view returns (uint256);
    function min_collateral(uint256 debtAmount, uint256 nBands) external view returns (uint256);
    function calculate_debt_n1(uint256, uint256, uint256) external view returns (int256);
    function minted() external view returns (uint256);
    function redeemed() external view returns (uint256);
    function amm_price() external view returns (uint256);
    function user_state(address) external view returns (uint256[4] memory);
    function user_prices(address) external view returns (uint256[2] memory);
    function loan_exists(address) external view returns (bool);
    function liquidation_discount() external view returns (uint256);
}

interface ICrvUsdControllerFactory {
    function get_controller(address) external view returns (address); 
    function debt_ceiling(address) external view returns (uint256);
}

interface ILLAMMA {
    function active_band_with_skip() external view returns (int256);
    function get_sum_xy(address) external view returns (uint256[2] memory);
    function get_xy(address) external view returns (uint256[][2] memory);
    function get_p() external view returns (uint256);
    function read_user_tick_numbers(address) external view returns (int256[2] memory);
    function p_oracle_up(int256) external view returns (uint256);
    function p_oracle_down(int256) external view returns (uint256);
    function p_current_up(int256) external view returns (uint256);
    function p_current_down(int256) external view returns (uint256);
    function bands_x(int256) external view returns (uint256);
    function bands_y(int256) external view returns (uint256);
    function get_base_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function active_band() external view returns (int256);
    function A() external view returns (uint256);
    function min_band() external view returns (int256);
    function max_band() external view returns (int256);
    function rate() external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 in_amount, uint256 min_amount) external returns (uint256[2] memory);
    function coins(uint256 i) external view returns (address);
    function user_state(address _user) external view returns (uint256[4] memory);
}

interface IAGG {
    function rate() external view returns (uint256);
    function rate0() external view returns (uint256);
    function target_debt_fraction() external view returns (uint256);
    function sigma() external view returns (int256);
    function peg_keepers(uint256) external view returns (address); 
}

interface IPegKeeper {
    function debt() external view returns (uint256);
}

interface ICurveUsdSwapper {
    function encodeSwapParams(uint256[5][5] memory swapParams,  uint32 gasUsed, uint24 dfsFeeDivider) external pure returns (uint256 encoded);
    function setAdditionalRoutes(address[8] memory _additionalRoutes, address[5] memory _swapZapPools) external;
}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





abstract contract IWETH {
    function allowance(address, address) public virtual view returns (uint256);

    function balanceOf(address) public virtual view returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}






library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "Eth send fail");
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}








contract CurveUsdHelper is MainnetCurveUsdAddresses, DSMath {
    using TokenUtils for address;

    error CurveUsdInvalidController();

    bytes4 constant CURVE_SWAPPER_ID = bytes4(keccak256("CurveUsdSwapper"));

    function getCollateralRatio(address _user, address _controllerAddr) public view returns (uint256 collRatio, bool isInSoftLiquidation) {
        // fetch users debt
        uint256 debt = ICrvUsdController(_controllerAddr).debt(_user);
        // no position can exist without debt
        if (debt == 0) return (0, false);
        (uint256 crvUsdCollAmount, uint256 collAmount) = getCollAmountsFromAMM(_controllerAddr, _user);
        // if user has crvusd as coll he is currently underwater
        if (crvUsdCollAmount > 0) isInSoftLiquidation = true;

        // fetch collToken oracle price
        address amm = ICrvUsdController(_controllerAddr).amm();
        uint256 oraclePrice = ILLAMMA(amm).price_oracle();
        // calculate collAmount as WAD (18 decimals)
        address collToken = ICrvUsdController(_controllerAddr).collateral_token();
        uint256 assetDec = IERC20(collToken).decimals();
        uint256 collAmountWAD = assetDec > 18 ? (collAmount / 10 ** (assetDec - 18)) : (collAmount * 10 ** (18 - assetDec));
        
        collRatio = wdiv(wmul(collAmountWAD, oraclePrice) + crvUsdCollAmount, debt);
    }

    function isControllerValid(address _controllerAddr) public view returns (bool) {
        return
            ICrvUsdControllerFactory(CRVUSD_CONTROLLER_FACTORY_ADDR).debt_ceiling(
                _controllerAddr
            ) != 0;
    }

    function userMaxWithdraw(
        address _controllerAddress,
        address _user
    ) public view returns (uint256 maxWithdraw) {
        uint256[4] memory userState = ICrvUsdController(_controllerAddress).user_state(_user);
        return
            userState[0] -
            ICrvUsdController(_controllerAddress).min_collateral(userState[2], userState[3]);
    }

    function getCollAmountsFromAMM(
        address _controllerAddress,
        address _user
    ) public view returns (uint256 crvUsdAmount, uint256 collAmount) {
        address llammaAddress = ICrvUsdController(_controllerAddress).amm();
        uint256[2] memory xy = ILLAMMA(llammaAddress).get_sum_xy(_user);
        crvUsdAmount = xy[0];
        collAmount = xy[1];
    }

    function _sendLeftoverFunds(address _controllerAddress, address _to) internal {
        address collToken = ICrvUsdController(_controllerAddress).collateral_token();

        CRVUSD_TOKEN_ADDR.withdrawTokens(_to, type(uint256).max);
        collToken.withdrawTokens(_to, type(uint256).max);
    }

    /// @dev Helper method for advanced actions to setup the curve path and write to transient storage in CurveUsdSwapper
    function _setupCurvePath(
        address _curveUsdSwapper,
        bytes memory _additionalData,
        uint256 _swapAmount,
        uint256 _minSwapAmount,
        uint32 _gasUsed,
        uint24 _dfsFeeDivider
    ) internal returns (uint256[] memory swapData) {
        (address[11] memory _route, uint256[5][5] memory _swap_params, address[5] memory _pools) = abi.decode(
            _additionalData,
            (address[11], uint256[5][5], address[5])
        );

        swapData = new uint256[](5);
        swapData[0] = _swapAmount;
        swapData[1] = _minSwapAmount;
        swapData[2] = ICurveUsdSwapper(_curveUsdSwapper).encodeSwapParams(_swap_params, _gasUsed, _dfsFeeDivider);
        swapData[3] = uint256(uint160(_route[1]));
        swapData[4] = uint256(uint160(_route[2]));

        address[8] memory _path = [
            _route[3],
            _route[4],
            _route[5],
            _route[6],
            _route[7],
            _route[8],
            _route[9],
            _route[10]
        ];

        ICurveUsdSwapper(_curveUsdSwapper).setAdditionalRoutes(_path, _pools);
    }
}







contract CurveUsdView is CurveUsdHelper {
  struct Band {
    int256 id;
    uint256 lowPrice;
    uint256 highPrice;
    uint256 collAmount;
    uint256 debtAmount;
  }

  struct CreateLoanData {
    int256 health;
    uint256 minColl;
    uint256 maxBorrow;
    Band[] bands;
  }

  struct GlobalData {
    address collateral;
    uint256 decimals;
    int256 activeBand;
    uint256 A;
    uint256 totalDebt;
    uint256 ammPrice;
    uint256 basePrice;
    uint256 oraclePrice;
    uint256 minted;
    uint256 redeemed;
    uint256 monetaryPolicyRate;
    uint256 ammRate;
    int256 minBand;
    int256 maxBand;
  }

  struct UserData {
    bool loanExists;
    uint256 collateralPrice;
    uint256 marketCollateralAmount;
    uint256 curveUsdCollateralAmount;
    uint256 debtAmount;
    uint256 N;
    uint256 priceLow;
    uint256 priceHigh;
    uint256 liquidationDiscount;
    int256 health;
    int256[2] bandRange;
    uint256[][2] usersBands;
    uint256 collRatio;
    bool isInSoftLiquidation;
  }

  address public constant WBTC_MARKET = 0x4e59541306910aD6dC1daC0AC9dFB29bD9F15c67;
  address public constant WBTC_HEALTH_ZAP = 0xCF61Ee62b136e3553fB545bd8fEc11fb7f830d6A;

  function userData(address market, address user) external view returns (UserData memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA amm = ILLAMMA(ctrl.amm());

      if (!ctrl.loan_exists(user)) {
        int256[2] memory bandRange = [int256(0), int256(0)];
        uint256[][2] memory usersBands;

        return UserData({
          loanExists: false,
          collateralPrice: 0,
          marketCollateralAmount: 0,
          curveUsdCollateralAmount: 0,
          debtAmount: 0,
          N: 0,
          priceLow: 0,
          priceHigh: 0,
          liquidationDiscount: 0,
          health: 0,
          bandRange: bandRange,
          usersBands: usersBands,
          collRatio: 0,
          isInSoftLiquidation: false
        });
      }

      uint256[4] memory amounts = ctrl.user_state(user);
      uint256[2] memory prices = ctrl.user_prices(user);
      (uint256 collRatio, bool isInSoftLiquidation) = getCollateralRatio(user, market);

      return UserData({
        loanExists: ctrl.loan_exists(user),
        collateralPrice: amm.price_oracle(),
        marketCollateralAmount: amounts[0],
        curveUsdCollateralAmount: amounts[1],
        debtAmount: amounts[2],
        N: amounts[3],
        priceLow: prices[1],
        priceHigh: prices[0],
        liquidationDiscount: ctrl.liquidation_discount(),
        health: ctrl.health(user, true),
        bandRange: amm.read_user_tick_numbers(user),
        usersBands: amm.get_xy(user),
        collRatio: collRatio,
        isInSoftLiquidation: isInSoftLiquidation
      });
  }

  function globalData(address market) external view returns (GlobalData memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      IAGG agg = IAGG(ctrl.monetary_policy());
      ILLAMMA amm = ILLAMMA(ctrl.amm());
      address collTokenAddr = ctrl.collateral_token();

      return GlobalData({
        collateral: collTokenAddr,
        decimals: IERC20(collTokenAddr).decimals(),
        activeBand: amm.active_band(),
        A: amm.A(),
        totalDebt: ctrl.total_debt(),
        ammPrice: ctrl.amm_price(),
        basePrice: amm.get_base_price(),
        oraclePrice: amm.price_oracle(),
        minted: ctrl.minted(),
        redeemed: ctrl.redeemed(),
        monetaryPolicyRate: agg.rate(),
        ammRate: amm.rate(),
        minBand: amm.min_band(),
        maxBand: amm.max_band()
    });
  }

  function getBandData(address market, int256 n) external view returns (Band memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());

      return Band(n, lama.p_oracle_down(n), lama.p_oracle_up(n), lama.bands_y(n), lama.bands_x(n));
  }
  
  function getBandsData(address market, int256 from, int256 to) public view returns (Band[] memory) {
      ICrvUsdController ctrl = ICrvUsdController(market);
      ILLAMMA lama = ILLAMMA(ctrl.amm());
      Band[] memory bands = new Band[](uint256(to-from+1));
      for (int256 i = from; i <= to; i++) {
          bands[uint256(i-from)] = Band(i, lama.p_oracle_down(i), lama.p_oracle_up(i), lama.bands_y(i), lama.bands_x(i));
      }

      return bands;
  }

  function createLoanData(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (CreateLoanData memory) {
    ICrvUsdController ctrl = ICrvUsdController(market);

    uint256 collForHealthCalc = collateral;

    int health = healthCalculator(market, address(0x00), int256(collForHealthCalc), int256(debt), true, N);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    Band[] memory bands = getBandsData(market, n1, n2);

    return CreateLoanData({
      health: health,
      minColl: ctrl.min_collateral(debt, N),
      maxBorrow: ctrl.max_borrowable(collateral, N),
      bands: bands
    });
  }

  function maxBorrow(address market, uint256 collateral, uint256 N) external view returns (uint256) {
    ICrvUsdController ctrl = ICrvUsdController(market);
    return ctrl.max_borrowable(collateral, N);
  }

  function minCollateral(address market, uint256 debt, uint256 N) external view returns (uint256) {
    ICrvUsdController ctrl = ICrvUsdController(market);
    return ctrl.min_collateral(debt, N);
  }

  function getBandsDataForPosition(address market, uint256 collateral, uint256 debt, uint256 N) external view returns (Band[] memory bands) {
    ICrvUsdController ctrl = ICrvUsdController(market);

    int256 n1 = ctrl.calculate_debt_n1(collateral, debt, N);
    int256 n2 = n1 + int256(N) - 1;

    bands = getBandsData(market, n1, n2);
  }

  function healthCalculator(address market, address user, int256 collChange, int256 debtChange, bool isFull, uint256 numBands) public view returns (int256 health) {
    ICrvUsdController ctrl = ICrvUsdController(market);

    // handle special health_calc if WBTC is collateral
    if (market == WBTC_MARKET) {
      ICrvUsdController healthZap = ICrvUsdController(WBTC_HEALTH_ZAP);
      health = healthZap.health_calculator(user, int256(collChange), int256(debtChange), isFull, numBands);
    } else {
      health =  ctrl.health_calculator(user, collChange, debtChange, isFull, numBands);
    }
  }
}
