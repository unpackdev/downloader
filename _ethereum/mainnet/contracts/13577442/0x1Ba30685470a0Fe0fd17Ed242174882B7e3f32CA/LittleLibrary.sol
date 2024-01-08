// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IERC721.sol";



contract LittleLibrary {

    function has(address contractAddress, uint256 tokenId) public view returns (bool) {
        require(IERC721(contractAddress).supportsInterface(type(IERC721).interfaceId), "Little Library: contract address must support ERC721 interface");
        address ownerOfToken = IERC721(contractAddress).ownerOf(tokenId);
        return ownerOfToken == address(this);
    }

    function take(address contractAddress, uint256 tokenId) public {
        require(IERC721(contractAddress).supportsInterface(type(IERC721).interfaceId), "Little Library: contract address must support ERC721 interface");
        IERC721(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    }

}
