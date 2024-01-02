// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

// Contracts
import "./Initializable.sol";
import "./TokenTransfer.sol";

// Libraries
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./TickMath.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./TransferHelper.sol";

import "./ApeSwapHelper.sol";

// Interfaces
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./IUniswapV3Pool.sol";
import "./IUniswapV3SwapCallback.sol";

import "./IApeSwap_V2.sol";
import "./ITellerV2.sol";
import "./IMarketRegistry.sol";
import "./ILenderCommitmentForwarder.sol";

/**
 * @title ApeSwap
 * @notice Executes a series of actions (hops) in a single transaction allowing a user to take a Teller loan out by
 *  using collateral flash swapped from Uniswap.
 */
contract ApeSwap_V2 is
    IApeSwap_V2,
    IUniswapV3SwapCallback,
    Initializable,
    TokenTransfer
{
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address public immutable factory;
    ILenderCommitmentForwarder public immutable commitmentForwarder;
    ITellerV2 public immutable tellerV2;

    mapping(uint256 => address) public override loanBorrower;
    mapping(uint256 => LoanInfo) internal _loanInfo;

    function loanInfo(
        uint256 _loanId
    ) external view override returns (LoanInfo memory) {
        return _loanInfo[_loanId];
    }

    address private _activeBorrower;
    // Tracks the ID of the Teller loan that was opened during the current transaction.
    uint256 private _tellerLoanId;

    modifier activateBorrower() {
        require(_activeBorrower == address(0), "borrower already active");
        _activeBorrower = msg.sender;
        _;
        delete _activeBorrower;
    }

    modifier activeBorrower() {
        require(_activeBorrower != address(0), "no borrower active");
        _;
    }

    constructor(
        address _factory,
        ITellerV2 _tellerV2,
        ILenderCommitmentForwarder _commitmentForwarder
    ) {
        factory = _factory;
        tellerV2 = _tellerV2;
        commitmentForwarder = _commitmentForwarder;
    }

    function _initialize() public initializer {}

    function getTellerCommitmentFeePercentages(
        uint256 _commitmentId
    ) public view returns (uint256 protocolFee, uint256 marketFee) {
        uint256 marketId = commitmentForwarder.getCommitmentMarketId(
            _commitmentId
        );
        protocolFee = tellerV2.protocolFee();
        marketFee = tellerV2.marketRegistry().getMarketplaceFee(marketId);
    }

    /**
     * @notice Executes a series of actions (hops) in a single transaction.
     * @dev Open and Close position actions internally execute an additional "subhop" to either accept a commitment or
     *  repay a loan, respectfully, _after_ funds are borrowed from Uniswap.
     * @dev The caller of this function is used as the "active borrower" for the duration of the transaction.
     * @param _hops A list of actions to execute.
     */
    function apeSwap(ApeHop[] calldata _hops) external activateBorrower {
        for (uint i; i < _hops.length; i++) {
            _execute_ApeHop(_hops[i]);
        }
    }

    function _execute_ApeHop(ApeHop memory _hop) internal {
        if (_hop.action == ApeHopAction.ApeSwap_OpenPosition) {
            _execute_ApeSwap_OpenPosition(
                abi.decode(_hop.extraData, (ApeSwap_OpenPositionParams))
            );
        } else if (_hop.action == ApeHopAction.ApeSwap_ClosePosition) {
            _execute_ApeSwap_ClosePosition(
                abi.decode(_hop.extraData, (ApeSwap_ClosePositionParams))
            );
        } else if (_hop.action == ApeHopAction.TellerV2_AcceptCommitment) {
            _execute_TellerV2_Commitment(
                abi.decode(_hop.extraData, (TellerV2_CommitmentParams))
            );
        } else if (_hop.action == ApeHopAction.TellerV2_RepayLoan) {
            _execute_TellerV2_RepayLoan(
                abi.decode(_hop.extraData, (TellerV2_RepayLoanParams))
            );
        } else {
            revert("invalid action");
        }
    }

    /**
     * @notice Opens a new position by flash swapping funds from Uniswap to be used as collateral on a Teller loan.
     * @param _params Arguments required to open a position.
     */
    function _execute_ApeSwap_OpenPosition(
        ApeSwap_OpenPositionParams memory _params
    ) internal activeBorrower {
        address sellToken = _params.uniswapPoolInfo.sellToken;
        if (_params.supplySellAmount > 0) {
            IERC20(sellToken).transferFrom(
                _activeBorrower,
                address(this),
                _params.supplySellAmount
            );
        }

        _execute_UniswapV3_FlashSwap(
            UniswapV3_FlashSwapParams({
                poolInfo: _params.uniswapPoolInfo,
                flashAmount: _params.buyAmount,
                swapType: UniswapV3_SwapType.ExactOutput,
                subHop: ApeHop({
                    action: ApeHopAction.TellerV2_AcceptCommitment,
                    extraData: abi.encode(
                        TellerV2_CommitmentParams({
                            commitmentId: _params.tellerCommitmentId,
                            principalTokenAddress: sellToken,
                            principalAmount: 0, // will be calculated in _preFlashSwapSubHop
                            collateralAmount: _params.buyAmount,
                            collateralTokenAddress: _params
                                .uniswapPoolInfo
                                .buyToken,
                            collateralTokenId: 0,
                            interestRate: _params.interestRate,
                            loanDuration: _params.duration
                        })
                    )
                })
            })
        );

        emit PositionOpened(
            _tellerLoanId,
            _activeBorrower,
            _params.supplySellAmount
        );
        // once we emit the event, we can delete the loan ID reference
        delete _tellerLoanId;
    }

    /**
     * @notice Calculates the amount of tokens that will be returned from a position after repaying the loan.
     * @dev See `_execute_ApeSwap_ClosePosition`
     * @param _params Arguments required to close a position.
     * @return positionReturns_ The amount of tokens (remaining after repaying the loan) sent to the borrower.
     */
    function calculatePositionReturns(
        ApeSwap_ClosePositionParams memory _params
    ) external returns (uint256 positionReturns_) {
        require(msg.sender == address(0), "not allowed");
        // set the active borrower so we pass the require statement in _execute_ApeSwap_ClosePosition
        _activeBorrower = loanBorrower[_params.bidId];
        return _execute_ApeSwap_ClosePosition(_params);
    }
 

    /**
     * @notice Uses Uniswap to borrow funds to repay the Teller loan from an opened position.
     * @dev Funds borrowed from the Uniswap pool are sent to this contract so that it can repay the Teller loan.
     * @dev See `_execute_TellerV2_RepayLoan` for more information.
     * @param _params Arguments required to close a position.
     * @return remainingBalance_ The amount of tokens (remaining after repaying the loan) sent to the borrower.
     */
    function _execute_ApeSwap_ClosePosition(
        ApeSwap_ClosePositionParams memory _params
    ) internal activeBorrower returns (uint256 remainingBalance_) {
        require(loanBorrower[_params.bidId] == _activeBorrower, "not borrower");

        LoanInfo memory info = _loanInfo[_params.bidId];
        ApeSwapHelper.PoolInfo memory poolInfo = ApeSwapHelper.PoolInfo({
            buyToken: info.principalToken,
            sellToken: info.collateralToken,
            fee: _params.uniswapPoolFee
        });

        ITellerV2.Payment memory owed = tellerV2.calculateAmountOwed(
            _params.bidId,
            block.timestamp
        );
        uint256 amountOwed = owed.principal + owed.interest;

        // ensure we have an allowance set to pay back the loan
        IERC20(info.principalToken).approve(address(tellerV2), amountOwed);

        TellerV2_RepayLoanParams memory repayParams = TellerV2_RepayLoanParams({
            bidId: _params.bidId,
            repayFrom: address(this)
        });

        _execute_UniswapV3_FlashSwap(
            UniswapV3_FlashSwapParams({
                poolInfo: poolInfo,
                flashAmount: info.collateralAmount,
                swapType: UniswapV3_SwapType.ExactInput,
                subHop: ApeHop({
                    action: ApeHopAction.TellerV2_RepayLoan,
                    extraData: abi.encode(repayParams)
                })
            })
        );

        remainingBalance_ = IERC20(info.principalToken).balanceOf(
            address(this)
        );
        if (remainingBalance_ > 0) {
            _transfer(
                info.principalToken,
                address(this),
                _activeBorrower,
                remainingBalance_
            );
        }

        emit PositionClosed(_params.bidId, remainingBalance_);
    }

    /**
     * @notice Internally accepts a commitment via the `LENDER_COMMITMENT_FORWARDER`.
     * @param _params Arguments required to accept a commitment.
     */
    function _execute_TellerV2_Commitment(
        TellerV2_CommitmentParams memory _params
    ) internal virtual activeBorrower {
        // TODO: use own state variable to track this?
        uint256 marketId = commitmentForwarder.getCommitmentMarketId(
            _params.commitmentId
        );
        if (
            !tellerV2.hasApprovedMarketForwarder(
                marketId,
                address(commitmentForwarder),
                address(this)
            )
        ) {
            tellerV2.approveMarketForwarder(
                marketId,
                address(commitmentForwarder)
            );
        }

        // if we don't have enough collateral, transfer it from the borrower
        ILenderCommitmentForwarder.CommitmentCollateralType collateralTokenType = commitmentForwarder
                .commitments(_params.commitmentId)
                .collateralTokenType;
        uint256 balance = _balanceOfCollateral(
            collateralTokenType,
            _params.collateralTokenAddress,
            address(this),
            _params.collateralTokenId
        );
        if (balance < _params.collateralAmount) {
            _transferCollateral(
                collateralTokenType,
                _params.collateralTokenAddress,
                _activeBorrower,
                address(this),
                _params.collateralAmount - balance,
                _params.collateralTokenId
            );
        }
        _approveCollateral(
            collateralTokenType,
            _params.collateralTokenAddress,
            address(tellerV2.collateralManager()),
            _params.collateralAmount,
            _params.collateralTokenId
        );

        uint256 bidId = commitmentForwarder.acceptCommitmentWithRecipient(
            _params.commitmentId,
            _params.principalAmount,
            _params.collateralAmount,
            _params.collateralTokenId,
            _params.collateralTokenAddress,
            // recipient
            address(this),
            _params.interestRate,
            _params.loanDuration
        );
        // track the teller loan ID so we can emit the event after the flash swap
        _tellerLoanId = bidId;

        loanBorrower[bidId] = _activeBorrower;
        _loanInfo[bidId] = LoanInfo({
            principalToken: _params.principalTokenAddress,
            collateralToken: _params.collateralTokenAddress,
            collateralTokenId: _params.collateralTokenId,
            collateralAmount: _params.collateralAmount,
            collateralTokenType: collateralTokenType
        });
    }

    /**
     * @notice Internally repays a loan via the `TELLER_V2` contract.
     * @param _params Arguments required to repay a loan.
     */
    function _execute_TellerV2_RepayLoan(
        TellerV2_RepayLoanParams memory _params
    ) internal {
        ITellerV2.Payment memory payment = tellerV2.calculateAmountOwed(
            _params.bidId,
            block.timestamp
        );
        uint256 paymentAmount = payment.principal + payment.interest;

        if (paymentAmount > 0) {
            if (
                _params.repayFrom != address(0) &&
                _params.repayFrom != address(this)
            ) {
            
                require( _params.repayFrom == _activeBorrower , "Can only use borrower funds to repay.");

                IERC20(_loanInfo[_params.bidId].principalToken).transferFrom(
                    _params.repayFrom,
                    address(this),
                    paymentAmount
                );
            }

            IERC20(_loanInfo[_params.bidId].principalToken).approve(
                address(tellerV2),
                paymentAmount
            );
        }

        
        tellerV2.repayLoanFull(_params.bidId);
    }

    /**
     * @notice Executes a flash swap from Uniswap, if required, then executes a "subhop" in the callback after the funds
     *  are received from the Uniswap pool.
     * @param _params Arguments required to execute a flash swap.
     */
    function _execute_UniswapV3_FlashSwap(
        UniswapV3_FlashSwapParams memory _params
    ) internal {
        UniswapV3_FlashSwapCallbackData memory callbackData;
        callbackData.poolInfo = _params.poolInfo;
        callbackData.subHop = _params.subHop;

        PoolAddress.PoolKey memory poolKey = ApeSwapHelper.getPoolKey(
            _params.poolInfo
        );

        // specify token1 as output token
        bool zeroForOne = _params.poolInfo.buyToken == poolKey.token1;

        int256 flashAmount = int256(_params.flashAmount);
        // swap amount value must be negative to specify exact output
        if (_params.swapType == UniswapV3_SwapType.ExactOutput) {
            flashAmount *= -1;
        }

        ApeSwapHelper.getPool(factory, poolKey).swap(
            // recipient
            address(this),
            zeroForOne,
            flashAmount,
            // 0 sqrtPriceLimitX96 means no limit
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(callbackData)
        );
    }

    /**
     * @notice Implements the callback called from the Uniswap pool after this contract was transferred the funds.
     * @param _delta0 The delta from calling flash for token0
     * @param _delta1 The delta from calling flash for token1
     * @param _callbackData The data needed in the callback passed as FlashCallbackData from `initFlash`
     */
    function uniswapV3SwapCallback(
        int256 _delta0, // a negative delta means we RECEIVED that
        int256 _delta1, // a positive delta means we OWE that
        bytes calldata _callbackData
    ) public virtual override activeBorrower {
        require(_delta0 > 0 || _delta1 > 0, "no 0 swaps");

        UniswapV3_FlashSwapCallbackData memory params = abi.decode(
            _callbackData,
            (UniswapV3_FlashSwapCallbackData)
        );
        PoolAddress.PoolKey memory poolKey = ApeSwapHelper.getPoolKey(
            params.poolInfo
        );
        // require that only the pool can call this
        CallbackValidation.verifyCallback(factory, poolKey);

        _preFlashSwapSubHop(_delta0, _delta1, params);

        // perform the next action after funds have been received
        // the result should end in having enough of a balance to pay for the swap
        _execute_ApeHop(params.subHop);

        // pay the pool what we owe
        _repayPool(IUniswapV3Pool(msg.sender), address(this), _delta0, _delta1);
    }

    function _preFlashSwapSubHop(
        int256 _delta0,
        int256 _delta1,
        UniswapV3_FlashSwapCallbackData memory _callbackData
    ) internal virtual {
        if (
            _callbackData.subHop.action ==
            ApeHopAction.TellerV2_AcceptCommitment
        ) {
            TellerV2_CommitmentParams memory commitmentParams = abi.decode(
                _callbackData.subHop.extraData,
                (TellerV2_CommitmentParams)
            );

            uint256 requiredLoanAmount = uint256(
                _delta0 > 0 ? _delta0 : _delta1
            );
            uint256 currentBalance = IERC20(
                commitmentParams.principalTokenAddress
            ).balanceOf(address(this));
            require(
                currentBalance < requiredLoanAmount,
                "already have enough funds"
            );
            requiredLoanAmount = requiredLoanAmount.sub(currentBalance);

            (
                uint256 protocolFeePercent,
                uint256 marketFeePercent
            ) = getTellerCommitmentFeePercentages(
                    commitmentParams.commitmentId
                );
            commitmentParams.principalAmount = ApeSwapHelper
                .calcAmountBeforeFees(
                    requiredLoanAmount,
                    protocolFeePercent + marketFeePercent
                );

            _callbackData.subHop.extraData = abi.encode(commitmentParams);
        }
    }

    function _repayPool(
        IUniswapV3Pool _pool,
        address payer,
        int256 _delta0,
        int256 _delta1
    ) internal virtual {
        if (_delta0 > 0)
            _transfer(_pool.token0(), payer, address(_pool), uint256(_delta0));
        if (_delta1 > 0)
            _transfer(_pool.token1(), payer, address(_pool), uint256(_delta1));
    }

    function _transfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == address(this))
            TransferHelper.safeTransfer(_token, _to, _amount);
        else TransferHelper.safeTransferFrom(_token, _from, _to, _amount);
    }
}
