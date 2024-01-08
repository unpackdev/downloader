pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";

contract RedlionSubscriptions is Context, Ownable, ERC721Enumerable {

    enum SubType {Silver, Gold, Red }
    struct WeeklyAllowance {
        uint64 red;
        uint64 gold;
        uint64 silver;
    }
    event BoughtSilver(uint indexed tokenId);
    event BoughtGold(uint indexed tokenId);
    event BoughtRed(uint indexed tokenId);

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    string private _baseTokenURI;

    WeeklyAllowance public weeklyAllowance;
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

    function setWeeklyAllowance(uint64 red, uint64 gold, uint64 silver) onlyOwner public {
        weeklyAllowance = WeeklyAllowance({red:red, gold:gold, silver:silver});
    }

    function ownerMint(address to, SubType subType) onlyOwner public {
        uint duration = 13 weeks;
        if (subType == SubType.Red) {
            duration = 52 weeks;
        } else if (subType == SubType.Gold) {
            duration = 26 weeks;
        }
        mint(to, duration, subType);
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

    function mint(address to, uint duration, SubType subType) internal returns (uint) {
        uint tokenId = _tokenIdTracker.current();
        _safeMint(to, tokenId);
        expirations[tokenId] = block.timestamp + duration;
        _typeOfTokenId[tokenId] = subType;
        _tokenIdTracker.increment();
        return tokenId;
    }

    function buyRed() public payable {
        require(msg.value == RED_PRICE, "BUY_RED:PRICE INCORRECT");
        require(weeklyAllowance.red > 0, "BUY_RED:SOLD OUT");
        weeklyAllowance.red--;
        uint tokenId = mint(msg.sender, 52 weeks, SubType.Red);
        emit BoughtRed(tokenId);
    }

    function buyGold() public payable {
        require(msg.value == GOLD_PRICE, "BUY_GOLD:PRICE INCORRECT");
        require(weeklyAllowance.gold > 0, "BUY_GOLD:SOLD OUT");
        weeklyAllowance.gold--;
        uint tokenId = mint(msg.sender, 26 weeks, SubType.Gold);
        emit BoughtGold(tokenId);
    }

    function buySilver() public payable {
        require(msg.value == SILVER_PRICE, "BUY_SILVER:PRICE INCORRECT");
        require(weeklyAllowance.silver > 0, "BUY_SILVER:SOLD OUT");
        weeklyAllowance.silver--;
        uint tokenId = mint(msg.sender, 13 weeks, SubType.Silver);
        emit BoughtSilver(tokenId);
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