// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

///
/// @title Access control interface
/// @author Fija
/// @notice Defines methods and events for access control manipulation in contracts
///
interface IFijaACL {
    ///
    /// @dev emits when address is added to whitelist
    /// @param addr address added to the whitelist
    ///
    event WhitelistedAddressAdded(address addr);

    ///
    /// @dev emits when address is removed from whitelist
    /// @param addr address removed from the whitelist
    ///
    event WhitelistedAddressRemoved(address addr);

    ///
    /// @dev emits when owner is changed
    /// @param previousOwner address of previous owner
    /// @param newOwner address of new owner
    ///
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    ///
    /// @dev emits when governance is changed
    /// @param previousGovernance address of previous governance
    /// @param newGovernance address of new governance
    ///
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    ///
    /// @dev emits when reseller is changed
    /// @param previousReseller address of previous reseller
    /// @param newReseller address of new reseller
    ///
    event ResellerTransferred(
        address indexed previousReseller,
        address indexed newReseller
    );

    ///
    /// @dev adds address to whitelist
    /// @param addr address to be added to whitelist
    /// @return true if address was added, false if it already in whitelist
    ///
    function addAddressToWhitelist(address addr) external returns (bool);

    ///
    /// @dev removes address from whitelist
    /// @param addr address to be removed from whitelist
    /// @return true if address was removed, false if it not in the whitelist
    ///
    function removeAddressFromWhitelist(address addr) external returns (bool);

    ///
    /// @dev contract owner
    /// @return address of the current owner
    ///
    function owner() external view returns (address);

    ///
    /// @dev contract governance
    /// @return address of the current governance
    ///
    function governance() external view returns (address);

    ///
    /// @dev contract reseller
    /// @return address of the current reseller
    ///
    function reseller() external view returns (address);

    ///
    /// @dev checks if address is in whitelist
    /// @param addr address to check if it is in whitelist
    /// @return true if address is in contract whitelist, false if it is not.
    ///
    function isWhitelisted(address addr) external view returns (bool);

    ///
    /// @dev changes ownership to new owner address
    /// @param newOwner address of new owner
    ///
    function transferOwnership(address newOwner) external;

    ///
    /// @dev changes governance to new governance address.
    /// @param newGovernance address of new governance
    ///
    function transferGovernance(address newGovernance) external;

    ///
    /// @dev changes reseller to new reseller address.
    /// @param newReseller address of new reseller
    ///
    function transferReseller(address newReseller) external;

    ///
    /// @dev Leaves the contract without governance.
    /// It will not be possible to call `onlyGovernance` functions anymore.
    /// Renouncing governance will leave the contract without governance,
    /// thereby removing any functionality that is only available to the governance.
    ///
    function renounceGovernance() external;

    ///
    /// @dev Leaves the contract without reseller.
    /// It will not be possible to call `onlyReseller` functions anymore.
    /// Renouncing reseller will leave the contract without reseller,
    /// thereby removing any functionality that is only available to the reseller.
    ///
    function renounceReseller() external;
}
