// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.2
// Chiru Labs ERC721A v3.0.0

/****************************************************************************
    Genesis Wiggles NFT Collection

    Written by Oliver Straszynski
    https://github.com/broliver12/
****************************************************************************/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract GenesisWiggles is Ownable, ERC721A, ReentrancyGuard {
    // Control params
    bool private revealed;
    string private baseURI;
    string private notRevealedURI;
    string private baseExtension = '.json';
    bool public freeWhitelistEnabled;
    bool public paidWhitelistEnabled;
    bool public publicMintEnabled;

    // Mint Limits & Collection Size
    uint256 public immutable unitPrice;
    uint256 public immutable maxMintsOg;
    uint256 public immutable maxMintsWhitelist;
    uint256 public immutable maxMints;
    uint256 public immutable devSupply;
    uint256 public immutable totalCollectionSize;

    // List of OG wallets, slot count
    mapping(address => uint256) public freeWhitelist;
    // List of whitelist wallets, slot count
    mapping(address => uint256) public paidWhitelist;
    // TOTAL supply for devs, marketing, friends, family
    uint256 private remainingDevSupply = 55;

    // Constructor
    constructor() ERC721A('WiggleWorld', 'WIGGLE') {
        // Set collection size
        totalCollectionSize = 5555;
        // Make dev supply immutable and public
        devSupply = remainingDevSupply;
        // Set price
        unitPrice = 0.04 ether;
        // Max 2 mints / wallet during OG sale
        maxMintsOg = 2;
        // Max 7 mints / wallet during WL sale
        maxMintsWhitelist = 3;
        // Any single wallet can only mint 20 NFTs total!
        // This includes giveaways, OG, WL, and publicly minted tokens
        maxMints = 20;
    }

    // Ensure caller is a wallet
    modifier isWallet() {
        require(tx.origin == msg.sender, 'Cant be a contract');
        _;
    }

    // Ensure there's enough supply to mint the quantity
    modifier enoughSupply(uint256 quantity) {
        require(totalSupply() + quantity <= totalCollectionSize, 'reached max supply');
        _;
    }

    // Mint function for OG sale
    // Mints a maximum of 2 NFTs to the caller
    // Caller MUST be OG-Whitelisted to use this function!
    function freeWhitelistMint() external isWallet enoughSupply(maxMintsOg) {
        require(freeWhitelistEnabled, 'OG sale not enabled');
        require(freeWhitelist[msg.sender] >= maxMintsOg, 'Not a wiggle world OG');
        freeWhitelist[msg.sender] = freeWhitelist[msg.sender] - maxMintsOg;
        _safeMint(msg.sender, maxMintsOg);
    }

    // Mint function for whitelist sale
    // Requires minimum ETH value of unitPrice * quantity
    // Mints a maximum of 7 NFTs to the caller
    // Caller MUST be whitelisted to use this function!
    function paidWhitelistMint(uint256 quantity) external payable isWallet enoughSupply(quantity) {
        require(paidWhitelistEnabled, 'Whitelist sale not enabled');
        require(quantity <= maxMintsWhitelist, 'Cant mint that many (WL)');
        require(paidWhitelist[msg.sender] >= quantity, 'No whitelist mints left');
        require(msg.value >= quantity * unitPrice, 'Not enough ETH');
        paidWhitelist[msg.sender] = paidWhitelist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * unitPrice);
    }

    // Mint function for public sale
    // Requires minimum ETH value of unitPrice * quantity
    // Mints a maximum of 20 NFTs to the caller
    // Any already minted NFTs are subtracted from this total
    function publicMint(uint256 quantity) external payable isWallet enoughSupply(quantity) {
        require(publicMintEnabled, 'Minting not enabled');
        require(quantity <= maxMints, 'Illegal quantity');
        require(numberMinted(msg.sender) + quantity <= maxMints, 'Cant mint that many');
        require(msg.value >= quantity * unitPrice, 'Not enough ETH');

        _safeMint(msg.sender, quantity);
        refundIfOver(quantity * unitPrice);
    }

    // Mint function for developers (owner)
    // Mints a maximum of 20 NFTs to the recipient
    // Used for devs, marketing, friends, family
    // Capped at 55 mints total
    function devMint(uint256 quantity, address recipient)
        external
        onlyOwner
        enoughSupply(quantity)
    {
        require(quantity <= remainingDevSupply, 'Not enough dev supply');
        require(quantity <= maxMints, 'Illegal quantity');
        require(numberMinted(recipient) + quantity <= maxMints, 'Cant mint that many (dev)');
        remainingDevSupply = remainingDevSupply - quantity;
        _safeMint(recipient, quantity);
    }

    // Returns the correct URI for the given tokenId based on contract state
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'Nonexistent token');
        if (revealed == false || compareStrings(baseURI, '') == true) {
            return notRevealedURI;
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension))
                : '';
    }

    // Change base metadata URI
    // Only will be called if something fatal happens to initial base URI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // Only will be called if something fatal happens to initial base URI
    function setBaseExtension(string calldata _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    // Sets URI for pre-reveal art metadata
    function setNotRevealedURI(string calldata _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    // Set the mint state
    function setMintState(uint256 _state) external onlyOwner {
        if (_state == 1) {
            freeWhitelistEnabled = true;
        } else if (_state == 2) {
            paidWhitelistEnabled = true;
        } else if (_state == 3) {
            publicMintEnabled = true;
        } else {
            freeWhitelistEnabled = false;
            paidWhitelistEnabled = false;
            publicMintEnabled = false;
        }
    }

    // Set revealed to true (displays baseURI instead of notRevealedURI on opensea)
    function reveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    // Seed the appropriate whitelist
    function setWhitelist(address[] calldata addrs, bool isOG) external onlyOwner {
        if (isOG) {
            for (uint256 i = 0; i < addrs.length; i++) {
                freeWhitelist[addrs[i]] = maxMintsOg;
            }
        } else {
            for (uint256 i = 0; i < addrs.length; i++) {
                paidWhitelist[addrs[i]] = maxMintsWhitelist;
            }
        }
    }

    // Returns the amount the address has minted
    function numberMinted(address minterAddr) public view returns (uint256) {
        return _numberMinted(minterAddr);
    }

    // Returns the ownership data for the given tokenId
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    // Withdraw entire contract value to owners wallet
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Withdraw failed');
    }

    // Refunds extra ETH if minter sends too much
    function refundIfOver(uint256 price) private {
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // Internal helper function that compares 2 strings
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
