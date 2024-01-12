// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./PreciseUnitMath.sol";
import "./IPositionController.sol";
import "./IBrightRiskToken.sol";
import "./IERC20Internal.sol";
import "./IPriceFeed.sol";
import "./IExchangeAdapter.sol";
import "./IUniswapV2Router02.sol";

abstract contract AbstractController is OwnableUpgradeable, IPositionController {
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;

    struct ExchangeData {
        address[] path;
        uint24[] poolFees;
        string exchangeAdapter;
        uint256 outMin;
    }

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
    // DEPRECATED
    address public swapVia;
    //DEPRECATED
    address public swapRewardsVia;

    //DEPRECATED
    IUniswapV2Router02 internal _uniswapRouter;
    IPriceFeed internal _priceFeed;

    event UpdateFeeInfo(FeeInfo);
    event Stake(uint256 amount);
    event CallUnstake(uint256[] unstakes);
    event Unstake(uint256 amount);

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
        FeeInfo memory _feeInfo
    ) internal initializer {
        description = _description;
        index = IBrightRiskToken(_indexAddress);
        feeInfo = _feeInfo;
        setDependencies();
    }

    // (Re-)sets the fields which are dependent on Index
    // access: ADMIN or INDEX
    function setDependencies() public override ownerOrIndex {
        _priceFeed = IPriceFeed(index.getPriceFeed());
        base = ERC20(index.getBase());
    }

    function setFeeInfo(FeeInfo memory _feeInfo) external onlyOwner {
        feeInfo = _feeInfo;
        emit UpdateFeeInfo(_feeInfo);
    }

    function setExchangeAdapters(
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external virtual override;

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

    function _decodeExchangeData(bytes calldata _exchangeData)
        internal
        pure
        returns (ExchangeData memory)
    {
        (
            address[] memory _path,
            uint24[] memory _poolFees,
            string memory _exchangeAdapter,
            uint256 _outMin
        ) = abi.decode(_exchangeData, (address[], uint24[], string, uint256));
        return ExchangeData(_path, _poolFees, _exchangeAdapter, _outMin);
    }

    /**
     * Checks the token approvals to the Uniswap routers are sufficient. If not
     * it bumps the allowance to MAX_UINT_256.
     * Max approval is safe here since the caller doesn't hold any of the swappable assets
     *
     * @param _asset     Asset to trade
     * @param _adapter    Uniswap router
     * @param _amount    Uniswap input amount
     */
    function _checkApprovals(
        IERC20 _asset,
        address _adapter,
        uint256 _amount
    ) internal {
        if (_asset.allowance(address(this), _adapter) < _amount) {
            _asset.approve(_adapter, PreciseUnitMath.MAX_UINT_256);
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

    function _swap(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        address _adapter,
        ExchangeData memory _data
    ) internal returns (uint256) {
        uint256 _expectedOut = _priceFeed.howManyTokensAinB(_tokenOut, _tokenIn, _amountIn);

        require(_data.outMin > _expectedOut.mul(94).div(100), "Slippage exceeds the limit");

        if (_data.path[0] == address(0)) {
            return
                IExchangeAdapter(_adapter).swapExactInputSingle(
                    _tokenIn,
                    _tokenOut,
                    _recipient,
                    _amountIn,
                    _data.outMin,
                    _data.poolFees[0]
                );
        } else {
            return
                IExchangeAdapter(_adapter).swapExactInput(
                    _tokenIn,
                    _data.path,
                    _tokenOut,
                    _recipient,
                    _amountIn,
                    _data.outMin,
                    _data.poolFees
                );
        }
    }
}
