// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// Inheritance
import "./ORentable.sol";

// References
import "./IRentable.sol";
import "./IORentableHooks.sol";
import "./ILandRegistry.sol";

/// @title OToken for Decentraland LAND
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Represents a transferrable tokenized deposit and mimics the wrapped token
contract OLandRegistry is ORentable {
    /* ========== CONSTRUCTOR ========== */

    /// @notice Instantiate a token
    /// @param wrapped wrapped token address
    /// @param owner admin for the contract
    /// @param rentable rentable address
    constructor(
        address wrapped,
        address owner,
        address rentable
    ) ORentable(wrapped, owner, rentable) {}

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Update current land operator, who can update content
    /// @param tokenId land identifier
    /// @param operator operator address
    function setUpdateOperator(uint256 tokenId, address operator) external {
        /// Makes operator updatable from the wrapper by depositor
        /// So depositor can still do OTC rent when not rented via Rentable
        require(ownerOf(tokenId) == msg.sender, "User not allowed");

        address wrapped = getWrapped();
        address rentable = getRentable();

        require(
            !IRentable(rentable).expireRental(wrapped, tokenId),
            "Operation not allowed during rental"
        );

        // slither-disable-next-line unused-return
        IORentableHooks(rentable).proxyCall(
            wrapped,
            ILandRegistry(wrapped).setUpdateOperator.selector,
            abi.encode(tokenId, operator)
        );
    }
}
