// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./ERC721A.sol";
import "./SkyGuysVoucherSigner.sol";
import "./SkyGuysVoucher.sol";

// Sky Guys v1.0.8

contract SkyGuys is ERC721A, Ownable, SkyGuysVoucherSigner {  
    using Address for address;
    using SafeMath for uint256;

    // Sale Controls
    bool public presaleActive = false;
    bool public reducedPresaleActive = false;
    bool public saleActive = false;

    // Mint Price
    uint256 public price = 0.05 ether;
    uint256 public reducedPrice = 0.05 ether;

    uint public MAX_SUPPLY = 5400;
    uint public PUBLIC_SUPPLY = 5245;
    uint public GIFT_SUPPLY = 155;  // 25 for team member + 30 for marketing

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Team Addresses
    address public a1 = 0x9751ec2F308B9AaEB8C26d2700223aEe45D96804; // Leandro
    address public a2 = 0x8F827C96aE53BDB5ce22654d6d6406663B01eB3D; // Brett
    address public a3 = 0x77caF3a30aC52edf96DA6a725342141Cc4865D1e; // Jena
    address public a4 = 0x3d5789454C710c7da09Be7D8ACad6f72c7289473; // Andrew - ACEO
    address public a5 = 0x6bf40B955a09b0F98c432187E74Ff02DdA4b1F63; // Mohit
    
    // Community Wallet
    address public a6 = 0x61Ee8490D3456312374331896f2f3E7323E2BB3b; // Community Wallet

    // Presale Address List
    mapping (uint => uint) public claimedVouchers;

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    // Contract Construction
    constructor ( 
    string memory newBaseURI, 
    address voucherSigner,
    uint256 maxBatchSize_,
    uint256 collectionSize_ 
    ) 
    ERC721A ("SkyGuys", "SkyGuys", maxBatchSize_, collectionSize_) 
    SkyGuysVoucherSigner(voucherSigner) {
        setBaseURI(newBaseURI);
    }

    // ================ Mint Functions ================ //

    // Minting Function
    function mintSkyGuys(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require( saleActive, "Public Sale Not Active" );
        require( _amount > 0 && _amount <= maxBatchSize, "Can't Mint More Than 5" );
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount, "Incorrect Amount Of ETH Sent" );
        _safeMint( msg.sender, _amount);
    }

    // Presale Minting
    function mintPresale(uint256 _amount, SkyGuysVoucher.Voucher calldata v) public payable {
        uint256 supply = totalSupply();
        require(presaleActive, "Private Sale Not Active");
        require(claimedVouchers[v.voucherId] + _amount <= 5, "Max 5 During Presale");
        require(_amount <= 5, "Can't Mint More Than 5");
        require(v.to == msg.sender, "You Are NOT Whitelisted");
        require(SkyGuysVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        _safeMint( msg.sender, _amount);
    }

    // Presale Reduced Minting
    function mintReducedPresale(uint256 _amount, SkyGuysVoucher.Voucher calldata v) public payable {
        uint256 supply = totalSupply();
        require(reducedPresaleActive, "Reduced Private Sale Not Active");
        require(claimedVouchers[v.voucherId] + _amount <= 5, "Max 5 During Reduced Presale");
        require(v.voucherId >= 6000, "Not Eligible For Reduced Mint");
        require(_amount <= 5, "Can't Mint More Than 5");
        require(v.to == msg.sender, "You Are NOT Whitelisted");
        require(SkyGuysVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == reducedPrice * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        _safeMint( msg.sender, _amount);
    }

    // Validate Voucher
    function validateVoucher(SkyGuysVoucher.Voucher calldata v) external view returns (bool) {
        return SkyGuysVoucher.validateVoucher(v, getVoucherSigner());
    }

    // ================ Only Owner Functions ================ //

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require( supply + _amount <= MAX_SUPPLY, "Not Enough Supply" );
        _safeMint( _to, _amount );
    }

     // Incase ETH Price Rises Rapidly
    function setPrice(uint256 newPrice) public onlyOwner() {
        price = newPrice;
    }

    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // ================ Sale Controls ================ //

    // Pre Sale On/Off
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Reduced Pre Sale On/Off
    function setReducedPresaleActive(bool val) public onlyOwner {
        reducedPresaleActive = val;
    }

    // Public Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // ================ Withdraw Functions ================ //

    // Team Withdraw Function
    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(a1, balance.mul(16).div(100)); 
        _widthdraw(a2, balance.mul(16).div(100)); 
        _widthdraw(a3, balance.mul(16).div(100)); 
        _widthdraw(a4, balance.mul(16).div(100)); 
        _widthdraw(a5, balance.mul(16).div(100)); 
        _widthdraw(a6, address(this).balance); // Community Wallet
    }

    // Private Function -- Only Accesible By Contract
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Emergency Withdraw Function -- Sends to Multisig Wallet
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(a6).transfer(balance);
    }

}