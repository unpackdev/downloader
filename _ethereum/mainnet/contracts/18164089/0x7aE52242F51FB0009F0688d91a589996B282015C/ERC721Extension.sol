// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract ERC721Extension is AdminControl, ICreatorExtensionTokenURI {
    using Strings for uint256;

    address private _creator;
    string private _baseURI;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AdminControl, IERC165) returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function mint() public {
        IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    function setBaseURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    function tokenURI(
        address creator,
        uint256 tokenId
    ) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
}
