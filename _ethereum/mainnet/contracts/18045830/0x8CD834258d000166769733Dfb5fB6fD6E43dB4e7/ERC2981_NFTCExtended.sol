// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC2981.sol";

/**
 * @title ERC2981_NFTCExtended
 * @author @NiftyMike | @NFTCulture
 * @dev A wrapper around ERC2981 which adds some common functionality.
 */
abstract contract ERC2981_NFTCExtended is ERC2981 {
    function setDefaultRoyalty(address newReceiver, uint96 newRoyalty) external {
        _isOwner();

        _setDefaultRoyalty(newReceiver, newRoyalty);
    }

    function _isOwner() internal view virtual;
}
