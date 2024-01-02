// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ILenderCommitmentForwarder.sol";
import "./ApeSwapHelper.sol";

interface IApeSwap_V2 {
    event PositionOpened(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 supplyAmount
    );

    event PositionClosed(uint256 indexed loanId, uint256 receiveAmount);

    struct LoanInfo {
        address principalToken;
        address collateralToken;
        uint256 collateralTokenId;
        uint256 collateralAmount;
        ILenderCommitmentForwarder.CommitmentCollateralType collateralTokenType;
    }

    enum ApeHopAction {
        ApeSwap_OpenPosition,
        ApeSwap_ClosePosition,
        TellerV2_AcceptCommitment,
        TellerV2_RepayLoan
    }

    struct ApeHop {
        ApeHopAction action;
        bytes extraData; // encoded hop data specific to the action
    }

    // TODO: add a variable to limit max leverage from the Teller loan
    struct ApeSwap_OpenPositionParams {
        ApeSwapHelper.PoolInfo uniswapPoolInfo;
        uint256 tellerCommitmentId;
        uint256 supplySellAmount; // how much the borrower is going to supply
        uint256 buyAmount;
        uint32 duration;
        uint16 interestRate;
    }

    struct ApeSwap_ClosePositionParams {
        uint256 bidId;
        uint24 uniswapPoolFee;
    }

    struct TellerV2_CommitmentParams {
        uint256 commitmentId;
        address principalTokenAddress;
        uint256 principalAmount;
        uint256 collateralAmount;
        uint256 collateralTokenId;
        address collateralTokenAddress;
        uint16 interestRate;
        uint32 loanDuration;
    }

    struct TellerV2_RepayLoanParams {
        uint256 bidId;
        address repayFrom;
    }

    enum UniswapV3_SwapType {
        ExactInput,
        ExactOutput
    }

    struct UniswapV3_FlashSwapParams {
        ApeSwapHelper.PoolInfo poolInfo;
        uint256 flashAmount;
        UniswapV3_SwapType swapType;
        ApeHop subHop;
    }

    struct UniswapV3_FlashSwapCallbackData {
        ApeSwapHelper.PoolInfo poolInfo;
        ApeHop subHop;
    }

    function loanBorrower(uint256 _loanId) external view returns (address);

    function loanInfo(uint256 _loanId) external view returns (LoanInfo memory);
}
