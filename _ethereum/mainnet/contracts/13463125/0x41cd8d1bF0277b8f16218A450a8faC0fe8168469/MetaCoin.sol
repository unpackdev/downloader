// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract ShamDAO is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintToken(address indexed sender, uint256 startWith, uint256 times);

    //supply counters 
    uint256 public totalTokens;
    uint256 public totalCount = 6969;


    uint256 public maxBatch = 100;
    uint256 public price = 50000000000000000;

    //string
    string public baseURI;

    //bool
    bool private started = true;

    //constructor args 
    constructor(string memory baseURI_) ERC721("ShamDAO", "SHAM") {
        baseURI = baseURI_;
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
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
        require(started, "Not Shams enough yet.");
        require(_times >0 && _times <= maxBatch, "Too many Shams!");
        require(totalTokens + _times <= totalCount, "sold out");
        require(msg.value == _times * price, "Value error, please check price.");
        payable(owner()).transfer(msg.value);
        emit MintToken(_msgSender(), totalTokens+1, _times);
        for(uint256 i=0; i< _times; i++){
            _mint(_msgSender(), 1 + totalTokens++);
        }
    }  
}
