// SPDX-License-Identifier: MIT
import "./ERC1155.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract Hancom1155 is ERC1155, Ownable {
    using Address for address;

    string public name = "Hancom Artpia";
    string public symbol = "HCAP";

    uint256 public tokenIdCounter = 0;
    uint256 public saleIdCounter = 0;

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

    struct Sale {
        bool isPresent;
        address payable seller;
        address contractAddress;
        uint256 tokenId;
        uint16 currencyId;
        uint256 price;
        uint256 amount;
    }

    struct ShareInfo {
        address addressA;
        address addressB;
        uint16 shareRateA;
        uint16 fee;
    }

    ShareInfo private _shareInfo;

    mapping(uint256 => Token) public tokens;
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
        _shareInfo.addressA = addressA;
        _shareInfo.addressB = addressB;
        _shareInfo.shareRateA = rate;
        _shareInfo.fee = fee;
    }

    function getShares() public view onlyOwner returns (ShareInfo memory) {
        return _shareInfo;
    }

    function changeTokenByOwner(uint256 tokenId, bool isPresent) public onlyOwner {
        tokens[tokenId].isPresent = isPresent;
    }

    function changeSaleByOwner(uint256 saleId, bool isPresent) public onlyOwner {
        tokens[saleId].isPresent = isPresent;
    }

    function changeTokenURI(uint256 tokenId, string memory newUri) public onlyOwner {
        tokens[tokenId].tokenURI = newUri;
    }

    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return tokens[tokenId].amount;
    }

    event Minted(
        uint256 tokenId, string title, string tokenURI, uint16 royalty, uint256 amount,
        bool putOnSale, uint256 saleId, uint16 currencyId, uint256 price, uint256 saleAmount,
        uint256 indexed dataId
    );

    function mintToken(string memory title, string memory newUri, uint16 royalty, uint256 amount,
        bool putOnSale, uint16 currencyId, uint256 price, uint256 saleAmount, uint256 dataId) external {

        require(
            amount >= saleAmount
            && bytes(newUri).length > 0);

        uint256 tokenId = tokenIdCounter;
        require(!tokens[tokenId + 1].isPresent);

        tokenId = ++tokenIdCounter;

        _mint(_msgSender(), tokenId, amount, "");

        tokens[tokenId] = Token(true, newUri, royalty, payable(_msgSender()), amount);

        uint256 saleId = 0;
        if (putOnSale) {
            require(
                currencyId > 0
                && price > 0
                && saleAmount > 0
                && !sales[saleIdCounter + 1].isPresent
            );
            saleId = ++saleIdCounter;
            sales[saleId] = Sale(true, payable(_msgSender()), address(this), tokenId, currencyId, price, saleAmount);
            setApprovalForAll(address(this), true);
        }

        emit Minted(tokenId, title, newUri, royalty, amount, putOnSale, saleId, currencyId, price, saleAmount, dataId);
    }

    event SaleChanged(address contractAddress, uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 amount, uint256 holdAmount, uint256 indexed dataId);

    function changeSale(address contractAddress, uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 amount, uint256 dataId) external {
        require(_msgSender() != address(0)
        && contractAddress.isContract()
        && currencyId > 0
        && price > 0
            && amount >= 0);

        uint256 changeSaleId = saleId;
        uint256 holdAmount = ERC1155(contractAddress).balanceOf(_msgSender(), tokenId);

        if (putOnSale) {
            require(holdAmount >= amount
                && !sales[saleIdCounter + 1].isPresent
                && IERC1155(contractAddress).isApprovedForAll(_msgSender(), address(this)));

            changeSaleId = ++saleIdCounter;
            sales[changeSaleId] = Sale(true, payable(_msgSender()), contractAddress, tokenId, currencyId, price, amount);
        } else {
            require(_msgSender() == sales[changeSaleId].seller);
            delete sales[changeSaleId];
        }

        emit SaleChanged(contractAddress, tokenId, changeSaleId, putOnSale, currencyId, price, amount, holdAmount, dataId);
    }

    event Sold(uint256 saleId, address seller, address contractAddress, uint256 tokenId, uint16 currencyId, uint256 price, uint256 amount, uint256 indexed dataId);

    function buyToken(uint256 saleId, uint256 amount, uint256 dataId) external payable {
        Sale memory sale = sales[saleId];
        address buyer = _msgSender();

        require(
            amount > 0
            && sale.amount >= amount
            && sale.contractAddress.isContract()
            && ERC1155(sale.contractAddress).balanceOf(sale.seller, sale.tokenId) >= amount
            && sale.seller != buyer
        );

        address minter = _shareInfo.addressB;
        uint16 royalty = 0;
        {
            if (address(this) == sale.contractAddress) {
                Token memory token = tokens[sale.tokenId];

                minter = token.minter;
                royalty = token.royalty;
            }
        }

        {
            (bool success,) = _distributor.delegatecall(
                abi.encodeWithSignature("distribute(address,uint16,uint256,address,uint16,(address,address,uint16,uint16),address)",
                sale.seller, sale.currencyId, (sale.price * amount), minter, royalty, _shareInfo, _currencyAddresses[sale.currencyId]));
            require(success);
        }

        {
            IERC1155(sale.contractAddress).safeTransferFrom(sale.seller, buyer, sale.tokenId, amount, "0x0");
        }

        {
            if (sale.amount > amount) {
                sales[saleId].amount = sale.amount - amount;
            } else {
                delete sales[saleId];
            }
        }

        emit Sold(saleId, sale.seller, sale.contractAddress, sale.tokenId, sale.currencyId, sale.price, amount, dataId);
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
