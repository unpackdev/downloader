// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GoldHeart is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 5555;
    uint public constant MAX_NFT_PURCHASE = 15;
    uint public constant MAX_NFT_PURCHASE_PRESALE = 5;
    string public _provenanceHash;
    string public _baseURL;
    address[]  beneficiaries;
    bool public _presaleStarted = false;
    bool public _publicSaleStarted = false;
    bool public _paused = false;
    mapping(address => bool) public presaleList;

    

    constructor() ERC721("GoldHeart", "GOLDHEART") {}

    function mint(uint256 count, uint256 index) external payable {
        require(!_paused, "Can't mint while sales paused");
        require(_publicSaleStarted, "Can't mint before public sale");
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= MAX_NFT_PURCHASE, "You can mint between 1 and 10 at once");
        require(msg.value >= count * 0.2 ether, "Insufficient payment");
        
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = payable(beneficiaries[index]).call{value : msg.value /20}("");
        require(success, "Failed to send to beneficiary");
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


    function flipPresaleState() public onlyOwner {
         _presaleStarted = !_presaleStarted;
    }
     function flipPublicSaleState() public onlyOwner {
         _publicSaleStarted = !_publicSaleStarted;
    }

     function flipPausedState() public onlyOwner {
         _paused = !_paused;
    }



    function mintPresale(uint256 count, uint256 index) public payable {
        require(!_paused, "Can't mint while sales paused");
        require(_presaleStarted, "Presale is not active at the moment");
        require(!_publicSaleStarted , "Cannot mint presale with public sale is open");
        require(balanceOf(msg.sender) + count <= MAX_NFT_PURCHASE_PRESALE, "Can't mint more than 10 in presale");
        require(presaleList[msg.sender] == true,"This address is not whitelisted for the presale.");

        require(msg.value >= count * 0.1 ether, "Insufficient payment");
        for (uint i = 0; i < count; i++) {
           _tokenIds.increment();
           _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = payable(beneficiaries[index]).call{value : msg.value/20}("");
        require(success, "Failed to send to beneficiary");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function addToPresaleList(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
          presaleList[addresses[i]] = true;
        }
    }

    function removeFromPresaleList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
          require(addresses[i] != address(0), "Can't add the null address");
          presaleList[addresses[i]] = false;
        }
    }


    function addBeneficiary(address beneficiary) external onlyOwner{
        beneficiaries.push(beneficiary);
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

