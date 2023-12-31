pragma solidity 0.8.18;

// This is from Circle's TokenMessenger contract
// https://github.com/circlefin/evm-cctp-contracts/blob/master/src/TokenMessenger.sol
interface ICircleTokenMessenger {
    /**
    * @notice Deposits and burns tokens from sender to be minted on destination domain.
    * Emits a `DepositForBurn` event.
    * @dev reverts if:
    * - given burnToken is not supported
    * - given destinationDomain has no CircleBridge registered
    * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
    * to this contract is less than `amount`.
    * - burn() reverts. For example, if `amount` is 0.
    * - MessageTransmitter returns false or reverts.
    * @param amount amount of tokens to burn
    * @param destinationDomain destination domain (ETH = 0, AVAX = 1)
    * @param mintRecipient address of mint recipient on destination domain
    * @param burnToken address of contract to burn deposited tokens, on local domain
    * @return nonce unique nonce reserved by message
    */
    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 nonce);
}