// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ECDSA.sol";

interface IOrignalNFT{
    function purchaseTo(address _to, uint count) external payable returns (uint256 _tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract NFTWrapper is Ownable{

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public amountMinted;
    uint256 public maxMint;
    uint256 public maxBalance;
    address public orignalNFT;

    //+publicmint
    bool public publicmintmode=false;

    //+allmax
    uint256 public maxAllMint;
    uint256 public currentAllMint=0;


    constructor(uint256 _maxMint, address _orignalNFT, uint256 _maxBalance) {
        maxMint = _maxMint;
        orignalNFT = _orignalNFT;
        maxBalance = _maxBalance;
    }

    //------------------------Balance so nft wrapper is able to mint 
    function balanceOf(address _owner) external view returns (uint256 balance) {
        if(_owner ==  address(this)){
            return 1;
        }
        else{
            return 0;
        }
    }

    //------------------------Admin only (Whitelist+Max)
    function setOrignalNFT(address _orignalNFT) public onlyOwner {
        orignalNFT = _orignalNFT;
    }

    function setMaxMints(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    //+allmax
    function setMaxAllMint(uint256 _maxAllMint) public onlyOwner {
        maxAllMint = _maxAllMint;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function addWhitelist(address _whitelist) public onlyOwner {
        whitelist[_whitelist] = true;
    }

    function addBulkWhitelist(address[] calldata _whitelist) public onlyOwner {
        uint256 ctr = 0;
        while(ctr < _whitelist.length){
            whitelist[_whitelist[ctr]] = true;
            ctr = ctr + 1;
        }
    }

    function revokeWhitelist(address _whitelist) public onlyOwner {
        whitelist[_whitelist] = false;
    }

    //+publicmint
    function setPublicMintMode(bool publicmintmodein) public onlyOwner {
        publicmintmode=publicmintmodein;
    }

    //------------------------Purchase
    function purchase(uint256 _count) public payable returns (uint256 _tokenId) {
        return purchaseTo(msg.sender, _count);
    }

    function purchaseTo(address _user, uint256 _count) public payable returns (uint256 _tokenId){
        require(amountMinted[msg.sender] + _count <= maxMint, "Mint count higher than Max Mint");
        require((whitelist[msg.sender] == true)||publicmintmode, "Address not in whitelist");//+publicmint
        require(IOrignalNFT(orignalNFT).balanceOf(_user) <= maxBalance, "Max Balance Exceeded");
        require(currentAllMint <= maxAllMint, "Max mint reached for round");//+allmax


        amountMinted[msg.sender] = amountMinted[msg.sender] + _count;
        currentAllMint = currentAllMint+_count;//+allmax


        return IOrignalNFT(orignalNFT).purchaseTo{value:msg.value}(_user, _count);
    }


    //Self register------------------------------------------------------------------------------------------------------------------------


    bool public registerpause=true;
    address initialsigner;

    function SetSigner(address signerin) public onlyOwner{
        initialsigner= signerin;
    }

    function setregisterpause(bool pausein) public onlyOwner {
        registerpause=pausein;
    }

    //---------------------------self signer 

    //self register
    
    function SelfRegisterWL(bytes memory signature) public  {
        require(!registerpause,"register is paused");
        require(IsCallerSignedbySignAdmin(signature), "Caller isn't signed by sign admin");
                
        whitelist[msg.sender] = true;
    }

    function register_and_purchase(uint256 _count,bytes memory signature) public payable returns (uint256 _tokenId) {
        SelfRegisterWL(signature);
        return purchaseTo(msg.sender, _count);
    }
    
    //---------------------------signer

    using ECDSA for bytes32;

    function IsCallerSignedbySignAdmin(bytes memory signature) public view returns (bool)
    {
        return RecoverSignerFromCallerAndSign(signature)==initialsigner;
    }

    function RecoverSignerFromCallerAndSign(bytes memory signature) public view returns (address)
    {
        address addr=msg.sender;
        return keccak256(abi.encodePacked(addr)).recover(signature);
    }

    //Helper------------------------------------------------------------------------------------------------------------------------
    function CanWLPurchase(address purchaser) public view returns (bool){
        return ((whitelist[purchaser] == true)||publicmintmode);
    }
}
