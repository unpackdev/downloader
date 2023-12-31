// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./AccessControlEnumerable.sol";

contract ERC721Full is Context, AccessControlEnumerable, ERC721, ERC721Enumerable, ERC721Pausable {

    /*** INIT ***/

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*** METHODS ***/

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        _pause();
    }

    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "INVALID_ROLE");
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}