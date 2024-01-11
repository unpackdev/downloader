// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";

error SaleNotBegun();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error NoFreeMintsLeft();

contract LofiRobos is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxSupply = 4000;
    uint256 public immutable maxFreeSupply = 250;

    uint256 public maxTokensPerTx = 10;
    uint256 public price = 0.005 ether;
    uint32 public saleStartTime = 1651154400;

    bool public revealed;

    string private _baseTokenURI;
    string private notRevealedUri;

    address private ownerWallet;

    event MintedFree(address from, uint256 remaining);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address ownerWallet_
    ) ERC721A(name_, symbol_, maxBatchSize_) {
        setOwnerWallet(ownerWallet_);
        _safeMint(ownerWallet, 25);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function freeMint(uint256 quantity) external nonReentrant {
        // Validation
        if (saleStartTime == 0 || block.timestamp < saleStartTime) {
            revert SaleNotBegun();
        }
        if (quantity == 0 || quantity > maxTokensPerTx) {
            revert QuantityOffLimits();
        }
        if (totalSupply() >= maxFreeSupply) {
            revert NoFreeMintsLeft();
        }
        if (totalSupply() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        uint256 remaining = maxFreeSupply - totalSupply();
        if (remaining > quantity) {
            _safeMint(msg.sender, quantity);
        } else {
            _safeMint(msg.sender, remaining);
        }
        emit MintedFree(msg.sender, remaining);
    }

    function mint(uint256 quantity) external payable {
        // Validation
        if (price == 0 || saleStartTime == 0 || block.timestamp < saleStartTime) {
            revert SaleNotBegun();
        }
        if (quantity == 0 || quantity > maxTokensPerTx) {
            revert QuantityOffLimits();
        }
        if (totalSupply() + quantity > maxSupply) {
            revert MaxSupplyReached();
        }
        if (price * quantity != msg.value) {
            revert InsufficientFunds();
        }
        _safeMint(msg.sender, quantity);
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

    function setOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
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

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = ownerWallet.call{value: balance}("");
        require(transferTx, "withdraw error");
    }
}