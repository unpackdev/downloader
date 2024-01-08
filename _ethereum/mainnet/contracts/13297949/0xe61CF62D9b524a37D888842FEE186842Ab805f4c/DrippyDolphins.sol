// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./AccessControl.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract DrippyDolphins is ERC721, AccessControl {
    using SafeMath for uint;

    uint public constant MAX_NFTS = 10000;

    uint public price;
    bool public hasSaleStarted = false;

    PaymentSplitter _paymentSplitter;
    uint _splitterId;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    constructor(string memory baseURI) ERC721("Drippy Dolphins", "DD") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
        price = 0.03 ether;
    }

    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_NFTS, "sold out");
        require(msg.value >= price.mul(quantity), "ether value sent is below the price");
        
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }
    
    function giftMint(uint quantity, address receiver) public onlyAdmin {
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_NFTS, "sold out");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
    }
    
    function toggleSale() public onlyAdmin {
        hasSaleStarted = !hasSaleStarted;
    }

    function setSplitterId(uint __splitterId) public onlyAdmin {
        _splitterId = __splitterId;
    }

    function withdrawAll() public payable onlyAdmin {
        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
    }
}