// SPDX-License-Identifier: MIT

pragma solidity >=0.8.13;

import {ERC721A} from "ERC721A.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";

error SaleNotStarted();
error QuantityOffLimits();
error MaxSupplyReached();
error InsufficientFunds();
error NonExistentTokenURI();

contract StoryWorlds is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable maxSupply = 9889;
    uint256 public immutable maxTokensPerTx = 100;

    uint256 public price = 0.18 ether;
    uint256 public saleStartTime = 1652814000;

    bool public revealed;

    address private ownerWallet;

    string private _baseTokenURI;
    string private notRevealedUri;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initNotRevealedUri,
        uint256 maxBatchSize_,
        address ownerWallet_
    ) ERC721A(name_, symbol_, maxBatchSize_) {
        setOwnerWallet(ownerWallet_);
        setNotRevealedURI(_initNotRevealedUri);
        _safeMint(0x283712312E70cDb81844D903D8D9C12B702f98cA, 40);
        _safeMint(0xD9cc905554623a1F8B75b03c52Ce1C091b04a33e, 20);
        _safeMint(0xC5e38233Cc0D7CFf9340e6139367aBA498EC9b18, 40);
    }

    function publicSaleMint(uint256 quantity) external payable {
        if (price == 0 || saleStartTime == 0 || block.timestamp < saleStartTime) revert SaleNotStarted();
        if (quantity == 0 || quantity > maxTokensPerTx) revert QuantityOffLimits();
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
        if (msg.value != price * quantity) revert InsufficientFunds();
        _safeMint(msg.sender, quantity);
    }

    function airdrop(address _to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert MaxSupplyReached();
        _safeMint(_to, quantity);
    }

     function setSaleStartTime(uint128 _timestamp) external onlyOwner {
        saleStartTime = _timestamp;
    }

    function setPrice(uint64 _price) external onlyOwner {
        price = _price;
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
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = ownerWallet.call{value: balance}("");
        require(transferTx, "withdraw error");
    }
}
