// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Address.sol";

contract ERC721Subdivision is ERC721, Ownable, IERC2981, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter private _tokenIdTracker;

    address payable public artist;
    address payable[] private _executive;
    uint256 public closingTime; // 2022-08-01 UnitTime(seconds) 1659285295
    uint256 public basePrice;
    string public baseURI;
    string public baseSuffix;
    uint256 public royalty;

    string public contractURI;
    bool private _isWithdrawn;

    mapping(address => BidInfo) private _bidInfoMap;

    struct BidInfo {
        uint256 totalBidValue;
        uint256 totalBidAmount;
        bool isRefunded;
    }

    event Refund(address indexed customer, uint value);
    event Withdrawal(uint when);
    event WithdrawalAll(uint when);
    // event PermanentURI(string _value, uint256 indexed _id); // For Opensea (Freezing Metadata)

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address payable artist_,
        address payable[] memory executive_,
        uint256 basePrice_,
        uint256 royalty_,
        uint256 closingTime_
    ) ERC721(name, symbol) {
        baseURI = baseURI_;
        contractURI = baseURI_;
        basePrice = basePrice_;
        closingTime = closingTime_;
        artist = artist_;
        royalty = royalty_;
        _executive = executive_;
    }

    modifier hasClosed(bool closed) {
        require(closed ? block.timestamp > closingTime : block.timestamp < closingTime);
        _;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function setClosingTime(uint256 newClosingTime) external onlyOwner {
        closingTime = newClosingTime;
    }

    function buy() external payable hasClosed(false) nonReentrant {
        require(msg.value >= (basePrice / (_tokenIdTracker.current() + 1)), "Incorrect value");
        _tokenIdTracker.increment();
        _bidInfoMap[msg.sender].totalBidAmount++;
        _bidInfoMap[msg.sender].totalBidValue += msg.value;
        _safeMint(msg.sender, _tokenIdTracker.current());
    }

    function refund() external hasClosed(true) nonReentrant {
        require(!_bidInfoMap[msg.sender].isRefunded, "You has been refunded");
        require(_tokenIdTracker.current() > 0, "Require minted");
        _bidInfoMap[msg.sender].isRefunded = true;
        uint refundValue = _bidInfoMap[msg.sender].totalBidValue - (_bidInfoMap[msg.sender].totalBidAmount * (basePrice / _tokenIdTracker.current()));
        Address.sendValue(payable(msg.sender), refundValue);
        emit Refund(msg.sender, refundValue);
    }

    function withdraw() external onlyOwner hasClosed(true) nonReentrant {
        require(!_isWithdrawn, "Already withdrawn");
        require(_tokenIdTracker.current() > 0, "Require minted");
        _isWithdrawn = true;
        uint fee = (basePrice * 3331) / 10000;
        Address.sendValue(artist, basePrice - fee);
        for (uint i = 0; i < _executive.length; i++) {
            Address.sendValue(_executive[i], fee / _executive.length);
        }
        emit Withdrawal(block.timestamp);
    }

    function withdrawAll() external onlyOwner hasClosed(true) nonReentrant {
        require(_tokenIdTracker.current() > 0, "Require minted");
        Address.sendValue(payable(msg.sender), address(this).balance);
        emit WithdrawalAll(block.timestamp);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseSuffix));
    }

    function setBase(string calldata uri, string calldata suffix) external onlyOwner {
        baseURI = uri;
        baseSuffix = suffix;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;
    }

    function royaltyInfo(uint256 tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (artist, (_salePrice * royalty) / 100);
    }
}
