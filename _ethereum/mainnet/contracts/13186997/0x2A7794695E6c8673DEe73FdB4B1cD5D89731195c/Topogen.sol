// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NPass.sol";

/**
 * @title TopoGe(N) contract
 * @author Archethect
 * This contract generates topographical generative art for N holders through NPass
 */

contract Topogen is NPass {

    string public baseURI;

    constructor(string memory baseURI_) NPass("CrypTopo", "CRYPTOPO", true, 8888, 8888, 15000000000000000, 15000000000000000) {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return baseURI;
    }

}
