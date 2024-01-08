// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

/*
Stack Floors to earn more $RENT.                              
*/
contract StackedFloors is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // mint event 
    event Mint(address indexed sender, uint256 startWith, uint256 times);

    //uints 
    uint256 public totalFloors;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 10;
    //price
    uint256 public price = 5000000000000000; // 0.05 eth

    //baseURI String
    string public baseURI;

    //bool
    bool private started;

    //constructor args 
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    //view functions 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    //tokenURI functions 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }

    //start the sale 
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }


    // view function for how many /which tokens an address has. 
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    //mint
    function mint(uint256 _times) payable public {
        require(started, "not started");
        require(_times >0 && _times <= maxBatch, "Too many floors!! Don't be a bad landlord.");
        require(totalFloors + _times <= totalCount, "Too many at once.");
        require(msg.value == _times * price, "value error");
        payable(owner()).transfer(msg.value);
        emit Mint(_msgSender(), totalFloors+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalFloors++);
        }
    }  
}