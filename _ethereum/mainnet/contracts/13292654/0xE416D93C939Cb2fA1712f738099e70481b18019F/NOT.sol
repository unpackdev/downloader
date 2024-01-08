//SPDX-License-Identifier: GPL-3.0
//Created by BaiJiFeiLong@gmail.com at 2021/9/23 10:09
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NOT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    mapping(uint256 => uint256) private _segmentMints;

    constructor() ERC721("NotOwnerToken", "NOT") {
        console.log("Constructing...");
        for (uint256 i = 0; i < 10; ++i) {
            doMint();
        }
        console.log("Constructed.");
    }

    function maxSupply() public pure returns (uint256) {
        return 10000;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmVCgHdsd37d5MmFiKm34c3Q4srNigp4DYdFzJxWZ68okd";
    }

    function logoURI() public pure returns (string memory) {
        return "ipfs://QmTshtWaQE4o7nwCWKZErEb1DBvKubtujdVbAm8CcUJwrb";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory padding = tokenId < 10 ? "000" : tokenId < 100 ? "00" : tokenId < 1000 ? "0" : "";
        return string(abi.encodePacked(_baseURI(), "/not", padding, tokenId.toString(), ".json"));
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, totalSupply())));
    }

    function _fragmentSize() private pure returns (uint256) {
        return 100;
    }

    function _nextRandomTokenId() private view returns (uint256) {
        uint256 i = _random() % maxSupply();
        while (i < maxSupply()) {
            if (!_exists(i)) {
                return i;
            }
            if (_segmentMints[i / _fragmentSize()] >= _fragmentSize()) {
                i = (i + _fragmentSize()) % maxSupply();
            } else {
                i = i - (i % _fragmentSize()) + ((i + 1) % _fragmentSize());
            }
        }
        revert("Impossible");
    }

    function doMint() public {
        require(totalSupply() < maxSupply(), "No more tokens to mint");
        uint256 newTokenId = _nextRandomTokenId();
        console.log("Minting...", _msgSender(), newTokenId);
        _mint(_msgSender(), newTokenId);
        _segmentMints[newTokenId / _fragmentSize()] += 1;
    }
}