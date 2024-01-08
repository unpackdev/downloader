pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract RedlionSubscriptions is Context, Ownable, ERC721Enumerable {

    enum SubType {Silver, Gold, Red }
    event BoughtSilver(uint indexed tokenId);
    event BoughtGold(uint indexed tokenId);
    event BoughtRed(uint indexed tokenId);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    uint public RED_PRICE = 2.35 ether;
    uint public GOLD_PRICE = 1.2 ether;
    uint public SILVER_PRICE = 0.6 ether;
    uint public currentIssue;

    mapping (uint => uint) public expirations;
    mapping (uint => SubType) private _typeOfTokenId;

    constructor(
        string memory name,
        string memory symbol, 
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }


    /*
        ADMIN FUNCTIONS
    */

    function changeBaseURI(string memory baseTokenURI) onlyOwner public {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw() onlyOwner public {
        uint amount = address(this).balance;
        payable(owner()).transfer(amount);
    }
    
    function setRedPrice(uint newPrice) onlyOwner public {
        RED_PRICE = newPrice;
    }
    function setGoldPrice(uint newPrice) onlyOwner public {
        GOLD_PRICE = newPrice;
    }
    function setSilverPrice(uint newPrice) onlyOwner public {
        SILVER_PRICE = newPrice;
    }
    function setCurrentIssue(uint issue) onlyOwner public {
        currentIssue = issue;
    }


    /*
        PUBLIC FUNCTIONS
    */

    function isExpired(uint tokenId) public view returns (bool) {
        return expirations[tokenId] < block.timestamp;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function buyRed() public payable {
        require(msg.value == RED_PRICE, "BUY_RED:PRICE INCORRECT");
        _safeMint(_msgSender(), _tokenIdTracker.current());
        expirations[_tokenIdTracker.current()] = block.timestamp + 52 weeks;
        _typeOfTokenId[_tokenIdTracker.current()] = SubType.Red;
        emit BoughtRed(_tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function buyGold() public payable {
        require(msg.value == GOLD_PRICE, "BUY_RED:PRICE INCORRECT");
        _safeMint(_msgSender(), _tokenIdTracker.current());
        expirations[_tokenIdTracker.current()] = block.timestamp + 26 weeks;
        _typeOfTokenId[_tokenIdTracker.current()] = SubType.Gold;
        emit BoughtGold(_tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function buySilver() public payable {
        require(msg.value == SILVER_PRICE, "BUY_RED:PRICE INCORRECT");
        _safeMint(_msgSender(), _tokenIdTracker.current());
        expirations[_tokenIdTracker.current()] = block.timestamp + 13 weeks;
        _typeOfTokenId[_tokenIdTracker.current()] = SubType.Silver;
        emit BoughtSilver(_tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function whichType(uint tokenId) public view returns (uint) {
        return uint(_typeOfTokenId[tokenId]);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}