// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

import "./IBooster.sol";
import "./ILiqLocker.sol";
import "./IBaseRewardPool.sol";
import "./IRewardPool4626.sol";
import "./ILitDepositorHelper.sol";
import "./BalancerV2.sol";

// Note Oracle 0x9d43ccb1aD7E0081cC8A8F1fd54D16E54A637E30
interface IOracle {
    /**
     * @notice Computes the current strike price of the option
     * @return price The strike price in terms of the payment token, scaled by 18 decimals.
     * For example, if the payment token is $2 and the strike price is $4, the return value
     * would be 2e18.
     */
    function getPrice() external view returns (uint256 price);
}

// Note oLIT 0x627fee87d0D9D2c55098A06ac805Db8F98B158Aa
interface IOLit {
    /**
     * @notice Exercises options tokens to purchase the underlying tokens.
     * @dev The options tokens are not burnt but sent to address(0) to avoid messing up the
     * inflation schedule.
     * The oracle may revert if it cannot give a secure result.
     * @param amount The amount of options tokens to exercise
     * @param maxPaymentAmount The maximum acceptable amount to pay. Used for slippage protection.
     * @param recipient The recipient of the purchased underlying tokens
     * @param deadline The Unix timestamp (in seconds) after which the call will revert
     * @return paymentAmount The amount paid to the treasury to purchase the underlying tokens
     */
    function exercise(
        uint256 amount,
        uint256 maxPaymentAmount,
        address recipient,
        uint256 deadline
    ) external returns (uint256 paymentAmount);
}

interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @notice Allows smart contracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     * 0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);
}

/**
 * @title   FlashOptionsExerciser
 * @author  LiquisFinance
 * @notice  Allows for claiming oLIT from RewardPools, exercise it and lock LIT received.
 * @dev     Implements AaveFlashloan in order to facilitate the conversion in one step.
 */
