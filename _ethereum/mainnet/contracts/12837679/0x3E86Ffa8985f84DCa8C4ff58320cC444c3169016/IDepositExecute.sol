pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {

    struct SwapInfo {
        uint64 transferFeeMultiplier;
        uint64 exchangeFeeMultiplier;
        uint128 baseFee;
        uint256 providedFee;

        uint64  depositNonce;
        uint    index;
        uint256 returnAmount;
        bytes   recipient;

        address stableTokenAddress;
        address handler;

        uint256        srcTokenAmount;
        uint256        srcStableTokenAmount;
        uint256        destStableTokenAmount;
        uint256        destTokenAmount;

        uint256        lenRecipientAddress;
        uint256        lenSrcTokenAddress;
        uint256        lenDestTokenAddress;
        uint256        lenDestStableTokenAddress;

        bytes20        srcTokenAddress;
        address        srcStableTokenAddress;
        bytes20        destTokenAddress;
        address        destStableTokenAddress;


        uint256[] distribution;
        uint256[] flags;
        address[] path;

    }
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
        @param swapDetails Swap details

     */
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        address depositer,
        bytes calldata data,
        SwapInfo calldata swapDetails
    ) external;

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(
        bytes32 resourceID, 
        bytes calldata data, 
        SwapInfo calldata swapDetails
    ) external;
}
