// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct FunctionCall {
    bytes4 functionSignature;
    address target;
    address caller;
    bytes parameters;
}

struct AccessToken {
    uint256 expiry;
    FunctionCall functionCall;
}

/**
 * @title AccessTokenVerifier Interface
 * @notice Used to verify Ethereum Access Tokens
 */
interface IAccessTokenVerifier {
    /**
     * @dev Verifies an Ethereum Access Token, checking its integrity and that it was signed by
     * an expected, active EAT issuer.
     */
    function verify(AccessToken calldata token, uint8 v, bytes32 r, bytes32 s) external view returns (bool);

    /**
     * @dev Returns the signer's address of an AccessToken.
     */
    function verifySignerOf(AccessToken calldata token, uint8 v, bytes32 r, bytes32 s) external view returns (address);
}
