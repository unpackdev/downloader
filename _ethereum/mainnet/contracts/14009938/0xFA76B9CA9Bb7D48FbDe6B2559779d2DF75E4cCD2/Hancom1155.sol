// SPDX-License-Identifier: MIT
import "./ERC1155.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract Hancom1155 is ERC1155, Ownable {

    string public name = "Hancom Artpia";
    string public symbol = "HCAP";

    uint256 public tokenIdCounter = 0;
    uint256 public saleIdCounter = 0;

    address payable private _addressA;   
    address payable private _addressB;   
    uint16 private _shareRateA = 55;    
    uint16 private _fee = 250; 
    string private _baseURIExtended;
    string private _contractMetadataURI;
    address private _distributor;

    struct Token {
        bool isPresent;
        string tokenURI;
        uint16 royalty;
        address payable minter;
        uint256 amount;
    }

    struct Hold {
        bool isPresent;
        uint256 amount;
    }

    struct Sale {
        bool isPresent;
        address payable seller;
        uint256 tokenId;
        uint16 currencyId;
        uint256 price;
        uint256 amount;
    }

    mapping(uint256 => Token) public tokens;
    mapping(uint256 => mapping(address => Hold)) public holds;
    mapping(uint256 => Sale) public sales;
    mapping(uint16 => address) private _currencyAddresses;

    constructor(string memory baseURI_, string memory contractMetadataURI_)
    ERC1155(string(abi.encodePacked(baseURI_, "{id}"))) payable {
        _baseURIExtended = baseURI_;
        _contractMetadataURI = contractMetadataURI_;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokens[tokenId].isPresent);
        return string(abi.encodePacked(_baseURIExtended, tokens[tokenId].tokenURI));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURIExtended, _contractMetadataURI));
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

    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return tokens[tokenId].amount;
    }

    event Minted(
        uint256 tokenId, string title, string tokenURI, uint16 royalty, uint256 amount,
        bool putOnSale, uint256 saleId, uint16 currencyId, uint256 price, uint256 saleAmount,
        uint256 indexed dataId
    );

    function mintToken(string memory title, string memory uri, uint16 royalty, uint256 amount,
        bool putOnSale, uint16 currencyId, uint256 price, uint256 saleAmount, uint256 dataId) external {

        require(
            amount >= saleAmount
            && bytes(uri).length > 0);

        uint256 tokenId = tokenIdCounter;
        require(!tokens[tokenId + 1].isPresent);

        tokenId = ++tokenIdCounter;

        setApprovalForAll(address(this), true);

        _mint(_msgSender(), tokenId, amount, "");

        tokens[tokenId] = Token(true, uri, royalty, payable(_msgSender()), amount);

        uint256 saleId = 0;
        if (putOnSale) {
            require(
                currencyId > 0
                && price > 0
                && saleAmount > 0
                && !sales[saleIdCounter + 1].isPresent
            );

            saleId = ++saleIdCounter;

            sales[saleId] = Sale(true, payable(_msgSender()), tokenId, currencyId, price, saleAmount);

            if (amount > saleAmount) {
                holds[tokenId][_msgSender()] = Hold(true, amount - saleAmount);
            }
        } else {
            holds[tokenId][_msgSender()] = Hold(true, amount);
        }

        emit Minted(tokenId, title, uri, royalty, amount, putOnSale, saleId, currencyId, price, saleAmount, dataId);
    }

    event Sold(uint256 saleId, address seller, uint256 tokenId, uint16 currencyId, uint256 price, uint256 amount, uint256 indexed dataId);

    function buyToken(uint256 saleId, uint256 amount, uint256 dataId) external payable {
        Sale memory sale = sales[saleId];
        Token memory token = tokens[sale.tokenId];

        require(
            amount > 0
            && sale.amount >= amount
            && sale.seller != _msgSender()
            && token.isPresent
        );

        {
            (bool success,) = _distributor.delegatecall(
                abi.encodeWithSignature("distribute(address,uint16,uint256,address,uint16,uint16,address,address,uint16,address)",
                sale.seller, sale.currencyId, (sale.price * amount), token.minter, token.royalty, _fee, _addressA, _addressB, _shareRateA, _currencyAddresses[sale.currencyId]));
            require(success);
        }

        {
            setApprovalForAll(address(this), true);
            _safeTransferFrom(sale.seller, _msgSender(), sale.tokenId, amount, "0x0");
        }

        {
            if (sale.amount > amount) {
                sales[saleId].amount = sale.amount - amount;
            } else {
                delete sales[saleId];
            }
        }

        {
            if (!holds[sale.tokenId][_msgSender()].isPresent) {
                holds[sale.tokenId][_msgSender()] = Hold(true, amount);
            } else {
                holds[sale.tokenId][_msgSender()].amount = holds[sale.tokenId][_msgSender()].amount + amount;
            }
        }

        emit Sold(saleId, sale.seller, sale.tokenId, sale.currencyId, sale.price, amount, dataId);
    }

    event SaleChanged(uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 amount, uint256 holdAmount, uint256 indexed dataId);

    function changeSale(uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 amount, uint256 dataId) external {
        require(_msgSender() != address(0)
        && tokens[tokenId].isPresent
        && currencyId > 0
        && price > 0
            && amount >= 0);

        uint256 changeSaleId = saleId;
        uint256 holdAmount = 0;
        if (holds[tokenId][_msgSender()].isPresent) {
            holdAmount = holds[tokenId][_msgSender()].amount;
        }

        if (putOnSale) {
            require(holdAmount >= amount);
            require(!sales[saleIdCounter + 1].isPresent);

            changeSaleId = ++saleIdCounter;
            sales[changeSaleId] = Sale(true, payable(_msgSender()), tokenId, currencyId, price, amount);

            uint256 restHoldAmount = holdAmount - amount;

            if (restHoldAmount > 0) {
                holds[tokenId][_msgSender()].amount = restHoldAmount;
            } else {
                delete holds[tokenId][_msgSender()];
            }
        } else {
            require(_msgSender() == sales[changeSaleId].seller);
            
            if (holdAmount == 0) {
                holds[tokenId][_msgSender()] = Hold(true, sales[changeSaleId].amount);
            } else {
                holds[tokenId][_msgSender()].amount = holdAmount + sales[changeSaleId].amount;
            }

            delete sales[changeSaleId];
        }

        emit SaleChanged(tokenId, changeSaleId, putOnSale, currencyId, price, amount, holdAmount, dataId);
    }

    function burn(address account, uint256 tokenId, uint256 amount) public {
        require(tokens[tokenId].isPresent
            && tokens[tokenId].amount == amount);
        if (_msgSender() == owner()) {
            _burn(account, tokenId, amount);
        } else {
            require(_msgSender() == account);
            _burn(account, tokenId, amount);
        }

        delete tokens[tokenId];
    }
}
