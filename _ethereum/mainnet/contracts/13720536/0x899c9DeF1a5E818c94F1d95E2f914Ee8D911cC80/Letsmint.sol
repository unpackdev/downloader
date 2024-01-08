/* SPDX-License-Identifier: Apache */

pragma solidity ^0.8.9;
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract Pausable is Ownable {
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "The contract is paused");
        _;
    }

    modifier whenPaused {
        require(paused, "The contract is not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
    }
}

// ERC1155 because we need to mint similar tokens
contract Letsmint is Pausable, ERC1155  {
    string public name="Letsmint";
    
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint8;
    
    struct Collection {
        bool running;
        bool collected;
        bool refunding;
        
        uint256 price;
        uint256 balance;
        uint16 backers;
        uint256 hardcap;
        address payable owner;

        uint8 percent;
        
        mapping(address => uint8) lucky;
        mapping(address => uint8) universal;
    }
    
    mapping(uint32 => Collection) collections;
    mapping(address => uint32) private burners;
    
    
    uint32 MAX_COLLECTIONS = 65535;
    
    constructor() ERC1155("https://api.letsmint.io/collection/{id}/token"){
    }
    
    // Collection management
    function startCampaign(uint32 collection, address payable owner, uint256 price, uint256 hardcap, uint8 percent) public onlyOwner {
        collections[collection].running = true;
        collections[collection].collected = false;
        collections[collection].refunding = false;
        
        collections[collection].owner = owner;
        collections[collection].hardcap = hardcap;
        collections[collection].price = price;
        
        collections[collection].backers = 0;
        collections[collection].balance = 0;

        collections[collection].percent = percent;
    }

    
    // Collection backing
    function back(uint32 collection, uint8 option) public whenNotPaused payable {
        require(collections[collection].running, "The collection campaign is not running");
        require((option == 1) || (option == 3) || (option == 10), "The support option is not valid");
        require(msg.value == collections[collection].price.mul(option), "Not enough ETH sent"); 
        
        collections[collection].balance = collections[collection].balance.add(collections[collection].price.mul(option));
        collections[collection].backers = collections[collection].backers + 1;
        
        _mint(msg.sender, collection, option, ""); 
        
        if (option >= 3){
            collections[collection].lucky[msg.sender] = uint8(collections[collection].lucky[msg.sender].add(1)); 
        }
        
        if (option == 10){
            collections[collection].universal[msg.sender] = uint8(collections[collection].universal[msg.sender].add(1));
        }
        
        if (collections[collection].balance >= collections[collection].hardcap){
            collections[collection].running = false;
            collections[collection].collected = true;
            
            collections[collection].owner.transfer(collections[collection].balance.mul(100-collections[collection].percent).div(100));
            payable(owner()).transfer(collections[collection].balance.mul(collections[collection].percent).div(100));
        }
    }

    // Refunds 
    function allowRefund(uint32 collection) public onlyOwner {
        collections[collection].running = false;
        collections[collection].refunding = true;
    }

    function claimRefund(uint32 collection, uint number) whenNotPaused public {
        require(collections[collection].refunding, "The refund is not allowed for this collection");
        require(balanceOf(msg.sender, collection) >= number, "You don't have enough tokens");
        
        _burn(msg.sender, collection, number);
        payable(msg.sender).transfer(collections[collection].price.mul(number));
    }

    
    function addBurner(address burner, uint32 collection) public onlyOwner {
        burners[burner] = collection;
    }

    function removeBurner(address burner) public onlyOwner {
        burners[burner] = 0;
    }


    function burn(address addr, uint32 collection, uint number) whenNotPaused public {
        require(burners[msg.sender] == collection, "The burning of these tokens is not allowed");
        _burn(addr, collection, number);
    }
    
    function luckyTokensAvailable(uint32 collection) public view returns (uint8){
        return  collections[collection].lucky[msg.sender];
    }

    function universalTokensAvailable(uint32 collection) public view  returns (uint8) {
        return collections[collection].universal[msg.sender];
    }

    function claimTokens(uint32 collection) whenNotPaused public {
        require(collections[collection].collected, "The collection is not funded yet");
        
        if (collections[collection].lucky[msg.sender] > 0){
            _mint(msg.sender, collection.add(MAX_COLLECTIONS), collections[collection].lucky[msg.sender], ""); 
            collections[collection].lucky[msg.sender] = 0;
        }
        
        if (collections[collection].universal[msg.sender] > 0){
            _mint(msg.sender, MAX_COLLECTIONS, collections[collection].universal[msg.sender], ""); 
            collections[collection].universal[msg.sender] = 0;
        }
    }
    
    // Get functions
    function getCollectedAmount(uint32 collection) public view returns (uint256){
        return collections[collection].balance;
    }
    
    function getBackersNumber(uint32 collection) public view returns (uint256){
        return collections[collection].backers;
    } 

    function isRunning(uint32 collection) public view returns (bool){
        return collections[collection].running;
    } 

    function isCollected(uint32 collection) public view returns (bool){
        return collections[collection].collected;
    } 
    
    function uri(uint256 id) override public pure returns (string memory){
        return string(
                abi.encodePacked(
                        "https://api.letsmint.io/collection/",
                        Strings.toString(id),
                        "/token"
                    )
            );
    }
}

