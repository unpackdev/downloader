// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";

/**
 * @notice A reference to the treasury contract.
 */
abstract contract TreasuryNode is Initializable {
    using AddressUpgradeable for address payable;

    address payable private treasury;
    address payable private creatorPaymentAddress;
    uint256 private secondaryFakturaFeeBasisPoints;
    uint256 private secondaryCreatorFeeBasisPoints;

    /**
     * @dev Called once after the initial deployment to set the treasury address.
     */
    function __TreasuryNode_init(address payable _treasury, address payable _creatorPaymentAddress, uint256 _secondaryFakturaFeeBasisPoints, uint256 _secondaryCreatorFeeBasisPoints) internal initializer {
        require(!_treasury.isContract(), "TreasuryNode: Address is a contract");
        require(!_creatorPaymentAddress.isContract(), "CreatorNode: Address is a contract");

        treasury = _treasury;
        creatorPaymentAddress = _creatorPaymentAddress;
        secondaryFakturaFeeBasisPoints = _secondaryFakturaFeeBasisPoints;
        secondaryCreatorFeeBasisPoints = _secondaryCreatorFeeBasisPoints;
    }

    /**
     * @notice Returns the address of the treasury.
     */
    function getTreasury() public view returns (address payable) {
        return treasury;
    }

    /**
     * @notice Returns the address of the creator.
     */
    function getTokenCreatorPaymentAddress() public view returns (address payable) {
        return creatorPaymentAddress;
    }

    function getFeeConfig() public view
    returns (uint256, uint256) {
        return (secondaryFakturaFeeBasisPoints,secondaryCreatorFeeBasisPoints);
    }
}