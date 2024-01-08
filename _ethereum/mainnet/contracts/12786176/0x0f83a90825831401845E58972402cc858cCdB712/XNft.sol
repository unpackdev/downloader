// contracts/XNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract XNft is ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    struct TokenCategory {
        string title;
        uint256 startId;
        uint256 endId;
        string imageURI;
        bool isValue;
    }

    uint256 public lastTokenCategoryId;
    mapping(uint256 => TokenCategory) public tokenCategories;

    struct Sale {
        address userAddress;
        uint256 tokenCategoryId;
        uint256[] tokens;
        uint256 tokenLength;
        uint256 amount;
    }

    Sale[] public sales;

    mapping(address => string) public names;

    mapping(uint256 => bool) public tokenSold;
    uint256 public soldTokensLength;

    mapping(uint256 => uint256) public tokenPrices;
    address payable public treasurer;
    uint256 public totalSale;

    bool public isPaused = true;

    event SaleExecuted(uint256 indexed saleIndex, address indexed userAddress, uint256 indexed tokenCategoryId, uint256 tokenLength, uint256 amount);
    event TokenSold(uint256 indexed categoryId, address indexed to, uint256 indexed tokenId);
    event NameUpdated(address indexed user, string name);
    event PriceUpdated(uint256 indexed categoryId, uint256 price);
    event TokenCategoryAdded(uint256 indexed categoryId, uint256 startId, uint256 endId, string imageURI, uint256 price);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        treasurer = payable(msg.sender);
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unPause() external onlyOwner {
        isPaused = false;
    }

    function getSalesLength() view external returns (uint256){
        return sales.length;
    }

    function addTokenCategory(string memory title, uint256 tokenLength, string memory imageURI, uint256 price) onlyOwner external {
        TokenCategory memory lastTokenCategory = tokenCategories[lastTokenCategoryId];
        uint256 startId = 1;
        if (lastTokenCategory.isValue) {
            startId = (lastTokenCategory.endId).add(1);
        }
        lastTokenCategoryId = lastTokenCategoryId.add(1);
        TokenCategory memory tokenCategory = TokenCategory(title, startId, startId.add((tokenLength.sub(1))), imageURI, true);
        tokenCategories[lastTokenCategoryId] = tokenCategory;
        tokenPrices[lastTokenCategoryId] = price;
        emit TokenCategoryAdded(lastTokenCategoryId, startId, startId.add((tokenLength.sub(1))), imageURI, price);
    }

    function updatePrice(uint256 tokenCategoryId, uint256 _new_price) external onlyOwner {
        tokenPrices[tokenCategoryId] = _new_price;
        emit PriceUpdated(tokenCategoryId, _new_price);
    }

    function updateTreasurer(address payable _new_treasurer) external onlyOwner {
        treasurer = _new_treasurer;
    }

    function buyMultiple(uint256 tokenCategoryId, uint256[] memory _tokenIds, string[] memory _tokenURIs) external payable {
        require(!isPaused, "XNft contract is paused.");
        TokenCategory memory tokenCategory = tokenCategories[tokenCategoryId];
        require(tokenCategory.isValue, "XNft: Token category not found.");
        require(msg.value == tokenPrices[tokenCategoryId].mul(_tokenIds.length), 'XNft: Wrong value to buy Token.');
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            buy(tokenCategoryId, _tokenIds[i], _tokenURIs[i]);
        }
        treasurer.transfer(msg.value);
        totalSale = totalSale.add(msg.value);

        Sale memory sale = Sale(msg.sender, tokenCategoryId, _tokenIds, _tokenIds.length, msg.value);
        sales.push(sale);
        emit SaleExecuted(sales.length, msg.sender, tokenCategoryId, _tokenIds.length, msg.value);
    }

    function buy(uint256 tokenCategoryId, uint256 _tokenId, string memory _tokenURI) internal {
        require(!tokenSold[_tokenId], 'XNft: Token already sold.');

        tokenSold[_tokenId] = true;
        soldTokensLength = soldTokensLength.add(1);
        _mint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);

        emit TokenSold(tokenCategoryId, msg.sender, _tokenId);
    }

    function updateName(string memory new_name) external {
        names[msg.sender] = new_name;
        emit NameUpdated(msg.sender, new_name);
    }

    function getNames(address[] memory addresses) view external returns (string memory commaSeparatedNames){
        for (uint256 i = 0; i < addresses.length; i++) {
            commaSeparatedNames = string(abi.encodePacked(commaSeparatedNames, names[addresses[i]], ','));
        }
        return commaSeparatedNames;
    }

    function getSaleTokenIds(uint256 index) view external returns (uint256[] memory _tokenIds){
        Sale memory sale = sales[index];
        return sale.tokens;
    }
}
