//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

/**
 @title MoBuDao
 */
contract MoBuDao is ERC721A, Ownable {
    uint16 public constant MAX_SUPPLY = 6969;

    uint256 public constant MINT_PRICE = 0.069 ether;

    uint256 public startTime;

    string private __baseURI;

    /// @dev Setup ERC721 and initial baseURI
    constructor(string memory _initBaseURI, uint256 _startTime)
        ERC721A("MoBuDao", "MBD", 5)
    {
        __baseURI = _initBaseURI;
        startTime = _startTime;
    }

    function mint(uint256 amount) external payable {
        require(block.timestamp >= startTime, "not start yet");
        require(msg.value >= amount * MINT_PRICE, "not enough fund");
        require(totalSupply() + amount <= MAX_SUPPLY, "exceed max supply");
        _safeMint(_msgSender(), amount);
    }

    /// @dev Set baseURI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    /// @dev Set start time
    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    /// @dev Withdraw
    function withdraw() external {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @dev Override _baseURI
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}
