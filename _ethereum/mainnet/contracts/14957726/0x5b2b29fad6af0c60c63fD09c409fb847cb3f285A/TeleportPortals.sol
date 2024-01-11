// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract TELEPORTFOUNDERSCLUB {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256);

    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract TeleportPortals is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Address for address;

    uint256 public price;
    uint256 public priceTFC;
    uint256 public priceWhitelist;
    uint256 public immutable maxSupply;
    uint256 public supplyCap;
    bool public mintingEnabled = true;
    uint256 public buyLimit;
    uint256 public walletLimit;
    mapping(address => bool) public whitelist;

    string private _baseURIPrefix;

    TELEPORTFOUNDERSCLUB private teleportfoundersclub;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _supplyCap,
        uint256 _price,
        uint256 _priceTFC,
        uint256 _priceWhiteList,
        uint256 _buyLimit,
        uint256 _walletLimit,
        string memory _uri,
        address _tfcContractAddress
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        supplyCap = _supplyCap;
        price = _price;
        priceTFC = _priceTFC;
        priceWhitelist = _priceWhiteList;
        buyLimit = _buyLimit;
        walletLimit = _walletLimit;
        _baseURIPrefix = _uri;
        teleportfoundersclub = TELEPORTFOUNDERSCLUB(_tfcContractAddress);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setWhitelist(address[] calldata newAddresses) external onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++)
            whitelist[newAddresses[i]] = true;
    }

    function removeWhitelist(address[] calldata currentAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < currentAddresses.length; i++)
            delete whitelist[currentAddresses[i]];
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPriceTFC(uint256 newPrice) external onlyOwner {
        priceTFC = newPrice;
    }

    function setPriceWhitelist(uint256 newPrice) external onlyOwner {
        priceWhitelist = newPrice;
    }

    function setBuyLimit(uint256 newBuyLimit) external onlyOwner {
        buyLimit = newBuyLimit;
    }

    function setWalletLimit(uint256 newWalletLimit) external onlyOwner {
        walletLimit = newWalletLimit;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function mintNFT(uint256 quantity) external payable {
        require(
            totalSupply().add(quantity) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            totalSupply().add(quantity) <= supplyCap,
            "Supply cap exceeded"
        );
        if (_msgSender() != owner()) {
            require(mintingEnabled, "Minting has not been enabled");

            require(quantity <= buyLimit, "Buy limit exceeded");
            require(
                balanceOf(_msgSender()).add(quantity) <= walletLimit,
                "Wallet limit exceeded"
            );
        }
        require(quantity > 0, "Invalid quantity");

        uint256 checkbalanceTFC = teleportfoundersclub.balanceOf(msg.sender);

        if (whitelist[_msgSender()]) {
            require(
                priceWhitelist.mul(quantity) == msg.value,
                "Incorrect ETH value"
            );
        } else if (checkbalanceTFC > 0) {
            require(priceTFC.mul(quantity) == msg.value, "Incorrect ETH value");
        } else {
            require(price.mul(quantity) == msg.value, "Incorrect ETH value");
        }

        require(!_msgSender().isContract(), "Contracts are not allowed");

        _safeMint(_msgSender(), quantity);
    }

    function creatorMint(uint256 quantity) external onlyOwner {
        _safeMint(_msgSender(), quantity);
    }

    function airdrop(address[] calldata to) external onlyOwner {
        require(
            totalSupply().add(to.length) <= maxSupply,
            "Max supply exceeded"
        );
        require(
            totalSupply().add(to.length) <= supplyCap,
            "Supply cap exceeded"
        );

        for (uint256 i = 0; i < to.length; i++) _safeMint(to[i], 1);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
