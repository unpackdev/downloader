// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./AccessControl.sol";

interface PaymentSplitter {
    function pay(uint id) external payable;
}

contract SimiHeaders is ERC721, AccessControl {
    using SafeMath for uint;

    uint public constant MAX_HEADERS = 10000;

    uint public price;
    uint public discount;
    bool public hasSaleStarted = false;

    ERC721 _wolfGangContract;
    ERC721 _wolfPupsContract;
    PaymentSplitter _paymentSplitter;
    address _cOwner;
    uint _splitterId;
    mapping(address => bool) public usedDiscounts;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    constructor(string memory baseURI, uint splitterId) ERC721("Simi Headers", "SIMIHEADER") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
        _cOwner = msg.sender;
        _wolfGangContract = ERC721(0x88c2b948749b13aBC1e0AE4B50ebeb2131D283C1);
        _wolfPupsContract = ERC721(0xE916AaEbC2b0f9566b463BaBe6Fb0270Ad9Ec395);
        _paymentSplitter = PaymentSplitter(0xAFde32E520222C8163e9ed162167759bAE585122);
        price = 0.02 ether;
        discount = 0.01 ether;
        _splitterId = splitterId;
    }

    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_HEADERS, "sold out");
        require(msg.value >= price.mul(quantity), "ether value sent is below the price");
        
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }
    
    function mintDiscount() public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(discountAvailable(), "discount not available");
        require(msg.value >= price - discount, "ether value sent is below the price");
        uint index = totalSupply();    
        require(index <= MAX_HEADERS, "sold out");

        usedDiscounts[msg.sender] = true;
        
        _safeMint(msg.sender, index);
    }
    
    function giftMint(uint quantity, address receiver) public onlyAdmin {
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= MAX_HEADERS, "sold out");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }

    function tokensOfOwner(address _owner) public view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function discountAvailable() public view returns (bool) {
        bool hasWolvesOrPups = _wolfPupsContract.balanceOf(msg.sender) > 0 || _wolfGangContract.balanceOf(msg.sender) > 0;
        return hasWolvesOrPups && usedDiscounts[msg.sender] == false;
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
    }
    
    function setDiscount(uint _discount) public onlyAdmin {
        discount = _discount;
    }
    
    function startSale() public onlyAdmin {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyAdmin {
        hasSaleStarted = false;
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public virtual onlyAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, account);
    }
    
    function withdraw(uint amount) public onlyAdmin {
        require(amount <= address(this).balance, "not enouth ether in balance");
        require(payable(_cOwner).send(amount));
    }

    function setSplitterId(uint __splitterId) public onlyAdmin {
        _splitterId = __splitterId;
    }

    function withdrawAll() public payable onlyAdmin {
        _paymentSplitter.pay{value: address(this).balance}(_splitterId);
    }
}