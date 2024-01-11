// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";

error SaleNotStarted();
error NoFreeMintsLeft();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error NonExistentTokenURI();

contract ElonApeClub is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint256;

    uint256 public immutable maxSupply = 4269;
    uint256 public immutable maxFreeSupply = 420;

    uint256 public maxTokensPerTx = 5;
    uint256 public price = 0.0069 ether;
    uint32 public saleStartTime = 1651896000;

    string private _baseTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _tokenURI,
        uint256 maxBatchSize_,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A(name_, symbol_, maxBatchSize_) PaymentSplitter(payees_, shares_) {
        _safeMint(msg.sender, 1);
        _baseTokenURI = _tokenURI;
    }

    function freeMint(uint256 quantity) external {
        if (saleStartTime == 0 || block.timestamp < saleStartTime)
            revert SaleNotStarted();
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();
        uint256 remaining = maxFreeSupply - totalSupply();
        if (remaining == 0) revert NoFreeMintsLeft();
        if (remaining > quantity) {
            _safeMint(msg.sender, quantity);
        } else {
            _safeMint(msg.sender, remaining);
        }
    }

    function publicSaleMint(uint256 quantity) external payable {
        if (price == 0 || saleStartTime == 0 || block.timestamp < saleStartTime)
            revert SaleNotStarted();
        if (quantity == 0 || quantity > maxTokensPerTx)
            revert QuantityOffLimits();
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
        if (msg.value != price * quantity) revert InsufficientFunds();
        _safeMint(msg.sender, quantity);
    }

    function airdrop(address _to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
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
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}
