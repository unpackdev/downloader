// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";

interface IOrignalNFT{
    function purchaseTo(address _to, uint count) external payable returns (uint256 _tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
}
contract NFTWrapperTwo is Ownable{

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistAmount;
    mapping(address => uint256) public amountMinted;
    uint256 public maxMint;
    uint256 public maxBalance;
    address public orignalNFT;
    uint256 public mintCost;
    

    constructor(uint256 _maxMint, address _orignalNFT, uint256 _maxBalance, uint256 _mintCost) {

        require(_orignalNFT != address(0), "OrignalNFT cannot be 0 Address");
        maxMint = _maxMint;
        orignalNFT = _orignalNFT;
        maxBalance = _maxBalance;
        mintCost = _mintCost;
    }

    function balanceOf(address _userAddress) external view returns (uint256 balance) {
        if(_userAddress ==  address(this)){
            return 1;
        }
        else{
            return 0;
        }
    }

    function setMaxMints(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setOrignalNFT(address _orignalNFT) external onlyOwner {
        require(_orignalNFT != address(0), "OrignalNFT cannot be 0 Address");
        orignalNFT = _orignalNFT;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyOwner {
        maxBalance = _maxBalance;
    }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addWhitelist(address[] calldata _whitelist, uint256 _amount) external onlyOwner {
        
        for(uint256 i=0; i<_whitelist.length; i++) {
            address userAddress = _whitelist[i];
            whitelist[userAddress] = true;
            whitelistAmount[userAddress] = _amount;
        }
        
    }

    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
    }

    function revokeWhitelist(address _whitelist) external onlyOwner {
        whitelist[_whitelist] = false;
    }

    function mint(uint256 _count) external returns (uint256 _tokenId) {
        return mintTo(msg.sender, _count);
    }

    receive() external payable {  }
    
    function mintTo(address _user, uint256 _count) internal returns (uint256 _tokenId){

        require(amountMinted[msg.sender] + _count <= maxMint, "Mint count higher than Max Mint");
        require(amountMinted[msg.sender] + _count <= whitelistAmount[msg.sender], "Mint count higher than WL Mint");
        require(whitelist[msg.sender] == true, "Address not in whitelist");
        require(IOrignalNFT(orignalNFT).balanceOf(_user) <= maxBalance, "Max Balance Exceeded");

        amountMinted[msg.sender] = amountMinted[msg.sender] + _count;
        uint256 totalCost = mintCost * _count;
        return IOrignalNFT(orignalNFT).purchaseTo{value:totalCost}(_user, _count);
    }

}
