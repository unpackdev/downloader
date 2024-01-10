// SPDX-License-Identifier: MIT
// Contract written by @KfishNFT
// Makes use of ERC721A created by Chiru Labs https://ERC721A.org
// Modified PR for ERC721AUpgradeable by https://github.com/naomsa
// Thanks Chiru Labs & naomsa for improving the space :)

pragma solidity ^0.8.11;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./StringsUpgradeable.sol";


contract Bibiz is
    Initializable,
    ERC721AUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    bool public saleActive;
    bool public revealed;

    uint256 public price;
    uint256 public maxPerTx;
    uint256 public maxPerAddress;
    uint256 public totalReserved;
    uint256 public reservedMinted;

    string public baseURI;
    string public unrevealedURI;

    uint256 public constant SUPPLY_LIMIT = 6969;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory unrevealedURI_
    ) public initializer {
        __ERC721A_init(name_, symbol_);
        __Ownable_init();
        __ReentrancyGuard_init();
        saleActive = false;
        price = 0.079 ether;
        maxPerAddress = maxPerTx = 3;
        totalReserved = 120;
        unrevealedURI = unrevealedURI_;
    }

    function mint(uint256 quantity) external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Only EoA");
        require(saleActive, "SALE IS NOT ACTIVE");
        require(quantity > 0, "QUANTITY MUST BE GREATER THAN ZERO");
        require(quantity <= maxPerTx, "QUANTITY EXCEEDS MAXIMUM PER TX");
        require(_numberMinted(msg.sender) + quantity <= maxPerAddress, "ADDRESS MAXIMUM REACHED");
        require(
            (_totalMinted() + quantity) <= (SUPPLY_LIMIT - totalReserved + reservedMinted),
            "MINT WOULD EXCEED SUPPLY LIMIT"
        );
        require(msg.value == (quantity * price), "ETHER AMOUNT INCORRECT");
        _safeMint(msg.sender, quantity);
    }

    /*
        Owner Functions
    */

    function mintReserved(uint256 quantity, address to) external onlyOwner {
        require(quantity + reservedMinted <= totalReserved, "QUANTITY EXCEEDS RESERVED AMONUT");
        require(_totalMinted() + quantity <= SUPPLY_LIMIT, "MINT WOULD EXCEED SUPPLY LIMIT");
        reservedMinted += quantity;
        _safeMint(to, quantity);
    }

    function setSaleActive(bool _saleActive) external onlyOwner {
        saleActive = _saleActive;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setTotalReserved(uint256 _totalReserved) external onlyOwner {
        totalReserved = _totalReserved;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function reveal() external onlyOwner {
        require(bytes(baseURI).length > 0, "MUST SET BASEURI FRIST");
        require(!revealed, "ALREADY REVEALED");
        revealed = !revealed;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    /*
        ERC721A Overrides
    */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(revealed) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), ".json")) : "";
        } else {
            return bytes(unrevealedURI).length != 0 ? unrevealedURI : "";
        }
    }
}
