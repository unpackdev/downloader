// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./UserOperation.sol";

/**
 * @title ILaserWallet
 * @author Rodrigo Herrera I.
 * @notice Has all the external functions, structs, events and errors for LaserWallet.sol.
 */
interface ILaserWallet {
    event Received(address indexed sender, uint256 amount);
    event Setup(address owner, address[] guardians, address entryPoint);
    event Success(address to, uint256 value, bytes4 funcSelector);

    ///@dev modifier custom error.
    error LW__notEntryPoint();

    ///@dev validateUserOp custom error.
    error LW__validateUserOp__invalidNonce();

    ///@dev exec() custom error.
    error LW__exec__failure();

    ///@dev isValidSignature() custom error.
    error LW__isValidSignature__invalidSigner();

    /**
     * @dev Setup function, sets initial storage of contract.
     * @param owner The owner of the wallet.
     * @param recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     * @param guardians Addresses that can activate the social recovery mechanism.
     * @param entryPoint Entry Point contract address.
     * @notice It can't be called after initialization.
     */
    function init(
        address owner,
        address recoveryOwner,
        address[] calldata guardians,
        address entryPoint
    ) external;

    /**
     * @dev Core interface to be EIP4337 compliant.
     * @param userOp the operation to be executed.
     * @param _requiredPrefund the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     * @notice only the EntryPoint contract can call this function.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32,
        uint256 _requiredPrefund
    ) external;

    /**
     * @dev Executes an AA transaction. The msg.sender needs to be the EntryPoint address.
     * The signatures are verified in validateUserOp().
     * @param to Destination address of the transaction.
     * @param value Ether value of the transaction.
     * @param data Data payload of the transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes memory data
    ) external;

    /**
     * @dev Returns the user operation hash to be signed by owners.
     * @param userOp The UserOperation struct.
     */
    function userOperationHash(UserOperation calldata userOp)
        external
        view
        returns (bytes32);

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        returns (bytes4);

    /**
     * @dev Returns the chain id of this.
     */
    function getChainId() external view returns (uint256);

    /**
     * @dev Returns the domain separator of this.
     * @notice This is done to avoid replay attacks.
     */
    function domainSeparator() external view returns (bytes32);
}
