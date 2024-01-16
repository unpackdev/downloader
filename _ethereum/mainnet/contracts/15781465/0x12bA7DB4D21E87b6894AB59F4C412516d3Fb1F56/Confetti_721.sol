    // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol"; 
import "./Address.sol"; 


contract Confetti721 is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using Address for address;

    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant START_TIME = 1665667000;  // TODO 2022-10-20 15:00 UTC
    uint256 public constant AMOUNT_FOR_FREEMINT = 200;
    uint256 public constant AMOUNT_FOR_MARKETING = 100;
    uint256 public constant MAX_PER_ADDRESS_FOR_FREE = 1; 
    uint256 public constant MAX_PER_ADDRESS_FOR_PUBLIC = 3;

    bool public devMinted = false;

    string private _baseTokenURI;

    constructor() ERC721A("Confetti", "CONFETTI") {}

    modifier mintStarted() {
        require(block.timestamp >= START_TIME, "Public sale has not begun yet");
        _;
    }

    function mintPrice() public view returns (uint256 price) {
        price = currentIndex < AMOUNT_FOR_FREEMINT + AMOUNT_FOR_MARKETING ? 0 : 0.1 ether;
    }

    function devMint(address _address) external onlyOwner {
        require(!devMinted, "Already minted");
        require(totalSupply() + AMOUNT_FOR_MARKETING < MAX_SUPPLY, "Over max supply");

        devMinted = true;
        _safeMint(_address, AMOUNT_FOR_MARKETING);
    }

    function mint(uint256 _quantity) external payable mintStarted {
        require(msg.sender == tx.origin, "Only EOA");
        require(totalSupply() + _quantity < MAX_SUPPLY, "Over max supply");
        require(_numberMinted(msg.sender) == 0, "Already minted");

        if (mintPrice() == 0) {
            require(_quantity <= MAX_PER_ADDRESS_FOR_FREE, "Quantity to mint too high");
        } else {
            require(_numberMinted(msg.sender) + _quantity <= MAX_PER_ADDRESS_FOR_PUBLIC, "Quantity to mint too high");
            require(_quantity <= MAX_PER_ADDRESS_FOR_PUBLIC, "Quantity to mint too high");
        }

        _safeMint(msg.sender, _quantity);

        if (currentIndex > AMOUNT_FOR_FREEMINT + AMOUNT_FOR_MARKETING) {
            refundIfOver(mintPrice() * _quantity);
        }
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool _success, ) = msg.sender.call{value: address(this).balance}("");
        require(_success, "Transfer failed");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }
}

