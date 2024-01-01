// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./IMstWrapper.sol";

import "./ILiquidity.sol";
import "./Pool.sol";
import "./Tick.sol";

import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC721.sol";

import "./SafeERC20.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./Multicall.sol";
import "./Strings.sol";

/**
 * @title MstWrapper
 * @author MetaStreet Labs
 */

contract MstWrapper is IMstWrapper, ERC20, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;
    using Tick for uint128;

    /*--------------------------------------------------------------------------*/
    /* Constants                                                                */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.1";

    /**
     * @notice Fixed point scale
     */
    uint256 internal constant FIXED_POINT_SCALE = 1e18;

    /**
     * @notice Capacity
     */
    uint256 internal immutable CAPACITY;

    /*--------------------------------------------------------------------------*/
    /* State                                                                    */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Initialized boolean
     */
    bool internal _initialized;

    /**
     * @notice MetaStreet V2 Pool
     */
    Pool internal _pool;

    /**
     * @notice Deposit tick
     */
    uint128 internal _tick;

    /**
     * @notice Currency token
     */
    IERC20 internal _currencyToken;

    /**
     * @notice Redemption mapping
     */
    mapping(uint128 => address) internal _pendingRedemptions;

    /*--------------------------------------------------------------------------*/
    /* Constructor                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice MstWrapper constructor
     */
    constructor(uint256 capacity_) ERC20("", "") {
        /* Disable initialization of implementation contract */
        _initialized = true;

        CAPACITY = capacity_;
    }

    /*--------------------------------------------------------------------------*/
    /* Initializer                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Initializer
     */
    function initialize(bytes memory params) external {
        require(!_initialized, "Already initialized");
        _initialized = true;

        /* Decode parameters */
        (address pool_, uint128 tick_) = abi.decode(params, (address, uint128));

        _pool = Pool(pool_);
        _tick = tick_;
        _currencyToken = IERC20(Pool(pool_).currencyToken());

        /* Approve pool to transfer currency token */
        _currencyToken.approve(pool_, type(uint256).max);
    }

    /*--------------------------------------------------------------------------*/
    /* Internal Helpers                                                         */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Internal helper to get node info
     *
     * @return Node value
     * @return Node shares
     */
    function _nodeInfo() internal view returns (uint128, uint128) {
        ILiquidity.NodeInfo memory node = ILiquidity(address(_pool)).liquidityNode(_tick);
        return (node.value, node.shares);
    }

    /**
     * @notice Helper function to get rounded loan limit for name() and symbol()
     *
     * @dev Solely utilized to generate rounded number in name() and symbol() getters.
     *      Loan limits > 1 ETH are rounded to the nearest whole number. Under 1 ETH
     *      are rounded to the nearest hundredth place.
     *
     * @return Loan limit as string
     */
    function _getLoanLimit(uint256 loanLimit_) internal pure returns (string memory) {
        /* Handle loan limits > 1 ETH */
        if (loanLimit_ >= FIXED_POINT_SCALE) {
            return Strings.toString((loanLimit_ + (FIXED_POINT_SCALE / 2)) / FIXED_POINT_SCALE);
        } else {
            /* Handle loan limits < 1 ETH */
            uint256 scaledValue = loanLimit_ * 100;
            uint256 integer = scaledValue / FIXED_POINT_SCALE;
            if (scaledValue % FIXED_POINT_SCALE >= FIXED_POINT_SCALE / 2) {
                integer += 1;
            }
            uint256 hundredthPlaces = integer % 100;
            string memory decimalStr = hundredthPlaces < 10
                ? string.concat("0", Strings.toString(hundredthPlaces))
                : Strings.toString(hundredthPlaces);

            return string.concat("0.", decimalStr);
        }
    }

    /*--------------------------------------------------------------------------*/
    /* Getters                                                                  */
    /*--------------------------------------------------------------------------*/

    /**
     *  @inheritdoc ERC20
     */
    function name() public view override returns (string memory) {
        (uint256 limit_,,,) = _tick.decode();

        return string.concat(
            "MetaStreet V2 Deposit: ",
            ERC721(_pool.collateralToken()).symbol(),
            "-",
            _getLoanLimit(limit_),
            ":",
            ERC20(_pool.currencyToken()).symbol()
        );
    }

    /**
     * @inheritdoc ERC20
     */
    function symbol() public view override returns (string memory) {
        (uint256 limit_,,,) = _tick.decode();
        return string.concat("mstETH-", ERC721(_pool.collateralToken()).symbol(), "-", _getLoanLimit(limit_));
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function pool() external view returns (Pool) {
        return _pool;
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function tick() external view returns (uint128) {
        return _tick;
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function limit() external view returns (uint128) {
        (uint256 limit_,,,) = _tick.decode();
        return uint128(limit_);
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function duration() external view returns (uint64) {
        (, uint256 durationIndex,,) = _tick.decode();
        return _pool.durations()[durationIndex];
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function rate() external view returns (uint64) {
        (,, uint256 rateIndex,) = _tick.decode();
        return _pool.rates()[rateIndex];
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function capacity() external view returns (uint256) {
        return CAPACITY;
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function withdrawalAvailable(uint128 redemptionId) external view returns (uint256, uint256, uint256) {
        return _pool.redemptionAvailable(address(this), _tick, redemptionId);
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function mstTokenToUnderlying(uint256 amount) external view returns (uint256) {
        /* Get node info */
        (uint128 nodeValue, uint128 nodeShares) = _nodeInfo();

        /* Reverts when node has zero value or zero shares */
        if (nodeValue == 0 || nodeShares == 0) revert InvalidNodeState();

        return Math.mulDiv(amount, nodeValue, nodeShares);
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function underlyingToMstToken(uint256 amount) external view returns (uint256) {
        /* Get node info */
        (uint128 nodeValue, uint128 nodeShares) = _nodeInfo();

        /* Uninitialized node returns amount as price is 1 */
        if (nodeValue == 0 && nodeShares == 0) return amount;

        /* Reverts when node has zero value or zero shares */
        if (nodeValue == 0 || nodeShares == 0) revert InvalidNodeState();

        return Math.mulDiv(amount, nodeShares, nodeValue);
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function depositSharePrice() external view returns (uint256) {
        /* Get node and accrual info */
        (ILiquidity.NodeInfo memory node, ILiquidity.AccrualInfo memory accrual) =
            ILiquidity(_pool).liquidityNodeWithAccrual(_tick);

        /* Simulate accrual */
        accrual.accrued += accrual.rate * uint128(block.timestamp - accrual.timestamp);

        /* Return deposit price */
        return node.shares == 0
            ? FIXED_POINT_SCALE
            : (Math.min(node.value + accrual.accrued, node.available + node.pending) * FIXED_POINT_SCALE) / node.shares;
    }

    /*--------------------------------------------------------------------------*/
    /* Deposit API                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @inheritdoc IMstWrapper
     */
    function deposit(uint256 amount, uint256 minTokensOut) external nonReentrant returns (uint256) {
        /* Revert if deposit exceeds capacity */
        if (totalSupply() + amount > CAPACITY) revert DepositExceedsCapacity();

        /* Transfer currency tokens from user to wrapper */
        _currencyToken.safeTransferFrom(msg.sender, address(this), amount);

        /* Deposit into pool */
        uint256 tokens = _pool.deposit(_tick, amount, minTokensOut);

        /* Mint shares */
        _mint(msg.sender, tokens);

        emit Deposited(msg.sender, amount, tokens);

        return tokens;
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function redeem(uint256 amount) external nonReentrant returns (uint128) {
        /* Burn shares */
        _burn(msg.sender, amount);

        /* Call redeem on pool */
        uint128 redemptionId = _pool.redeem(_tick, amount);

        /* Set pending redemption status */
        _pendingRedemptions[redemptionId] = msg.sender;

        emit Redeemed(msg.sender, redemptionId, amount);

        return redemptionId;
    }

    /**
     * @inheritdoc IMstWrapper
     */
    function withdraw(uint128 redemptionId) external nonReentrant returns (uint256) {
        /* Check that a redemption is pending */
        if (_pendingRedemptions[redemptionId] != msg.sender) revert RedemptionNotPending();

        /* Call withdraw on pool */
        (uint256 sharesWithdrawn, uint256 amountWithdrawn) = _pool.withdraw(_tick, redemptionId);

        /* Reset pending redemption status if redemption complete */
        if (_pool.redemptions(address(this), _tick, redemptionId).pending == 0) {
            delete _pendingRedemptions[redemptionId];
        }

        /* Transfer */
        if (amountWithdrawn > 0) _currencyToken.safeTransfer(msg.sender, amountWithdrawn);

        emit Withdrawn(msg.sender, redemptionId, sharesWithdrawn, amountWithdrawn);

        return amountWithdrawn;
    }
}