contract FlashOptionsExerciser is IFlashLoanSimpleReceiver {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public owner;
    address public immutable operator;
    address public immutable liqLit;
    address public immutable litDepositorHelper;
    address public immutable lockerRewards;
    address public immutable liqLocker;

    address public immutable balVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public immutable lit = 0xfd0205066521550D7d7AB19DA8F72bb004b4C341;
    address public immutable olit = 0x627fee87d0D9D2c55098A06ac805Db8F98B158Aa;
    address public immutable olitOracle = 0x9d43ccb1aD7E0081cC8A8F1fd54D16E54A637E30;
    address public immutable weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    uint16 internal referralCode; // Aave referral code

    uint256 public constant basisOne = 10000;
    bytes32 internal constant balancerPoolId = 0x9232a548dd9e81bac65500b5e0d918f8ba93675c000200000000000000000423;

    struct LocalVariablesFlashLoan {
        uint256 olitAmount;
        uint256 amountToRepay;
        uint256 price;
        uint256 amountIn;
        uint256 maxAmountIn;
        uint256 amountNeeded;
        uint256 wethBal;
        uint256 maxGrossSlippage;
    }

    event OwnerUpdated(address newOwner);
    event SetReferralCode(uint16 referralCode);

    /**
     * @param _liqLit ERC20 token minted when locking LIT to veLIT in VoterProxy through crvDepositor.
     * @param _operator Booster main deposit contract; keeps track of pool info & user deposits; distributes rewards.
     * @param _litDepositorHelper Converts LIT -> balBPT and then wraps to liqLIT via the crvDepositor.
     * @param _lockerRewards BaseRewardPool where staking token is liqLIT
     * @param _liqLocker LiqLocker contract address
     */
    constructor(
        address _liqLit,
        address _operator,
        address _litDepositorHelper,
        address _lockerRewards,
        address _liqLocker
    ) {
        liqLit = _liqLit;
        operator = _operator;
        litDepositorHelper = _litDepositorHelper;
        lockerRewards = _lockerRewards;
        liqLocker = _liqLocker;

        owner = msg.sender;

        IERC20(weth).safeApprove(olit, type(uint256).max);
        IERC20(lit).safeApprove(balVault, type(uint256).max);

        IERC20(lit).safeApprove(litDepositorHelper, type(uint256).max);

        emit OwnerUpdated(msg.sender);
    }

    /**
     * @notice Update the contract owner
     * @param _owner the new owner
     * @dev Owner is responsible for setting initial config and updating operational params
     */
    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;

        emit OwnerUpdated(_owner);
    }

    /**
     * @notice User converts their olit into liqLit, sends it back to the user or stakes it in liqLit staking
     * @param _amount The amount of oLIT to exercise and lock
     * @param _stake Stake liqLit into the liqLit staking rewards pool
     * @param _minExchangeRate The minimal accepted oLIT to BAL-20WETH-80LIT exchange rate
     * @return claimed The amount of BAL-20WETH-80LIT claimed and locked
     */
    function exerciseAndLock(
        uint256 _amount,
        bool _stake,
        uint256 _minExchangeRate
    ) external returns (uint256 claimed) {
        IERC20(olit).safeTransferFrom(msg.sender, address(this), _amount);

        // convert oLIT to LIT by exercising the option
        _exerciseOptions(_amount);

        // convert lit to liqLit, send it to sender or stake it in liqLit staking
        claimed = _convertLitToLiqLit(_amount, _minExchangeRate, _stake);
    }

    /**
     * @notice User claims their olit from different pools, converts into lit and sends it back to the user
     * @param _pids Booster pools ids array to claim rewards from
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     * @param _minExchangeRate The minimal accepted oLIT to BAL-20WETH-80LIT exchange rate
     * @return claimed The amount of LIT claimed and sent to caller
     */
    function claimAndExercise(
        uint256[] memory _pids,
        bool _locker,
        bool _liqLocker,
        uint256 _minExchangeRate
    ) external returns (uint256 claimed) {
        uint256 olitAmount = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            // claim all the rewards, only olit is sent here, the rest directly to sender
            olitAmount += IBaseRewardPool(pool.crvRewards).getRewardFor(msg.sender, true);
        }

        if (_locker) {
            olitAmount += IBaseRewardPool(lockerRewards).getRewardFor(msg.sender, true);
        }

        if (_liqLocker) {
            olitAmount += ILiqLocker(liqLocker).getRewardFor(msg.sender);
        }

        // convert oLIT to LIT by exercising the option
        _exerciseOptions(olitAmount);

        // send lit to sender
        claimed = _transferLitToSender(olitAmount, _minExchangeRate);
    }

    /**
     * @notice User claims their olit from pool, converts into liqLit and sends it back to the user
     * @param _pids Booster pools ids array to claim rewards from
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     * @param _stake Stake liqLit into the liqLit staking rewards pool
     * @param _minExchangeRate The minimal accepted oLIT to BAL-20WETH-80LIT exchange rate
     * @return claimed The amount of BAL-20WETH-80LIT rewards claimed and locked
     */
    function claimAndLock(
        uint256[] memory _pids,
        bool _locker,
        bool _liqLocker,
        bool _stake,
        uint256 _minExchangeRate
    ) external returns (uint256 claimed) {
        uint256 olitAmount = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            // claim all the rewards, only olit is sent here, the rest directly to sender
            olitAmount += IBaseRewardPool(pool.crvRewards).getRewardFor(msg.sender, true);
        }

        if (_locker) {
            olitAmount += IBaseRewardPool(lockerRewards).getRewardFor(msg.sender, true);
        }

        if (_liqLocker) {
            olitAmount += ILiqLocker(liqLocker).getRewardFor(msg.sender);
        }

        // convert oLIT to LIT by exercising the option
        _exerciseOptions(olitAmount);

        // convert lit to liqLit, send it to sender or stake it in liqLit staking
        claimed = _convertLitToLiqLit(olitAmount, _minExchangeRate, _stake);
    }

    /**
     * @notice Withdraw Bunni LpTokens, claim oLIT, convert into liqLit and sends it back to the user
     * @param _pids Booster pools ids array to claim rewards from
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     * @param _stake Stake liqLit into the liqLit staking rewards pool
     * @param _minExchangeRate The minimal accepted oLIT to BAL-20WETH-80LIT exchange rate
     * @return claimed The amount of BAL-20WETH-80LIT rewards claimed and locked
     * @dev owner needs to first approve this contract as spender on the rewards pool
     */
    function withdrawAndLock(
        uint256[] memory _pids,
        uint256[] memory _amounts,
        bool _locker,
        bool _liqLocker,
        bool _stake,
        uint256 _minExchangeRate
    ) external returns (uint256 claimed) {
        require(_pids.length == _amounts.length, "array length missmatch");

        uint256 olitAmount = 0;
        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            // sender will receive the Bunni LpTokens, already unwrapped
            IRewardPool4626(pool.crvRewards).withdraw(_amounts[i], msg.sender, msg.sender);
            // claim all the rewards, only oLIT is sent here, the rest directly to sender
            olitAmount += IBaseRewardPool(pool.crvRewards).getRewardFor(msg.sender, true);
        }

        if (_locker) {
            olitAmount += IBaseRewardPool(lockerRewards).getRewardFor(msg.sender, true);
        }

        if (_liqLocker) {
            olitAmount += ILiqLocker(liqLocker).getRewardFor(msg.sender);
        }

        // convert oLIT to LIT by exercising the option
        _exerciseOptions(olitAmount);

        // convert lit to liqLit, send it to sender or stake it in liqLit staking
        claimed = _convertLitToLiqLit(olitAmount, _minExchangeRate, _stake);
    }

    /**
     * @notice User claims their olit from pool, converts into liqLit and sends it back to the user
     * @param account The account for which to query earned rewards
     * @param _pids Booster pools ids array to claim rewards from
     * @param _locker Boolean that indicates if the user is staking in lockerRewards (BaseRewardPool)
     * @param _liqLocker Boolean that indicates if the user is locking Liq in LiqLocker
     * @return earned_ The amount of oLIT earned
     * @dev Can be used to compute _minExchangeRate among other things
     */
    function earned(
        address account,
        uint256[] memory _pids,
        bool _locker,
        bool _liqLocker
    ) external view returns (uint256 earned_) {
        for (uint256 i = 0; i < _pids.length; i++) {
            IBooster.PoolInfo memory pool = IBooster(operator).poolInfo(_pids[i]);
            earned_ += IBaseRewardPool(pool.crvRewards).earned(account);
        }

        if (_locker) {
            earned_ += IBaseRewardPool(lockerRewards).earned(account);
        }

        if (_liqLocker) {
            earned_ += ILiqLocker(liqLocker).earned(account, olit);
        }
    }

    function _transferLitToSender(uint256 _olitAmount, uint256 _minExchangeRate) internal returns (uint256 litOut) {
        uint256 minOut = (_minExchangeRate * _olitAmount) / 1e18;
        litOut = IERC20(lit).balanceOf(address(this));
        require(litOut >= minOut, "slipped");
        if (litOut > 0) {
            IERC20(lit).safeTransfer(msg.sender, litOut);
        }
    }

    function _convertLitToLiqLit(
        uint256 _olitAmount,
        uint256 _minExchangeRate,
        bool _stake
    ) internal returns (uint256 bptOut) {
        uint256 minOut = (_minExchangeRate * _olitAmount) / 1e18;
        uint256 claimed = IERC20(lit).balanceOf(address(this));

        if (claimed > 0) {
            bptOut = _stake == true
                ? ILitDepositorHelper(litDepositorHelper).depositFor(
                    msg.sender,
                    claimed,
                    minOut,
                    true,
                    lockerRewards,
                    lit
                )
                : ILitDepositorHelper(litDepositorHelper).depositFor(
                    msg.sender,
                    claimed,
                    minOut,
                    true,
                    address(0),
                    lit
                );
        } // otherwise bptBalance = 0
    }

    function _balancerSwap(
        uint256 _amountOutDesired,
        uint256 _maxAmountIn,
        IAsset _assetIn,
        IAsset _assetOut
    ) internal returns (uint256 tokensIn) {
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            balancerPoolId,
            IBalancerVault.SwapKind.GIVEN_OUT,
            _assetIn,
            _assetOut,
            _amountOutDesired, // amount of assetOut desired from the trade
            abi.encode(0)
        );

        tokensIn = IBalancerVault(balVault).swap(
            singleSwap,
            IBalancerVault.FundManagement(address(this), false, payable(address(this)), false),
            _maxAmountIn, // limit amountIn we are willing to swap
            block.timestamp
        );
    }

    function _exerciseOptions(uint256 _olitAmount) internal {
        if (_olitAmount == 0) return;

        // amount of weth needed to process the olit, rounded up
        uint256 amount = (_olitAmount * IOracle(olitOracle).getPrice()) / 1e18 + 1;

        // encode _olitAmount to avoid an extra balanceOf call in next function
        bytes memory userData = abi.encode(_olitAmount);

        IPool(aavePool).flashLoanSimple(address(this), weth, amount, userData, referralCode);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == aavePool, "untrusted lender");
        require(initiator == address(this), "untrusted initiator");

        LocalVariablesFlashLoan memory vars;

        vars.olitAmount = abi.decode(params, (uint256));

        // exercise oLit option burns olitAmount of oLIT and mints olitAmount of LIT
        IOLit(olit).exercise(vars.olitAmount, amount, address(this), block.timestamp);

        // currently flashloan fee = 5, but that could vary
        vars.amountToRepay = amount.add(premium);

        vars.wethBal = IERC20(weth).balanceOf(address(this));
        if (vars.wethBal < vars.amountToRepay) {
            vars.amountNeeded = vars.amountToRepay.sub(vars.wethBal);

            // it is fine to max by balance because we control for slippage with _minExchangeRate
            vars.maxAmountIn = vars.olitAmount;

            // swap the necessary lit into weth, swap must start with a non-zero amount in
            _balancerSwap(vars.amountNeeded, vars.maxAmountIn, IAsset(lit), IAsset(weth));
        }

        // repay the flashloan, aavePool will pull the tokens from the contract
        IERC20(asset).safeIncreaseAllowance(aavePool, vars.amountToRepay);

        return true;
    }

    /**
     * @param _referralCode The referral code for Aave Protocol.
     */
    function setReferralCode(uint16 _referralCode) external {
        require(msg.sender == owner, "!auth");
        referralCode = _referralCode;
        emit SetReferralCode(_referralCode);
    }
}
