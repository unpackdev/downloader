// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol"; 

abstract contract hun {
    function tokensOfOwner(address addr) public virtual view returns(uint256[] memory);
}

contract HunnysMerch is ERC1155Supply, Ownable {  
    using Address for address;
    using Counters for Counters.Counter; 

    struct ProductData {
        uint256     id;
        string      uriString;
        uint256     price;
        bool        redeemable;
        uint256     layerId;
        bool        isLimited;
        bool        isHolderOnly;
        bool        isSoldOut;
        uint256     currentCount;
        uint256     limit;
    }

    hun private hu;
    Counters.Counter private tokenIds;
    ProductData[] public products;

    mapping (uint256 => string) private tokenURIs;
    mapping (uint256 => ProductData) public tokenProductRelation;

    string public baseTokenURI;

    // Starting and stopping sale
    bool public active = false;

    // price scale
    bool public scalePriceDown = false;
    uint256 public priceScalePercent = 0;

    // Team addresses for withdrawals
    address public a1;
    address public a2;
    address public a3;
    address public a4;
    
    constructor (string memory newBaseURI, address hunAddress) ERC1155 ("Hunnys Merch") {
        baseTokenURI = newBaseURI;
        // Deploy with Hunnys contract address
        hu = hun(hunAddress);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function uri(uint256 tokenId) override public view returns (string memory) { 
        return(tokenURIs[tokenId]); 
    } 

    // See which address owns which tokens
    function totalSupply(uint256 productId) override public view returns(uint256) {
        return products[productId].currentCount;
    }

    function totalContractSupply() public view returns(uint256) {
        return tokenIds.current();
    }

    function hunnysTokensOfOwner() public view returns(uint256[] memory) {
        return hu.tokensOfOwner(msg.sender);
    }

    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 tokenCounter = 0;
        // get tokenCount
        for (uint256 i = 0; i < tokenIds.current(); i++) {
            uint256 tokenCount = balanceOf(addr, i);
            if(tokenCount == 1) {
                tokenCounter = tokenCounter + 1;
            }
        }

        // use tokenCount to set return array size
        uint256[] memory tokensId = new uint256[](tokenCounter);
        uint256 count = 0;

        for (uint256 i = 0; i < tokenIds.current(); i++) {
            uint256 tokenCount = balanceOf(addr, i);
            if(tokenCount == 1) {
                tokensId[count] = i;
                count = count + 1;
            }
        }

        return tokensId;
    }

    // returns the length of the products array
    function getProductCount() public view returns(uint256) {
        return products.length;
    }

    // mint function
    function mintProducts(uint256[] memory _ids, uint256[] memory _amounts) public payable {
        require( active,                                                                    "Sale isn't active" );
        require( _ids.length > 0 && _ids.length == _amounts.length,                         "Params do not match up" );

        uint256 totalPrice = 0.00 ether;

        // validation 
        for (uint256 i = 0; i < _ids.length; i++) {
            // check if id is present
            require( _ids[i] >= 0 && _ids[i] <= products.length - 1,                        "Some ids got no matching product" );

            // get product data
            ProductData memory currentData = products[_ids[i]];

            // check for soldOut
            require( !currentData.isSoldOut,                                                "Can't mint a sold out product" );

            // check for limit
            if(currentData.isLimited){
                require( currentData.currentCount + _amounts[i] <= currentData.limit + 1,   "Can't mint more than max supply" );
            }

            // check for holder
            if(currentData.isHolderOnly){
                uint256[] memory ownedHunTokens = hu.tokensOfOwner(msg.sender);
                
                require( ownedHunTokens.length > 0,                                         "Some products require wallet to hold a Hunnys 10k Token" );
            }

            // set price
            uint256 scaledPrice = applyPriceScale(currentData.price);
            totalPrice = totalPrice + (scaledPrice * _amounts[i]);
        }

        // check price
        require( msg.value == totalPrice,                                                   "Wrong amount of ETH sent" );

        // minting
        for (uint256 i = 0; i < _ids.length; i++) {
            ProductData memory currentProduct = products[_ids[i]];

            // set products new current count before mint
            uint256 currentProductCount = currentProduct.currentCount;
            products[currentProduct.id].currentCount = products[currentProduct.id].currentCount + _amounts[i];

            // mint that product
            for (uint256 k = 0; k < _amounts[i]; k++) {
                uint256 currentContractId = tokenIds.current(); 
                
                setTokenUri(currentContractId, append(baseTokenURI, currentProduct.uriString, Strings.toString(currentProductCount + k)));

                tokenProductRelation[currentContractId] = products[_ids[i]];

                tokenIds.increment(); 

                _mint(msg.sender, currentContractId, 1, "");
            }
        }
    }

    function applyPriceScale(uint256 price) private view returns(uint256) {
        uint256 result = price;
        uint256 onePricePercent = price / 100;
        uint256 scaleValue = onePricePercent * priceScalePercent;

        if(scalePriceDown) {
            result = price - scaleValue;
        } else {
            result = price + scaleValue;
        }

        return result;
    }

    function setTokenUri(uint256 tokenId, string memory tokenURI) private {
         tokenURIs[tokenId] = tokenURI; 
    } 

    // concat strings
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    // Add new products in array way 
    function addNewProducts(string[] memory _uriString, uint256[] memory _prices, bool[] memory _redeemable, uint256[] memory _layerIds, bool[] memory _isLimited, bool[] memory _isHolderOnly, bool[] memory _isSoldOut, uint256[] memory _limits) public onlyOwner {
        uint256 currentId = products.length;
        for(uint256 i = 0; i < _uriString.length; i++){
            ProductData memory newProduct = ProductData(currentId + i, _uriString[i], _prices[i], _redeemable[i], _layerIds[i], _isLimited[i], _isHolderOnly[i], _isSoldOut[i], 1, _limits[i]);
            products.push(newProduct);
        }
    }

    // Change existing product by id 
    function changeProductById(uint256 _id, string memory _uriString, uint256 _price, bool _redeemable, uint256 _layerId, bool _isLimited, bool _isHolderOnly, bool _isSoldOut, uint256 _limit) public onlyOwner {
        products[_id].uriString = _uriString;
        products[_id].price = _price;
        products[_id].redeemable = _redeemable;
        products[_id].layerId = _layerId;
        products[_id].isLimited = _isLimited;
        products[_id].isHolderOnly = _isHolderOnly;
        products[_id].isSoldOut = _isSoldOut;
        products[_id].limit = _limit;
    }

    // Start and stop sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set discount values
    function setPriceScale(bool scaleDown, uint256 pricePercent) public onlyOwner {
        scalePriceDown = scaleDown;
        priceScalePercent = pricePercent;
    }

    // Set team addresses
    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
        a4 = _a[3];
    }

    // Withdraw funds from contract for the team
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send(percent * 60)); // 60% to Community Wallet
        require(payable(a2).send((percent * 13) + (percent / 3 ))); // 13,3% to Stacy
        require(payable(a3).send((percent * 13) + (percent / 3 ))); // 13,3% to NFT Forge
        require(payable(a4).send((percent * 13) + (percent / 3 ))); // 13,3% to Rat
    }
}