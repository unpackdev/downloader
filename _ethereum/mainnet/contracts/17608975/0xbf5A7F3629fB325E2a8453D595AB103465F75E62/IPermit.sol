/// SPDX-License-Identifier: unlicensed

/// @author Portals.fi
/// @notice Various Permit functions for ERC20 tokens

pragma solidity 0.8.19;

interface IPermit {
    /// @notice EIP-2612 Permit
    /// @param owner The address which is a source of funds and has signed the Permit.
    /// @param spender The address which is allowed to spend the funds.
    /// @param value The quantity of tokens to be spent.
    /// @param deadline The timestamp after which the Permit is no longer valid.
    /// @param v A valid secp256k1 signature of Permit by owner
    /// @param r A valid secp256k1 signature of Permit by owner
    /// @param s A valid secp256k1 signature of Permit by owner
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Yearn style permit
    /// @param owner The address which is a source of funds and has signed the Permit.
    /// @param spender The address which is allowed to spend the funds.
    /// @param amount The amount of tokens to be spent.
    /// @param expiry The timestamp after which the Permit is no longer valid.
    /// @param signature A valid secp256k1 signature of Permit by owner encoded as
    /// r, s, v.
    /// @return True, if transaction completes successfully
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    /// @notice DAI style permit
    /// @param holder The address which is a source of funds and has signed the Permit.
    /// @param spender The address which is allowed to spend the funds.
    /// @param nonce The nonce of the spender
    /// @param expiry The timestamp after which the Permit is no longer valid.
    /// @param allowed Determines if the spender is allowed to spend the funds.
    /// @param v A valid secp256k1 signature of Permit by owner
    /// @param r A valid secp256k1 signature of Permit by owner
    /// @param s A valid secp256k1 signature of Permit by owner
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
