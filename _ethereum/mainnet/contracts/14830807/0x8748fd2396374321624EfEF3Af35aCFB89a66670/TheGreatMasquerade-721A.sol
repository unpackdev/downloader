//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract TheGreatMasquerade is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 4001;
    uint256 public constant MAX_PER_WALLET = 10;
    uint256 public constant MAX_RESERVED_SUPPLY = 200;
    uint256 public constant FINAL_PRICE = 0.08 ether;
    uint256 public constant PUBLIC_PRICE = 0.05 ether;
    uint256 public constant WL_PRICE = 0.035 ether;

    uint32 public constant PLUS_ONE_DEAL_END_TIME = 1653508800; // May 25th 22:00 CET

    bool private isSaleActive = false;
    bool private isFinalPrice = false;
    bool public revealed = false;

    string public notRevealedUri;
    string public baseTokenURI;

    mapping(address => uint256) public allowlist;

    event welcomeToTheGreatMasquerade(uint256 indexed tokenId);

    constructor(string memory _initialBaseURI, string memory _initNotRevealedUri) ERC721A('TheGreatMasquerade', 'TGM') {
        setBaseURI(_initialBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier saleIsOpen() {
        require(totalSupply() <= MAX_SUPPLY, 'Soldout!');
        require(isSaleActive, 'Sale not open');
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    // For promotional purposes
    function devMint(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, 'Quantity cannot be zero');
        uint256 totalMinted = totalSupply();
        require(totalMinted.add(quantity) <= MAX_RESERVED_SUPPLY, 'No more promo NFTs left');
        _safeMint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _baseNotRevealedURI() internal view virtual returns (string memory) {
        return notRevealedUri;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setIsSaleActive(bool _isSaleActive) public onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setIsFinalPrice(bool _isFinalPrice) public onlyOwner {
        isFinalPrice = _isFinalPrice;
    }

    function setReveal(bool _setReveal) public onlyOwner {
        revealed = _setReveal;
    }

    function mint(uint256 _amountOfTokens) public payable callerIsUser saleIsOpen {
        uint256 currentPrice = getHoodiePrice();

        require(totalSupply() + _amountOfTokens <= MAX_SUPPLY, 'Reached Max Supply');
        require(msg.value >= currentPrice.mul(_amountOfTokens), 'Ether value sent is not correct');

        uint256 amonutMintedOfWallet = numberMinted(msg.sender);

        uint256 finalAmountOfTokens = _amountOfTokens;

        if (block.timestamp < PLUS_ONE_DEAL_END_TIME && amonutMintedOfWallet == 0) {
            finalAmountOfTokens += 1;
        }

        require(amonutMintedOfWallet + finalAmountOfTokens <= MAX_PER_WALLET, 'Cannot mint this many');

        if (allowlist[msg.sender] > 0) {
            allowlist[msg.sender] -= finalAmountOfTokens;
        }

        _safeMint(msg.sender, finalAmountOfTokens);
        emit welcomeToTheGreatMasquerade(totalSupply());
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, 'addresses does not match numSlots length');
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function getHoodiePrice() public view returns (uint256) {
        if (isFinalPrice) {
            return FINAL_PRICE;
        } else if (allowlist[msg.sender] > 0) {
            return WL_PRICE;
        } else {
            return PUBLIC_PRICE;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();

        if (revealed == false) {
            currentBaseURI = _baseNotRevealedURI();
        }

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), '.json'))
                : '';
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed.');
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}
