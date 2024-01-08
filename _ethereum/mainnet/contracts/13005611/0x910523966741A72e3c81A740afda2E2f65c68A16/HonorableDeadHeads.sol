// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./AccessControl.sol";

contract HonorableDeadHeads is ERC721, AccessControl {
    using SafeMath for uint;

    uint public maxSupply;
    uint public price;
    bool public hasSaleStarted = false;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }

    constructor(string memory baseURI, uint _price, uint _maxSupply) ERC721("Honorable DeadHeads", "HONORABLEDEAD") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
        price = _price;
        maxSupply = _maxSupply;
    }

    function mint(uint quantity) public payable {
        mint(quantity, msg.sender);
    }
    
    function mint(uint quantity, address receiver) public payable {
        require(hasSaleStarted || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= maxSupply, "sold out");
        require(msg.value >= price.mul(quantity) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ether value sent is below the price");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(receiver, totalSupply());
        }
    }

    function burn(uint id) external {
        require(ownerOf(id) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _burn(id);
    }

    function mintBatch(address[] memory receivers, uint[] memory quantities) public onlyAdmin {
        require(receivers.length == quantities.length, "receivers and quantities must be of the same length");

        for (uint index = 0; index < receivers.length; index++) {
            for (uint i = 0; i < quantities[index]; i++) {
                _safeMint(receivers[index], totalSupply());
            }
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

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }

    function setMaxSupply(uint _maxSupply) public onlyAdmin {
        maxSupply = _maxSupply;
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
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
        require(payable(msg.sender).send(amount));
    }
    
    function withdrawAll() public onlyAdmin {
        withdraw(address(this).balance);
    }
}