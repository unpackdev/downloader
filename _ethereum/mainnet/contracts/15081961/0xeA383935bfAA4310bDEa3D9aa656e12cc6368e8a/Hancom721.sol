// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";

pragma solidity ^0.8.0;

contract Hancom721 is Ownable, ERC721 {
    using Strings for uint256;
    using Address for address;

    uint256 public tokenIdCounter = 0;
    uint256 public saleIdCounter = 0;

    string private _baseURIExtended;
    string private _contractMetadataURI;
    address private _distributor;

    struct Token {
        bool isPresent;
        string tokenURI;
        uint16 royalty;
        address minter;
    }

    struct Sale {
        bool isPresent;
        address payable seller;
        address contractAddress;
        uint256 tokenId;
        uint16 currencyId;
        uint256 price;
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

    function mintToken(string memory title, string memory newUri, uint16 royalty,
        bool putOnSale, uint16 currencyId, uint256 price, uint256 dataId) external {

        require(bytes(newUri).length > 0);

        uint256 tokenId = tokenIdCounter;

        require(!tokens[tokenId + 1].isPresent);

        tokenId = ++tokenIdCounter;

        _safeMint(_msgSender(), tokenId);

        tokens[tokenId] = Token(true, newUri, royalty, payable(_msgSender()));

        uint256 saleId = 0;
        if (putOnSale) {
            require(currencyId > 0
            && price > 0
                && !sales[saleIdCounter + 1].isPresent);

            saleId = ++saleIdCounter;
            sales[saleId] = Sale(true, payable(_msgSender()), address(this), tokenId, currencyId, price);
            setApprovalForAll(address(this), true);
        }

        emit Minted(tokenId, title, newUri, royalty, putOnSale, saleId, currencyId, price, dataId);
    }

    event SaleChanged(address contractAddress, uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 indexed dataId);

    function changeSale(address contractAddress, uint256 tokenId, uint256 saleId, bool putOnSale, uint16 currencyId, uint256 price, uint256 dataId) external {
        require(_msgSender() != address(0)
        && contractAddress.isContract()
        && currencyId > 0
        && price > 0
            && _msgSender() == IERC721(contractAddress).ownerOf(tokenId));

        uint256 changeSaleId = saleId;
        if (putOnSale) {
            require(!sales[saleIdCounter + 1].isPresent
            && IERC721(contractAddress).isApprovedForAll(_msgSender(), address(this)));

            changeSaleId = ++saleIdCounter;
            sales[changeSaleId] = Sale(true, payable(_msgSender()), contractAddress, tokenId, currencyId, price);
        } else {
            delete sales[changeSaleId];
        }

        emit SaleChanged(contractAddress, tokenId, changeSaleId, putOnSale, currencyId, price, dataId);
    }

    event Sold(uint256 saleId, address seller, address contractAddress, uint256 tokenId, uint16 currencyId, uint256 price, uint256 indexed dataId);

    function buyToken(uint256 saleId, uint256 dataId) external payable {
        Sale memory sale = sales[saleId];
        address buyer = payable(_msgSender());

        require(buyer != address(0)
        && sale.seller == IERC721(sale.contractAddress).ownerOf(sale.tokenId)
        && sale.contractAddress.isContract()
            && sale.seller != buyer);

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
                sale.seller, sale.currencyId, sale.price, minter, royalty, _shareInfo, _currencyAddresses[sale.currencyId]));
            require(success);
        }

        {
            IERC721(sale.contractAddress).safeTransferFrom(sale.seller, buyer, sale.tokenId);
        }

        delete sales[saleId];

        emit Sold(saleId, sale.seller, sale.contractAddress, sale.tokenId, sale.currencyId, sale.price, dataId);
    }

    function burn(uint256 tokenId) public {
        require(tokens[tokenId].isPresent);
        require(_msgSender() == ownerOf(tokenId)
            || _msgSender() == owner());
        _burn(tokenId);
        delete tokens[tokenId];
    }

}
