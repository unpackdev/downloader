// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "ERC1155.sol";
import "Ownable.sol";
import "Counters.sol";

interface IYieldToken {
    function getRewardForAssets(address _ownerAddress, uint256[] memory _assetIds) external;
}

contract CrazyChihuahuaMysteryCamp is ERC1155, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private CCMCSupply;

    uint256 public constant CCMCMaxSupply = 10000;
    uint256 public constant CCMCPublicMintPrice = 80000000000000000;
    uint256 public constant CCMCMaxMintPerTx = 5;

    bool public CCMCSaleIsActive = true;
    bool public MCTRewardsActive;

    IYieldToken public MCT;

    constructor(string memory _metadataUri, uint256 _initialMintAmount) public ERC1155(_metadataUri) {
        for (uint256 i = 0; i < _initialMintAmount; i++) {
            CCMCSupply.increment();
            _mint(msg.sender, CCMCSupply.current(), 1, "");
        }
    }

    function totalSupply() public view returns (uint256) {
        return CCMCSupply.current();
    }

    modifier mintConditions(uint256 _numberOfAssets) {
        require(_numberOfAssets > 0 && _numberOfAssets <= CCMCMaxMintPerTx, "Invalid mint amount!");
        require(CCMCSupply.current() + _numberOfAssets <= CCMCMaxSupply, "No more supply!");
        require(CCMCSaleIsActive, "Sale not active!");
        require(msg.value >= _numberOfAssets * CCMCPublicMintPrice, "Not enough Ether!");
        _;
    }

    function mintCrazyChihuahua() public payable mintConditions(1) {
        CCMCSupply.increment();
        _mint(msg.sender, CCMCSupply.current(), 1, "");
    }

    function mintCrazyChihuahuas(uint256 _numberOfAssets) public payable mintConditions(_numberOfAssets) {
        for (uint256 i = 0; i < _numberOfAssets; i++) {
            CCMCSupply.increment();
            _mint(msg.sender, CCMCSupply.current(), 1, "");
        }
    }

    function getRewardForAssets(uint256[] memory _assetIds) public {
        require(MCTRewardsActive, "MCT rewards not yet launched!");
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            require(balanceOf(msg.sender, _assetIds[i]) != 0, "Asset not owned by sender!");
        }

        MCT.getRewardForAssets(msg.sender, _assetIds);
    }

    function setSaleState(bool _saleState) public onlyOwner {
        CCMCSaleIsActive = _saleState;
    }

    function setMetadataUri(string memory _newMetadataUri) public onlyOwner {
        _setURI(_newMetadataUri);
    }

    function setMCT(address _mct) public onlyOwner {
        MCT = IYieldToken(_mct);
    }

    function setMCTRewardsActive(bool _mctRewardsState) public onlyOwner {
        MCTRewardsActive = _mctRewardsState;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

