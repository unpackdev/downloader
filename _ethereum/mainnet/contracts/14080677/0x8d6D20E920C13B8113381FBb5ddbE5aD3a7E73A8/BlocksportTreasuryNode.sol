// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Blocksport treasury contract.
 */
abstract contract BlocksportTreasuryNode is Initializable {
    using AddressUpgradeable for address payable;

    address payable private treasury;

    /**
     * @dev Called once after the initial deployment to set the Blocksport treasury address.
     */
    function _initializeBlocksportTreasuryNode(address payable _treasury)
        internal
        initializer
    {
        require(
            _treasury.isContract(),
            "BlocksportTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    /**
     * @notice Returns the address of the Blocksport treasury.
     */
    function getBlocksportTreasury() public view returns (address payable) {
        return treasury;
    }

    // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
    uint256[2000] private __gap;
}
