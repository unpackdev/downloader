// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SnobietyPeacocks is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 8888;

    string public _provenanceHash;
    string public _baseURL;
    bool public _presaleStarted = false;
    bool public _publicSaleStarted = false;
    uint public constant MAX_NFT_PURCHASE_PRESALE = 2;
    uint public constant MAX_NFT_PURCHASE = 15;

    constructor() ERC721("SnobietyPeacocks", "SPCKS") {}

    function mint(uint256 count) external payable {
        require(_publicSaleStarted, "Sales not active at the moment");
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        require(_tokenIds.current() + count <= _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= MAX_NFT_PURCHASE, "You can mint between 1 and 10 at once");
        require(msg.value >= count * 0.04 ether, "Insufficient payment");
        
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }


    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

function togglePresale () public onlyOwner {
    _presaleStarted = !_presaleStarted;
}

function togglePublicSale () public onlyOwner {
    _publicSaleStarted = !_publicSaleStarted;
}
        function mintPresale(uint256 count) public payable {
        require(_presaleStarted, "Presale is not active at the moment");
        require(count > 0 , "You can only mint more than 1 token.");
        require(msg.value >= count * 0.028 ether, "Insufficient payment"); 
        require(balanceOf(msg.sender) + count <= MAX_NFT_PURCHASE_PRESALE, "Exceeds Presale limit of 2");
        for (uint i = 0; i < count; i++) {
           _tokenIds.increment();
           _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

   function reserve(uint256 count) public onlyOwner {
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        require(count > 0 , "You can one reserve more than one token");
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(owner(), _tokenIds.current());
        }
    }
}

