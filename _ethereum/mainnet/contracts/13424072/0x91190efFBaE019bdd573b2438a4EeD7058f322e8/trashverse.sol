// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract TrashVerse is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintTrash(address indexed sender, uint256 startWith, uint256 times);

    //supply counters 
    uint256 public totalTrash;
    uint256 public totalCount = 8888;


    uint256 public maxBatch = 50;
    uint256 public price = 10000000000000000;

    string public baseURI;

    bool private started;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

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

    function mint(uint256 _times) payable public {
        require(started, "sale not started mf wtf.");
        require(_times >0 && _times <= maxBatch, "Too much trash!");
        require(totalTrash + _times <= totalCount, "sold out");
        require(msg.value == _times * price, "value error, please check price.");
        payable(owner()).transfer(msg.value);
        emit MintTrash(_msgSender(), totalTrash+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalTrash++);
        }
    }  
}