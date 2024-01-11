//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

/**
 @title MoBuDao
 */
contract MoBuDao is ERC721A, Ownable {
    uint16 public constant MAX_SUPPLY = 6969;

    struct StageInfo {
        uint16 supply;
        uint240 price;
    }

    StageInfo private __stageInfo;

    string private __baseURI;

    /// @dev Setup ERC721 and initial baseURI
    constructor(string memory _initBaseURI, StageInfo memory _stageInfo)
        ERC721A("MoBuDao", "MBD", 5)
    {
        __baseURI = _initBaseURI;
        __stageInfo = _stageInfo;
    }

    /// @notice Mint NFT
    function mint(uint256 amount) external payable {
        require(
            totalSupply() + amount <= __stageInfo.supply,
            "exceed stage supply"
        );
        require(
            msg.value >= amount * __stageInfo.price,
            "not enough fund to mint"
        );
        _safeMint(_msgSender(), amount);
    }

    /// @dev Reserve NFT
    function reserve(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= __stageInfo.supply,
            "exceed stage supply"
        );
        _safeMint(to, amount);
    }

    /// @dev Set baseURI
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        __baseURI = newBaseURI;
    }

    /// @dev Set stage info
    function setStageInfo(StageInfo calldata newStageInfo) external onlyOwner {
        require(newStageInfo.supply <= MAX_SUPPLY, "exceed max supply");
        __stageInfo = newStageInfo;
    }

    /// @dev Withdraw
    function withdraw() external {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /// @dev Override _baseURI
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    /// @notice get mint price
    function MINT_PRICE() public view returns (uint240) {
        return __stageInfo.price;
    }

    /// @notice get stage supply
    function STAGE_SUPPLY() public view returns (uint16) {
        return __stageInfo.supply;
    }
}
