// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract DaPengWan is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    uint8 public maxCount;
    uint32 public startTime;
    uint32 public endTime;
    uint256 public firstMintBlock;

    string private baseURI;
    Counters.Counter private _currentTokenId;

    event PurchaseRecord(uint8 purchaseId, uint256 amount, uint32 time);
    event PurchaseSaying(uint8 purchaseId, string name, string saying);

    constructor(
        uint32 startTime_,
        uint32 endTime_,
        uint8 maxCount_
    ) ERC721("Ocean Friendly Token", "OFT") {
        maxCount = maxCount_;
        startTime = startTime_;
        endTime = endTime_;
    }

    function mint(string memory name, string memory saying) external payable {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Not in event time"
        );
        require(msg.value >= 0.02e18, "Should pay at least 0.02 ether");
        require(
            _currentTokenId.current() < maxCount,
            "Reach maximum NFT amount"
        );

        _safeMint(msg.sender, _currentTokenId.current());
        _setTokenURI(
            _currentTokenId.current(),
            Strings.toString(_currentTokenId.current())
        );

        emit PurchaseRecord(
            uint8(_currentTokenId.current()),
            msg.value,
            uint32(block.timestamp)
        );
        emit PurchaseSaying(uint8(_currentTokenId.current()), name, saying);

        if (firstMintBlock == 0) {
            firstMintBlock = block.number;
        }
        _currentTokenId.increment();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMaxCount(uint8 maxCount_) external onlyOwner {
        require(maxCount_ < 2**8 - 1, "input exceeds 255");
        maxCount = maxCount_;
    }

    function setEventTime(uint32 startTime_, uint32 endTime_)
        external
        onlyOwner
    {
        startTime = startTime_;
        endTime = endTime_;
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function currentTokenId() external view returns (uint256) {
        return _currentTokenId.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
