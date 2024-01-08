// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/*
                   ══           ══
                   ██           ██
                   ██           ██
               ███████████████████████
               ███████████████████████
   ██      ██  ████    ███████    ████  ██████████
   ██████████  ██  ████  ███  ████  ██  ██      ██
       ██      ██  ████  ███  ████  ██  ██████████
   ██████████  ██  ████  ███  ████  ██  ██      ██
   ██      ██  ████    ███████    ████  ██████████
               ███████████████████████
               ███████████████████████
                 ██ █████████████ ██
                 ██═══════════════██
                 ██═══════════════██
*/

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";


contract XyzzyBots is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;

    string internal baseTokenURI = "ipfs://bafybeie272kvby4m6pe3ap25t4on4g5a3pydsalnnuutlszhwlxfr6xzhy/";
    
    uint public NFT_PRICE = 0.05 ether;
    uint public MAX_NFT_PURCHASE = 10;
    uint public nftPerAddressLimit = 4;
    uint public MAX_SUPPLY = 10000;
    uint public freeMintSupply = 100;
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    
    address private a1 = 0xfaf8893Ac746e83444a5E63A8C2A6BCAa65E6da6; // CD
    address private a2 = 0x77F9C7477d82583C0e7B23430c92E672e47500Fc; // Meep
    address private a3 = 0x1f3CfC9Ee59D817C62412d72B6dEb98d7FceA13e; // Brain
    address private a4 = 0x0Ee111f19313eB3896F1333873fe6b6bEBBa9765; // JP
    address private a5 = 0xd562549EA677a648020f9179e0C89D9911462A40; // Kir
    address private a6 = 0xDa620F0CD5246E9d5Ee570033D0081249B817f8a; // Fud
    address private a7 = 0xCFBc3083b6400Fb4248D2D3B4Bc124C592eFAA36; // OG
    address private a8 = 0x595076ce19e6BDce9B147B6df3D0BfD068B3A52c; // Doz
    
    address private admin = 0x3029caC2426D7A6b4862642f8D6b01fa9e9bcC24;
    
    event Mint(address owner, uint qty);
    event FreeMint(address to, uint qty);
    event Withdraw(uint256 amount);

    constructor() ERC721("XyzzyBots", "XYZZYBOTS") {}
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
        if (preSaleIsActive) {
          preSaleIsActive = !preSaleIsActive;
        }
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }
    
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        
        uint256 a1payment = balance.mul(30).div(100);
        uint256 a2payment = balance.mul(20).div(100);
        uint256 a3payment = balance.mul(15).div(100);
        uint256 a4payment = balance.mul(15).div(100);
        uint256 a5payment = balance.mul(5).div(100);
        uint256 a6payment = balance.mul(5).div(100);
        uint256 a7payment = balance.mul(5).div(100);
        uint256 a8payment = balance.mul(5).div(100);
        
        bool success;
        success = payable(a1).send(a1payment);
        require(success);
        success = payable(a2).send(a2payment);
        require(success);
        success = payable(a3).send(a3payment);
        require(success);
        success = payable(a4).send(a4payment);
        require(success);
        success = payable(a5).send(a5payment);
        require(success);
        success = payable(a6).send(a6payment);
        require(success);
        success = payable(a7).send(a7payment);
        require(success);
        success = payable(a8).send(a8payment);
        require(success);
        
        emit Withdraw(balance);
    }
    
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function reserveTokens(address _address, uint numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(freeMintSupply.sub(numberOfTokens) >= 0, "Purchase would exceed maximum number of free mints");
        
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_address, totalSupply() + 1);
            freeMintSupply--;
        }
        emit FreeMint(_address, numberOfTokens);
    }

    function mint(uint numberOfTokens, bytes calldata _sig) public payable {
        require(saleIsActive || preSaleIsActive, "Sale or PreSale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY.sub(freeMintSupply), "Purchase would exceed max supply of XyzzyBots");
        require(numberOfTokens <= MAX_NFT_PURCHASE, "Can only mint up to 10 per purchase");

        if (msg.sender != owner()) {
            if (preSaleIsActive) {
                require(checkWhitelisted(msg.sender, _sig), "User is not whitelisted");
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require(ownerTokenCount.add(numberOfTokens) <= nftPerAddressLimit, "Max NFT per address exceeded");
            }
            require(NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");
        }

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
        emit Mint(msg.sender, numberOfTokens);
    }

    function checkWhitelisted(address _address, bytes calldata _sig) public view returns (bool) {
        bytes32 _rawHash = keccak256(abi.encodePacked(_address));
        return admin == _rawHash.recover(_sig);
    }
}
