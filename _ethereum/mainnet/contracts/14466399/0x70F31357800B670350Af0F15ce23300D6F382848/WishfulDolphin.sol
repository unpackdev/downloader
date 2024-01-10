// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Tradable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract WishfulDolphin is ERC721Tradable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    enum salesRound { Wait, First, Second, Third, Fourth }
    enum salesStatus { Pause, Sold, Progress }
    enum salesType { General, Whitelist }

    salesRound private currentSalesRound = salesRound.Wait;
    salesStatus private currentSalesStatus = salesStatus.Pause;
    salesType private currentSalesType = salesType.General;

    string private baseURI;
    uint256 public immutable maxSupply;
    uint256 public immutable reservedSupply;
    uint256 public immutable maxAllowedMints;
    uint256 public maxWhiteListMints = 5;
    uint256 private constant _numTier = 4;
    uint256 public currentMaxSupply; 
    bool public onPromo = false;
    uint256 public promoPrice = 0.02 ether;
    uint256 public reservedMinted;
    mapping (address => uint256) public totalMints;
    address private _signer = 0x47ED4eE4021d3CF5e6582ceF3e6756D1b88efB6e;  

    constructor(
        string memory bURI, 
        address _proxyRegistryAddress,
        uint256 maxSupply_,
        uint256 reservedSupply_,
        uint256 maxAllowedMints_
    ) ERC721Tradable("Wishful Dolphin", "WFD", _proxyRegistryAddress) {
        require(maxSupply_ % _numTier == 0, "maxSupply must be divisible by numTier");
        baseURI = bURI;
        maxSupply = maxSupply_;
        reservedSupply = reservedSupply_;
        maxAllowedMints = maxAllowedMints_;
        currentMaxSupply = maxSupply / _numTier;
    }

    function baseTokenURI() override public view returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string calldata bURI) external onlyOwner {
        baseURI = bURI;
    }

    modifier isSaleOpen {
        require(totalSupply() < maxSupply, "Sorry, All Wishful Dolphins are sold.");
        _;
    }

    function updateSales(uint8 sRound, uint8 sStatus, uint8 sType) external onlyOwner {
        currentSalesRound = salesRound(sRound);
        currentSalesStatus = salesStatus(sStatus);
        currentSalesType = salesType(sType);
    }

    function updateCurrentMaxSupply(uint256 currentMax) external onlyOwner {
        currentMaxSupply = currentMax;
    }

    function updateMaxWhiteListMints(uint256 amount) external onlyOwner {
        maxWhiteListMints = amount;
    }

    function updatePromotion(bool enablePromo, uint256 price) external onlyOwner {
        onPromo = enablePromo;
        promoPrice = price;
    }

    function _nextTokenId() private view returns (uint256) {
        return totalSupply() + 1;
    }

    function mintNFT(
            bytes32 messageHash,
            bytes calldata signature,
            uint256 numTokens) external payable nonReentrant isSaleOpen {
        require( currentSalesRound > salesRound.Wait, "Whitelist Sales has not begun yet.");
        require( currentSalesType == salesType.Whitelist, "Whitelist sales is not available at the moment.");
        require( currentSalesStatus > salesStatus.Sold, "Whitelist sales is not active at the moment.");
        require( hashMessage(msg.sender) == messageHash, "Invalid Message");
        require( messageSigner(messageHash, signature) == _signer, "Signat?ure validation failed");    
        require( totalSupply() + numTokens <= currentMaxSupply, "Exceeds current maximum NFT supply.");
        require( totalSupply() + numTokens <= maxSupply, "Exceeds maximum NFT supply.");
        require( numTokens > 0 && numTokens <= maxWhiteListMints, "Invalid mint amount");
        require( totalMints[msg.sender] + numTokens <= maxWhiteListMints, "Address exceeds max whitelist allowed mints.");
        require( currentPrice().mul(numTokens) == msg.value, "Incorrect ether value sent. Please check again.");
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _nextTokenId());
            totalMints[msg.sender]++;
        }
        updateSalesStatus();
    }

    function mintNFT(uint256 numTokens) external payable nonReentrant isSaleOpen {
        require( currentSalesRound > salesRound.Wait, "Public Sales has not begun yet.");
        require( currentSalesType == salesType.General, "Public sales is not available at the moment");
        require( currentSalesStatus > salesStatus.Sold, "Public sales is not active at the moment.");
        require( totalSupply() + numTokens <= currentMaxSupply, "Exceeds current maximum NFT supply.");
        require( totalSupply() + numTokens <= maxSupply, "Exceeds maximum NFT supply.");
        require( numTokens > 0 && numTokens <= 10, "Invalid mint amount");
        require( totalMints[msg.sender] + numTokens <= maxAllowedMints, "Address exceeds max allowed mints.");
        require( currentPrice().mul(numTokens) == msg.value, "Incorrect ether value sent. Please check again.");
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _nextTokenId());
            totalMints[msg.sender]++;
        }
        updateSalesStatus();
    }

    function mintReservedNFT(address[] calldata recipients, uint256 numTokens) external onlyOwner isSaleOpen {
        require( numTokens > 0, "numTokens should be 1 or greater.");
        require( totalSupply() + recipients.length * numTokens <= maxSupply, "Exceeds maximum NFT supply.");
        require( reservedMinted + recipients.length * numTokens <= reservedSupply, "Exceeds maximum reserved supply.");
        for (uint256 i = 0; i < recipients.length; i++) {
            for (uint256 j = 0; j < numTokens; j++) {
                _safeMint(recipients[i], _nextTokenId());
                reservedMinted++;
            }
        }
        updateSalesStatus();
    }

    function contractStatus() public view returns (uint256, uint256, uint256, salesRound, salesStatus, salesType ) {
        return (totalSupply(), currentPrice(), currentMaxSupply, currentSalesRound, currentSalesStatus, currentSalesType);
    }

    function currentPrice() public view returns (uint256) {
        if ( onPromo ) {
            return promoPrice;
        }
        uint256 pricePerToken = 0.02 ether;
        if ( currentSalesRound == salesRound.First ) {
            pricePerToken = 0.02 ether;
        } else if ( currentSalesRound == salesRound.Second ) {
            pricePerToken = 0.04 ether;
        } else if ( currentSalesRound == salesRound.Third ) {
            pricePerToken = 0.06 ether;
        } else if ( currentSalesRound == salesRound.Fourth ) {
            pricePerToken = 0.08 ether;
        }
        return pricePerToken;
    }

    function updateSalesStatus() private {
        if ( totalSupply() >= currentMaxSupply ) {
            currentMaxSupply += maxSupply / _numTier;
            currentMaxSupply = (currentMaxSupply > maxSupply? maxSupply : currentMaxSupply);
            currentSalesStatus = salesStatus.Sold;
        }
    }

    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(amount <= balance, "The amount exceeds your balance");
        payable(owner()).transfer(amount);
    }

    function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function messageSigner(bytes32 messageHash, bytes memory signature) private pure returns (address) {
        return messageHash.toEthSignedMessageHash().recover(signature);
    }

    function updateSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0));
        _signer = newSigner;
    }

}