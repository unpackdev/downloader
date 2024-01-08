// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

import "./IBlitmap.sol";
import "./Base64.sol";
import "./StringUtils.sol";

contract MockBlitmap is ERC721, Ownable {

    constructor() payable ERC721("MockBlitmap", "BLIT") {}

    function tokenNameOf(uint256 _tokenId) public view returns (string memory) {
        return "Mock Blitmap";
    }

    function tokenSvgDataOf(uint256 tokenId) public view returns (string memory) {
        return '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32"><rect fill="#000000" x="0" y="0" width="1.5" height="1.5" /><rect fill="#000000" x="1" y="0" width="1.5" height="1.5" /><rect fill="#000000" x="2" y="0" width="1.5" height="1.5" /></svg>';
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        return tx.origin;
    }

}
