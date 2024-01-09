// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract Hancom721 is Ownable, ERC721 {
    using Strings for uint256;

    uint256 public tokenIdCounter = 0;
    uint256 public saleIdCounter = 0;

    address payable private _addressA;
    address payable private _addressB;
    uint16 private _shareRateA = 5500;
    uint16 private _fee = 250;
    string private _baseURIExtended;
    string private _contractMetadataURI;
    address private _distributor;

    struct Token {
        bool isPresent;
        string tokenURI;
        uint16 royalty;
        address minter;
        address owner;
    }

    struct Sale {
        bool isPresent;
        address payable seller;
        uint256 tokenId;
        uint16 currencyId;
        uint256 price;
    }

    mapping(uint256 => Token) public tokens;
    mapping(uint256 => Sale) public sales;
    mapping(uint16 => address) private _currencyAddresses;

    constructor(string memory baseURI_, string memory contractMetadataURI_)
    ERC721("Hancom Artpia", "HCAP") payable {
        _baseURIExtended = baseURI_;
        _contractMetadataURI = string(abi.encodePacked(baseURI_, contractMetadataURI_));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokens[tokenId].isPresent);
        return string(abi.encodePacked(_baseURIExtended, tokens[tokenId].tokenURI));
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }


    function setDistributor(address distributor) public onlyOwner {
        _distributor = distributor;
    }

    function getDistributor() public view onlyOwner returns (address) {
        return _distributor;
    }

    function addCurrencyAddress(uint16 currencyId, address currencyAddress) public onlyOwner {
        _currencyAddresses[currencyId] = currencyAddress;
    }


    function setShares(address payable addressA, address payable addressB, uint16 rate, uint16 fee) public onlyOwner {
        _addressA = addressA;
        _addressB = addressB;
        _shareRateA = rate;
        _fee = fee;
    }


    function getShares() public view onlyOwner returns (address, address, uint16, uint16) {
        return (_addressA, _addressB, _shareRateA, _fee);
    }


    function changeToken(uint256 tokenId, bool isPresent) public onlyOwner {
        tokens[tokenId].isPresent = isPresent;
    }

    function changeSale(uint256 saleId, bool isPresent) public onlyOwner {
        tokens[saleId].isPresent = isPresent;
    }

    function changeTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        tokens[tokenId].tokenURI = tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIdCounter;
    }

    event Minted(
        uint256 tokenId, string title, string tokenURI, uint16 royalty,
        bool putOnSale, uint256 saleId, uint16 currencyId, uint256 price, uint256 indexed dataId
    );

    function mintToken(string memory title, string memory uri, uint16 royalty,
        bool putOnSale, uint16 currencyId, uint256 price, uint256 dataId) external {

        require(bytes(uri).length > 0);

        uint256 tokenId = tokenIdCounter;

        require(!tokens[tokenId + 1].isPresent);

        tokenId = ++tokenIdCounter;

        setApprovalForAll(address(this), true);

        _mint(_msgSender(), tokenId);

        tokens[tokenId] = Token(true, uri, royalty, payable(_msgSender()), payable(_msgSender()));

        uint256 saleId = 0;
        if (putOnSale) {
            require(currencyId > 0
            && price > 0
                && !sales[saleIdCounter + 1].isPresent);

            saleId = ++saleIdCounter;

            sales[saleId] = Sale(true, payable(_msgSender()), tokenId, currencyId, price);
        }

        emit Minted(tokenId, title, uri, royalty, putOnSale, saleId, currencyId, price, dataId);
    }

    event Sold(uint256 saleId, address seller, uint256 tokenId, uint16 currencyId, uint256 price, uint256 indexed dataId);

    function buyToken(uint256 saleId, uint256 dataId) external payable {
        Sale memory sale = sales[saleId];
        Token memory token = tokens[sale.tokenId];

        require(_msgSender() != address(0)
        && sale.seller != address(0)
        && sale.seller != _msgSender()
            && token.isPresent);

        {
            address erc20 = _currencyAddresses[sale.currencyId];

            (bool success,) = _distributor.delegatecall(
                abi.encodeWithSignature("distribute(address,uint16,uint256,address,uint16,uint16,address,address,uint16,address)",
                sale.seller, sale.currencyId, sale.price, token.minter, token.royalty, _fee, _addressA, _addressB, _shareRateA, erc20));
            require(success);
        }

        setApprovalForAll(address(this), true);

        {
            _transfer(sale.seller, _msgSender(), sale.tokenId);
        }

        tokens[sale.tokenId].owner = payable(_msgSender());

        delete sales[saleId];

        emit Sold(saleId, sale.seller, sale.tokenId, sale.currencyId, sale.price, dataId);
    }

    event SaleChanged(uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 indexed dataId);

    function changeSale(uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 dataId) external {
        require(_msgSender() != address(0)
        && currencyId > 0
        && price > 0
            && _msgSender() == tokens[tokenId].owner);

        uint256 changeSaleId = saleId;
        if (putOnSale) {
            if (!sales[changeSaleId].isPresent) {
                require(!sales[saleIdCounter + 1].isPresent);

                changeSaleId = ++saleIdCounter;

                sales[changeSaleId] = Sale(true, payable(_msgSender()), tokenId, currencyId, price);
            } else {
                require(_msgSender() == sales[changeSaleId].seller);

                sales[changeSaleId].currencyId = currencyId;
                sales[changeSaleId].price = price;
            }
        } else {
            delete sales[changeSaleId];
        }

        emit SaleChanged(tokenId, changeSaleId, putOnSale, currencyId, price, dataId);
    }

    function burn(uint256 tokenId) public {
        require(tokens[tokenId].isPresent);
        require(_msgSender() == tokens[tokenId].owner
            || _msgSender() == owner());
        _burn(tokenId);
        delete tokens[tokenId];
    }


}
