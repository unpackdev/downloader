// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./PreciseUnitMath.sol";
import "./IPositionController.sol";
import "./IBrightRiskToken.sol";
import "./IERC20Internal.sol";
import "./IPriceFeed.sol";

abstract contract AbstractController is OwnableUpgradeable, IPositionController {
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;

    uint256 constant PRECISION = 10**25;
    uint256 constant PRECISION_5_DEC = 1 * 10**5;
    uint256 constant PERCENTAGE_100 = 100 * PRECISION;
    uint256 constant PRECISION_5_PERCENTAGE_100 = 100 * PRECISION_5_DEC;
    uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60;

    StakingState public currentState;
    string public override description;
    IBrightRiskToken public index;
    ERC20 public base;
    FeeInfo public feeInfo;
    address public swapVia;
    address public swapRewardsVia;

    IUniswapV2Router02 internal _uniswapRouter;
    IPriceFeed internal _priceFeed;

    modifier onlyIndex() {
        require(_msgSender() == address(index), "AbstractController: No access");
        _;
    }

    modifier ownerOrIndex() {
        require(
            _msgSender() == address(index) || _msgSender() == owner(),
            "AbstractController: No access"
        );
        _;
    }

    function __AbstractController_init(
        string calldata _description,
        address _indexAddress,
        address _swapVia,
        address _swapRewardsVia,
        FeeInfo memory _feeInfo
    ) internal initializer {
        description = _description;
        index = IBrightRiskToken(_indexAddress);
        swapVia = _swapVia;
        swapRewardsVia = _swapRewardsVia;
        feeInfo = _feeInfo;
        setDependencies();
    }

    // (Re-)sets the fields which are dependent on Index
    // access: ADMIN or INDEX
    function setDependencies() public override ownerOrIndex {
        _priceFeed = IPriceFeed(index.getPriceFeed());
        _uniswapRouter = IUniswapV2Router02(_priceFeed.getUniswapRouter());
        base = ERC20(index.getBase());
    }

    function setFeeInfo(FeeInfo memory _feeInfo) public onlyOwner {
        feeInfo = _feeInfo;
    }

    function setSwapVia(address _swapVia) public override onlyIndex {
        swapVia = _swapVia;
    }

    function setSwapRewardsVia(address _swapRewardsVia) public override onlyIndex {
        swapRewardsVia = _swapRewardsVia;
    }

    function canStake() public view virtual override returns (bool) {
        return currentState != StakingState.UNSTAKING;
    }

    function canCallUnstake() public view virtual override returns (bool) {
        return currentState != StakingState.UNSTAKING;
    }

    function canUnstake() public view virtual override returns (bool) {
        return currentState == StakingState.UNSTAKING;
    }

    function _calculateRewards() internal view returns (uint256, uint256) {
        uint256 _rewards = outstandingRewards();
        if (_rewards == 0) {
            return (0, 0);
        }
        return _applyFees(_rewards);
    }

    function _applyFees(uint256 _rewards)
        internal
        view
        returns (uint256 _rewardsNoFee, uint256 _feeAmount)
    {
        if (_rewards == 0) {
            return (0, 0);
        }
        //calculate fee
        uint256 _feeAmountScale = _rewards.mul(feeInfo.successFeePercentage);
        // ScaleFactor (10e18) - fee
        uint256 b = PreciseUnitMath.preciseUnit().sub(feeInfo.successFeePercentage);

        _feeAmount = _feeAmountScale.div(b);
        _rewardsNoFee = _rewards.sub(_feeAmount);
    }

    function outstandingRewards() public view virtual override returns (uint256);

    function setStakingState() internal {
        currentState = StakingState.STAKING;
    }

    function staking() internal view returns (bool) {
        return currentState == StakingState.STAKING;
    }

    function setUnstakingState() internal {
        currentState = StakingState.UNSTAKING;
    }

    function setIdleState() internal {
        currentState = StakingState.IDLE;
    }

    function setWithdrawRewardsState() internal {
        currentState = StakingState.WITHDRAWING_REWARDS;
    }

    /**
     * Checks the token approvals to the Uniswap routers are sufficient. If not
     * it bumps the allowance to MAX_UINT_256.
     *
     * @param _asset     Asset to trade
     * @param _router    Uniswap router
     * @param _amount    Uniswap input amount
     */
    function _checkApprovals(
        IERC20 _asset,
        address _router,
        uint256 _amount
    ) internal {
        if (_asset.allowance(address(this), _router) < _amount) {
            _asset.approve(_router, PreciseUnitMath.MAX_UINT_256);
        }
    }

    /// @notice sets the tether allowance
    /// @dev USDT requires allowance to be set to zero before modifying its value
    function _checkTetherApprovals(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        string memory _symbol = IERC20Internal(_token).symbol();
        if (
            keccak256(bytes(_symbol)) == keccak256(bytes("USDT")) ||
            keccak256(bytes(_symbol)) == keccak256(bytes("TUSDT"))
        ) {
            ERC20(_token).safeApprove(_spender, 0);
            ERC20(_token).safeApprove(_spender, _amount);
        } else {
            ERC20(_token).safeApprove(address(_spender), _amount);
        }
    }

    function _swapTokenForToken(
        uint256 _amountIn,
        address _from,
        address _to,
        address _via
    ) internal returns (uint256) {
        if (_amountIn == 0) {
            return 0;
        }

        address[] memory pairs;

        if (_via == address(0)) {
            pairs = new address[](2);
            pairs[0] = _from;
            pairs[1] = _to;
        } else {
            pairs = new address[](3);
            pairs[0] = _from;
            pairs[1] = _via;
            pairs[2] = _to;
        }

        uint256 _expectedOut = _priceFeed.howManyTokensAinB(_to, _from, _via, _amountIn, false);
        uint256 _amountOutMin = _expectedOut.mul(99).div(100);

        return
            _uniswapRouter.swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                pairs,
                address(this),
                block.timestamp.add(600)
            )[pairs.length.sub(1)];
    }
}
