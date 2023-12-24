// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Initializable.sol";
import "./IAccessTokenVerifier.sol";

/**
 * @title AccessTokenConsumerUpgradeable
 * @dev Implementation of `AccessTokenConsumer`, for consuming Ethereum Access Tokens (EIP-7272),
 * compatible with OpenZeppelin UUPS upgradeable contracts.
 * @dev The AccessTokenConsumer contract is inherited by contracts that need to gate functions
 * using Ethereum Access Tokens (EIP-7272).
 * It provides the `requiresAuth` modifier which reverts unless a valid EAT is passed along with the function call.
 * This contract stores and points to an AccessTokenVerifier contract which is called to verify
 * an EAT after reconstructing it from a function call.
 * Finally, it keeps track of consumed EATs to prevent re-use.
 */
contract AccessTokenConsumerUpgradeable is Initializable {
    // Address of the AccessTokenVerifier currently used by this contract
    IAccessTokenVerifier public verifier;
    // Stores whether an EAT has already been used
    mapping(bytes32 => bool) private _accessTokenUsed;

    /**
     * @dev Initializes the AcessTokenConsumer by setting the AccessTokenVerifier address.
     * This must be called in the initializer function of contracts inheriting AccessTokenConsumer.
     */
    function __AccessTokenConsumer_init(address accessTokenVerifier) internal onlyInitializing {
        if (verifier == IAccessTokenVerifier(address(0))) {
            verifier = IAccessTokenVerifier(accessTokenVerifier);
        }
    }

    /**
     * @dev Adds a layer of access control to a function
     * by requiring a valid EAT to be provided.
     * If valid, it marks the EAT as consumed.
     */
    modifier requiresAuth(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) {
        // VF -> Verification Failure
        require(verify(v, r, s, expiry), "AccessToken: VF");
        _consumeAccessToken(v, r, s, expiry);
        _;
    }

    /**
     * @dev Updates the AccessTokenVerifier address this contract is pointing to.
     */
    function setVerifier(address newVerifier) internal {
        verifier = IAccessTokenVerifier(newVerifier);
    }

    /**
     * @dev Verifies an EAT by calling the AccessTokenVerifier.
     * Reverts if the EAT has already been used.
     */
    function verify(uint8 v, bytes32 r, bytes32 s, uint256 expiry) internal view returns (bool) {
        // AU -> Already Used
        require(!_isAccessTokenUsed(v, r, s, expiry), "AccessToken: AU");

        AccessToken memory token = constructToken(expiry);
        return verifier.verify(token, v, r, s);
    }

    /**
     * @dev Reconstructs an EAT based on `expiry` and current function call
     * to populate function signature, target contract address, caller and function parameters.
     */
    function constructToken(uint256 expiry) internal view returns (AccessToken memory token) {
        FunctionCall memory functionCall;
        functionCall.functionSignature = msg.sig;
        functionCall.target = address(this);
        functionCall.caller = msg.sender;

        functionCall.parameters = extractInputs();
        token.functionCall = functionCall;
        token.expiry = expiry;
    }

    /**
     * @dev Takes calldata and extracts non-signature, non-expiry function inputs as a byte array
     * Removes all references to the proof object except any offsets related to
     *  other inputs that are pushed by the proof
     */
    function extractInputs() public pure returns (bytes memory inputs) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            mstore(0x40, add(ptr, calldatasize()))

            let startPos := 0x04
            let endOfSigExp := add(startPos, 0x80)
            let totalInputSize := sub(calldatasize(), endOfSigExp)

            // Overwrite data to calldata pointer
            inputs := ptr

            // Store expected length of total byte array as first value
            mstore(inputs, totalInputSize)

            // Copy bytes from end of signature and expiry section to end of calldata
            calldatacopy(add(inputs, 0x20), endOfSigExp, totalInputSize)
        }
    }

    /**
     * @dev Returns whether an EAT has already been used.
     */
    function _isAccessTokenUsed(uint8 v, bytes32 r, bytes32 s, uint256 expiry) internal view returns (bool) {
        bytes32 accessTokenHash = keccak256(abi.encodePacked(v, r, s, expiry));
        return _accessTokenUsed[accessTokenHash];
    }

    /**
     * @dev Marks an EAT as consumed/used.
     */
    function _consumeAccessToken(uint8 v, bytes32 r, bytes32 s, uint256 expiry) private {
        bytes32 accessTokenHash = keccak256(abi.encodePacked(v, r, s, expiry));

        _accessTokenUsed[accessTokenHash] = true;
    }
}
