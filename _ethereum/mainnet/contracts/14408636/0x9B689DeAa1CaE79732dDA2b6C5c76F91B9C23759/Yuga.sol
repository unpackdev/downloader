// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "ERC721A.sol";
import "Counters.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "PaymentSplitter.sol";
import "Strings.sol";

contract Yuga is Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;

    uint256 public immutable maxSupply = 3333;
    uint256 public immutable maxFreeSupply = 555;

    uint256 public maxTokensPerTx = 8;

    struct SaleConfig {
        uint32 publicSaleStartTime;
        uint64 price;
    }

    SaleConfig public saleConfig;

    string private _baseTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _tokenURI,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_, maxBatchSize_) PaymentSplitter(payees_, shares_) {
        _safeMint(payees_[0], 1);
        _baseTokenURI = _tokenURI; //instant reveal
        maxTokensPerTx = maxBatchSize_;
    }

    function freeMint(uint256 quantity) external {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(
            publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime,
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
        SaleConfig memory config = saleConfig;
        uint256 price = uint256(config.price);
        require(price != 0, "public sale has not begun yet");
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(
            publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime,
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

    function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    function setPrice(uint64 price) external onlyOwner {
        saleConfig.price = price;
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
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
