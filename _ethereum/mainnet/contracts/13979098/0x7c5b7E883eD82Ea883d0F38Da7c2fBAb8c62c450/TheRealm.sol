// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Counters.sol";
import "./ECDSA.sol";

/*
    ███        ▄█    █▄       ▄████████         ▄████████    ▄████████    ▄████████  ▄█         ▄▄▄▄███▄▄▄▄   
▀█████████▄   ███    ███     ███    ███        ███    ███   ███    ███   ███    ███ ███       ▄██▀▀▀███▀▀▀██▄ 
   ▀███▀▀██   ███    ███     ███    █▀         ███    ███   ███    █▀    ███    ███ ███       ███   ███   ███ 
    ███   ▀  ▄███▄▄▄▄███▄▄  ▄███▄▄▄           ▄███▄▄▄▄██▀  ▄███▄▄▄       ███    ███ ███       ███   ███   ███ 
    ███     ▀▀███▀▀▀▀███▀  ▀▀███▀▀▀          ▀▀███▀▀▀▀▀   ▀▀███▀▀▀     ▀███████████ ███       ███   ███   ███ 
    ███       ███    ███     ███    █▄       ▀███████████   ███    █▄    ███    ███ ███       ███   ███   ███ 
    ███       ███    ███     ███    ███        ███    ███   ███    ███   ███    ███ ███▌    ▄ ███   ███   ███ 
   ▄████▀     ███    █▀      ██████████        ███    ███   ██████████   ███    █▀  █████▄▄██  ▀█   ███   █▀  
                                               ███    ███                           ▀                         

I see you nerd! ⌐⊙_⊙
*/

contract TheRealm is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;
    uint256 public constant AUCTION_REFUND_THRESHOLD = 0.005 ether;

    uint256 public mintPrice = 0.2 ether;

    uint256 public maxPresaleMintsPerWallet = 3;

    bool public preSaleIsActive = false;

    bool public auctionIsActive = false;

    // Auction parameters
    uint256 public auctionDuration;
    uint256 public auctionStartPrice;
    uint256 public auctionStartTime;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    mapping (address => uint256) private _presaleMints;

    address[6] private _shareholders;

    uint[6] private _shares;

    // Used to validate authorized mint addresses
    address private _signerAddress = 0x9da855aE60135e2e81e73162f3ec071704CB9575;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxNFTs) ERC721(name, symbol) {
        maxTokenSupply = maxNFTs;

        _shareholders[0] = 0xDB67f2fD397a8C1EfDC290E9fC51f5945f94D8C2;
        _shareholders[1] = 0xB39bdD62A07032366d2CDbd0107fC9fDBaa1b852;
        _shareholders[2] = 0xEE2098Df368D4e564587fDEdB58dE2BDAd4017B8;
        _shareholders[3] = 0x57C2a3A08fE8B36a169f34CABdF836087bBeB5aD;
        _shareholders[4] = 0x11C72B94C3F7F8BfF28CDefEaAA770a95e5eD128;
        _shareholders[5] = 0x5d4365564f5a72CB8626d2D7ed7d48Ce6F00484a;

        _shares[0] = 3125;
        _shares[1] = 3125;
        _shares[2] = 2500;
        _shares[3] = 1000;
        _shares[4] = 150;
        _shares[5] = 100;
    }

    function setMaxTokenSupply(uint256 maxNFTs) public onlyOwner {
        maxTokenSupply = maxNFTs;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    modifier whenAuctionActive() {
        require(auctionIsActive, "Auction not live");
        _;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 6; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function hashAddress(address senderAddress) public pure returns (bytes32) {
        return keccak256(abi.encode(
            senderAddress
        ));
    }

    function startAuction(uint256 duration, uint256 startPrice) external onlyOwner {
        require(! auctionIsActive, "Auction already active");
        auctionDuration = duration; // in seconds
        auctionStartPrice = startPrice;
        auctionStartTime = block.timestamp;
        auctionIsActive = true;
    }

    function pauseAuction() external onlyOwner whenAuctionActive {
        auctionIsActive = false;
    }

    /*
    * Mint The Realm NFTs during the pre-sale
    */
    function presaleMint(uint256 numberOfTokens, bytes memory signature) external payable {
        require(preSaleIsActive, "Pre-sale not live");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Max limit exceeded");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Max supply reached");
        require(mintPrice * numberOfTokens <= msg.value, "Incorrect ether value");
        require(_signerAddress == hashAddress(msg.sender).toEthSignedMessageHash().recover(signature), "Invalid signature");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Mint The Realm NFTs during the dutch auction
    */
    function auctionMint(uint256 numberOfTokens) external payable whenAuctionActive nonReentrant {
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Max supply reached");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "Exceeds max mints");

        uint256 totalMintPrice = getMintPrice() * numberOfTokens;
        require(totalMintPrice <= msg.value, "Incorrect ether value");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }

        if (msg.value > (totalMintPrice + AUCTION_REFUND_THRESHOLD)) {
            // If the refund amount is less than the threshold, it is not worth the gas to refund.
            Address.sendValue(payable(msg.sender), msg.value - totalMintPrice);
        }
    }

    function getMintPrice() public view returns (uint256) {
        uint256 elapsed = auctionStartTime > 0 ? block.timestamp - auctionStartTime : 0;
        if (elapsed >= auctionDuration) {
            return mintPrice;
        } else {
            uint256 currentPrice = ((auctionDuration - elapsed) * (auctionStartPrice - mintPrice)) / auctionDuration + mintPrice;
            return currentPrice;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
