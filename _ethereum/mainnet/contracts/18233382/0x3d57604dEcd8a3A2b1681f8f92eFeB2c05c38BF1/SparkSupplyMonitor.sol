/**
 *Submitted for verification at Etherscan.io on 2023-08-09
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IVaultInterface {
    function execute(
        address,
        bytes memory
    ) external payable returns (bytes memory);
}

interface ISparkPool {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getReserveData(
        address asset
    ) external view returns (ReserveData memory);
}

interface IsparkSavingsInterface {
    function pool() external view returns (address);

    function WETH() external view returns (address);
}

contract SparkSupplyMonitor {
    using SafeMath for uint256;
    address public owner;
    address public sparkPool;
    address public sparkSupplyStrategy;
    address public WETH;

    constructor(address _owner) {
        owner = _owner;
        sparkSupplyStrategy = 0x052a6469aD8C8C40D5218357fA9ED2C68Bd09fa8; //0x052a6469aD8C8C40D5218357fA9ED2C68Bd09fa8
        sparkPool = IsparkSavingsInterface(sparkSupplyStrategy).pool(); //spark 0xC13e21B648A5Ee794902342038FF3aDAB66BE987#
        WETH = IsparkSavingsInterface(sparkSupplyStrategy).WETH(); // weth:0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    }

    function setSparkSupplyStrategy(address _sparkSupplyStrategy) external {
        require(msg.sender == owner, " only owner set Spark Supply Strategy");
        sparkSupplyStrategy = _sparkSupplyStrategy;
    }

    function hasSupplyAllTokens(address _vault) public view returns (bool) {
        /*
        (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
        )
        */
        (uint256 totalCollateralBase, , , , , ) = ISparkPool(sparkPool)
            .getUserAccountData(_vault);
        if (totalCollateralBase > 0) {
            return true;
        }
        return false;
    }

    function getSparkPoolLiquidity(
        address _underlying
    ) public view returns (uint256) {
        uint256 _cash;
        address _aToken;
        ISparkPool.ReserveData memory reserveData;
        reserveData = ISparkPool(sparkPool).getReserveData(_underlying);
        _aToken = reserveData.aTokenAddress;
        _cash = IERC20(_underlying).balanceOf(_aToken);
        return _cash;
    }

    function isSparkCashLiquidityInsufficient(
        address _underlying,
        uint256 _cashAmountThreshold
    ) public view returns (bool) {
        uint256 _poolCash;
        _poolCash = getSparkPoolLiquidity(_underlying);
        if (_cashAmountThreshold >= _poolCash) {
            return true;
        }
        return false;
    }

    function encodeExitInput(
        address _underlying
    ) public pure returns (bytes memory encodedInput) {
        return abi.encodeWithSignature("exit(address)", _underlying);
    }

    function encodeExitETHInput()
        public
        pure
        returns (bytes memory encodedInput)
    {
        return abi.encodeWithSignature("exitETH()");
    }

    function executeExit(
        address _vault,
        address _underlying
    ) public view returns (bool canExec, bytes memory execPayload) {
        bytes memory args = encodeExitInput(_underlying);
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            sparkSupplyStrategy,
            args
        );
        return (true, execPayload);
    }

    function executeExitETH(
        address _vault
    ) public view returns (bool canExec, bytes memory execPayload) {
        bytes memory args = encodeExitETHInput();
        execPayload = abi.encodeWithSelector(
            IVaultInterface(_vault).execute.selector,
            sparkSupplyStrategy,
            args
        );
        return (true, execPayload);
    }

    function checker(
        address _vault,
        address _underlying,
        uint256 _cashThreshold
    ) external view returns (bool canExec, bytes memory execPayload) {
        if (hasSupplyAllTokens(_vault)) {
            if (isSparkCashLiquidityInsufficient(_underlying, _cashThreshold)) {
                if (_underlying == WETH) {
                    return executeExitETH(_vault);
                } else {
                    return executeExit(_vault, _underlying);
                }
            }
        }
        return (false, bytes("monitor is ok"));
    }
}