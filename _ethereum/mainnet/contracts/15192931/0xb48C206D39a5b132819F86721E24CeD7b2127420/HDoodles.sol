// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract HDoodles is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 4e15; // 0.004 ETH

    string private __baseUri__;

    uint64 public startTime;

    constructor(string memory baseUri__, uint64 _startTime) ERC721("H/Doodles", "HDoodles") {
        __baseUri__ = baseUri__;
        startTime = _startTime;
    }

    function mint(uint256[] calldata tokenIds) external payable {
        uint256 len = tokenIds.length;
        require(len != 0, "HDoodles: invalid length");
        require(msg.value == len * PRICE, "HDoodles: invalid price");
        require(block.timestamp >= startTime, "HDoodles: not ready to start");

        for (uint256 i = 0; i < len; i += 1) {
            uint256 tokenId = tokenIds[i];
            require(tokenId < MAX_SUPPLY, "HDoodles: invalid tokenId");

            _safeMint(msg.sender, tokenId);
        }
    }

    function withdraw(address recipient, uint256 amount) external onlyOwner {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "HDoodles: withdraw failed");
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseUri__;
    }
}
