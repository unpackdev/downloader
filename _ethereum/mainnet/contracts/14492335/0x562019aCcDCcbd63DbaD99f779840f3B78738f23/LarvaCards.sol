// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "ERC721A.sol";
import "Counters.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "PaymentSplitter.sol";
import "Strings.sol";

contract LarvaCards is Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    uint256 public immutable maxSupply = 10000;
    uint256 public immutable maxFreeSupply = 500;

    uint256 public maxTokensPerTx = 10;
    uint256 public price = 0.012 ether;
    uint32 public saleStartTime = 1648756800; // THURDAY 31.3 1 PM PST

    bool public revealed;

    string private _baseTokenURI;
    string private notRevealedUri;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_, maxBatchSize_) PaymentSplitter(payees_, shares_) {
        _safeMint(msg.sender, 1);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function freeMint(uint256 quantity) external {
        require(
            saleStartTime != 0 && block.timestamp >= saleStartTime,
            "sale has not started yet"
        );
        require(quantity <= maxTokensPerTx, "sale transaction limit exceeded");
        uint256 remaining = maxFreeSupply - totalSupply();
        require(remaining != 0, "no free mints left");
        if (remaining > quantity) {
            _safeMint(msg.sender, quantity);
        } else {
            _safeMint(msg.sender, remaining);
        }
    }

    function publicSaleMint(uint256 quantity) external payable {
        require(price != 0, "public sale has not begun yet");
        require(
            saleStartTime != 0 && block.timestamp >= saleStartTime,
            "public sale has not started yet"
        );
        require(quantity <= maxTokensPerTx, "sale transaction limit exceeded");
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        require(
            price * quantity <= msg.value,
            "Ether value sent is not correct"
        );
        _safeMint(msg.sender, quantity);
    }

    function airdrop(address _to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        _safeMint(_to, quantity);
    }

    function setPublicSaleStartTime(uint32 _timestamp) external onlyOwner {
        saleStartTime = _timestamp;
    }

    function setPrice(uint64 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTokensPerTx(uint256 _maxTokensPerTx) external onlyOwner {
        maxTokensPerTx = _maxTokensPerTx;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnerOfToken(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
