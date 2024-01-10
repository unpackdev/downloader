pragma solidity 0.6.4;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param destinationChainID Chain ID deposit is expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @param depositer Address of account making the deposit in the Bridge contract.
     */
    function deposit(
        bytes32 resourceID,
        bytes8 destinationChainID,
        uint64 depositNonce,
        address depositer,
        address recipientAddress,
        uint256 amount,
        bytes calldata params
    ) external returns (address);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
     */
    function executeProposal(bytes32 resourceID, address recipientAddress, uint256 amount, bytes calldata params) external;
    function getAddressFromResourceId(bytes32 resourceID) external view returns(address);
}
