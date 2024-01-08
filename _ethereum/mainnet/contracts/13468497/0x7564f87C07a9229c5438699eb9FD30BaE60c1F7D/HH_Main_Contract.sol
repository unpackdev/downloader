// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./HHVoucherSigner.sol";
import "./HHVoucher.sol";

contract HellHounds is ERC721Enumerable, Ownable, HHVoucherSigner {  
    using Address for address;

    // Sale Controls
    bool public presaleActive = false;
    bool public saleActive = false;
    
    // Mint Price
    uint256 public price = 66600000000000000; // 0.0666 ETH

    // Token Supply
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant GIFT_SUPPLY = 100;
    uint256 public constant PUBLIC_SUPPLY = MAX_SUPPLY - GIFT_SUPPLY;

    // Contract URI
    string public contractURI;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Presale Address List
    mapping (uint => uint) public claimedVouchers;

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    constructor (string memory newBaseURI, address voucherSigner) ERC721 ("Hell Hounds", "HH") HHVoucherSigner(voucherSigner) {
        setBaseURI(newBaseURI);
        _safeMint(msg.sender, 0);
    }

    // Check Token # Ownership
    function checkHoundOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(addr);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(addr, i);
        }
        return tokensId;
    }

    // Minting Function
    function mintHound(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( saleActive,                     "Sale Not Active" );
        require( _amount > 0 && _amount < 11,    "Can't Mint More Than 10 Tokens" );
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount,   "Incorrect Amount Of ETH Sent" );
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // Presale Minting
    function mintPresale(uint256 _amount, HHVoucher.Voucher calldata v) public payable {
        uint256 supply = totalSupply();
        require(presaleActive, "Private sale not open");
        require(claimedVouchers[v.voucherId] + _amount <= 2, "No Voucher For Your Address");
        require(_amount <= 2, "Can't Mint More Than Two");
        require(v.to == msg.sender, "No Voucher For Your Address");
        require(HHVoucher.validateVoucher(v, getVoucherSigner()), "Invalid voucher");
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        for(uint256 i; i < _amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    // Validate Voucher
    function validateVoucher(HHVoucher.Voucher calldata v) external view returns (bool) {
        return HHVoucher.validateVoucher(v, getVoucherSigner());
    }

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= MAX_SUPPLY, "Not Enough Supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

    }

     // Incase ETH Price Rises Rapidly
    function setPrice(uint256 newPrice) public onlyOwner() {
        price = newPrice;
    }

    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Pre Sale On/Off
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Set Contract URI
    function setContractURI(string memory newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    // Withdraw Function
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}