// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";


/*
**************************************************************
**************************************************************
*   ______   __   __________   ______   __     __     ______ *
*../  _   |.|  |.(___    ___)./  _   |.|  |...|  |.../  _   |*
*./  /.|  |.|  |.....|  |... /  /.|  |.|  |...|  |../  /.|  |*
*|  (__|  |.|  |.....|  |...|  (__|  |.|  \.../  |.|  (__|  |*
*|   __   |.|  |___ .|  |...|   __   |..\  \_/  /..|   __   |*
*|__(..(__|.|______|.|__|...|__(..(__|...\_____/...|__(..(__|*
*                                                            *
**************************************************************
*                                _   _                       *
*                               | | | |                      *
*                           __ _| |_| |_  __ _ __    __ __ _ *
*                          / _` | |_   _|/ _` |\ \  / // _` |*
*                         | (_| | | | | | (_| | \ \/ /| (_| |*
*                          \__,_|_| |_|  \__,_|  \__/  \__,_|*
**************************************************************
**************************************************************
*/

contract SecondSkinMinter is Ownable {
    SecondSkinERC721 private asset;
    address private assetAddress;
    
    uint256 private arrayIndex = 0;
    uint256 private startTime = 1646042400;
    uint256 private endTime = 1646215200;
    uint256 private mintPrice = 210000000000000000;

    uint256 private teamMinted = 0;
    string metadata = "";

    mapping (address => bool) public Wallets;

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory abc = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babc = bytes(abc);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babc[k++] = _bc[i];
        return string(babc);
    }
    
    function Mint() public payable returns (bool) {
        require(block.timestamp >= startTime && block.timestamp < endTime , "Not minting time");
        require(Wallets[msg.sender] || msg.sender == owner, "Not whitelisted wallet");
        require(msg.value >= mintPrice || (msg.sender == owner && teamMinted < 184), "Not right value");
        require(arrayIndex + 184 - teamMinted  < 2584, "Sold Out");

        asset = SecondSkinERC721(assetAddress);
        asset.mint(msg.sender, arrayIndex+1, strConcat(metadata, uint2str(arrayIndex+1), ".json"));
        
        if (msg.sender == owner) {
            teamMinted++;
        }
        arrayIndex++;

        Wallets[msg.sender] = false;

        return true;
    }

    function TeamMint(uint256 amount) public onlyOwner payable {
        require(teamMinted + amount < 185);
        
        asset = SecondSkinERC721(assetAddress);
        for (uint256 i = 0; i < amount; i++) {
            asset.mint(msg.sender, arrayIndex+1, strConcat(metadata, uint2str(arrayIndex+1), ".json"));
            teamMinted++;
            arrayIndex++;
        }
    }

    function getIndexCursor() public view returns (uint256) {
        return arrayIndex;
    }
    
    function getLeftTime() public view returns (uint256){
        return startTime - block.timestamp;
    }

    function getNowTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    function getLeftAmount() public view returns (uint256) {
        return 2584 - arrayIndex;
    }
    
    function setStartTime(uint256 _time) public onlyOwner returns (bool) {
        startTime = _time;
        return true;
    }
    function setEndTime(uint256 _time) public onlyOwner returns (bool) {
        endTime = _time;
        return true;
    }

    function addWhiteList(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            Wallets[_wallets[i]] = true;
        }
    }
    
    function setPrice(uint256 _price) public onlyOwner returns (bool) {
        mintPrice = _price;
        return true;
    }

    function getTeamMintedAmount() public onlyOwner view returns (uint256) {
        return teamMinted;
    }

    function getMetadata() public view returns (string memory) {
        return metadata;
    }

    function setMetadata(string memory _metadata) public onlyOwner {
        metadata = _metadata;
    }

    function getAssetAddress() public view returns (address) {
        return assetAddress;
    }

    function setAssetAddress(address _assetAddress) public onlyOwner {
        assetAddress = _assetAddress;
    }

    function returnAssetOwnership() public onlyOwner {
        asset = SecondSkinERC721(assetAddress);
        asset.transferOwnership(msg.sender);
    }
    
    function claimBalance(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function isWL() view public returns (bool) {
        return Wallets[msg.sender];
    }
}