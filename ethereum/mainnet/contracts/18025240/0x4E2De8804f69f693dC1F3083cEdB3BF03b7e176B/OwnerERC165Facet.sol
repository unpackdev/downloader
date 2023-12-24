// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./OwnableInternal.sol";
import "./ERC165BaseInternal.sol";

contract OwnerERC165Facet is OwnableInternal, ERC165BaseInternal {
    function setSupportsInterface(bytes4 interfaceId, bool supportsInterface)
        public
        onlyOwner
    {
        _setSupportsInterface(interfaceId, supportsInterface);
    }
}
