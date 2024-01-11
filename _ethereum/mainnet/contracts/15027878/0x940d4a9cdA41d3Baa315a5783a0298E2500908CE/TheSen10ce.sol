//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract TheSen10ce is ERC721A, Ownable {
    uint256 public immutable maxBatchSize;
    uint256 public immutable collectionSize;
    bool public isMintPaused = true;
    string private _baseTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721A(name_, symbol_) {
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
    }

    function mint(uint256 quantity) external payable {
        require(
            quantity > 0,
            "quantity must be greater than 0"
        );
        require(
            quantity <= maxBatchSize,
            "over max batch size"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "not enough remaining reserved mint amout"
        );
        require(
            !isMintPaused,
            "minting is paused"
        );
        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleMintPause() external onlyOwner {
       isMintPaused = !isMintPaused;
    }
}
