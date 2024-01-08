//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract HttpsDao is ERC721Enumerable, Ownable {
    uint8 public immutable maxTokenId;
    uint8 public currentMaxTokenId;
    uint8 public lastTokenId = 0;

    uint256 public immutable startTimestamp;
    uint256 public immutable priceInETH;

    string public baseURIPath;

    event BaseURIUpdated(string newURI);
    event CurrentMaxTokenIdUpdated(uint8 maxTokenId);

    constructor(uint8 _maxTokenId, uint8 _currentMaxTokenId, uint256 _priceInETH, string memory _baseURIPath, uint256 _startTimestamp) ERC721("HTTPSWORLDWIDE", "HTTPS") {
        maxTokenId = _maxTokenId;
        currentMaxTokenId = _currentMaxTokenId;
        priceInETH = _priceInETH;
        baseURIPath = _baseURIPath;
        startTimestamp = _startTimestamp;
    }

    function mint() external payable {
        require(block.timestamp >= startTimestamp, "Not time yet");
        require(msg.value == priceInETH, "msg.value != price");
        require(lastTokenId < currentMaxTokenId, "Sold out");

        lastTokenId += 1;
        _safeMint(msg.sender, lastTokenId);
    }

    function withdraw(address payable _to) external onlyOwner {
        require(_to != address(0), "Invalid address");
        _to.transfer(address(this).balance);
    }

    function updateBaseURI(string memory _newURI) external onlyOwner {
        baseURIPath = _newURI;
        emit BaseURIUpdated(baseURIPath);
    }

    function updateCurrentMaxTokenId(uint8 _currentMaxTokenId) external onlyOwner {
        require(_currentMaxTokenId <= maxTokenId, "Larger than maxTokenId");
        currentMaxTokenId = _currentMaxTokenId;
        emit CurrentMaxTokenIdUpdated(currentMaxTokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIPath;
    }
} 