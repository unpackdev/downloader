// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Holder.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC1155.sol";

contract FlufMarketplace is ERC1155Holder, Ownable {
    // Struct for setting individual assetPrices
    struct assetPrice {
        uint256 price;
    }
    // Asset Type => ERC1155 Contract Address
    mapping(string => address) public assetAddress;
    // Price set for Asset Type 
    mapping (uint => assetPrice) public assetPricing;
    mapping (uint => mapping(address => bool)) public whiteList;
    mapping (uint => bool) public whiteListEnabled;
    address public flufAssetsAddress;
    
    constructor() {
        flufAssetsAddress = 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47;
    }
    
    function setFlufAssetsAddress(address _address) public onlyOwner {
        flufAssetsAddress = _address;
    }
    
    function setWhiteList(address[] calldata _addresses, uint assetId, bool _state) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whiteList[assetId][_addresses[i]] = _state;
        }
        // Since we are setting a whitelist, it's pretty obvious that whitelisting has to be enabled for this tokenId
        whiteListEnabled[assetId] = true;
    }
    
    function setWhiteListState(uint[] calldata _assetIds, bool _state) public onlyOwner{
        for (uint i = 0; i < _assetIds.length; i++) {
            whiteListEnabled[_assetIds[i]] = _state;
        }
    }
    
    function listNewAssetType(address _address, string memory _name) 
        public 
        onlyOwner 
        returns (bool) 
    {
        assetAddress[_name] = _address;
        return true;
    }
    
    function changeAssetPrice(uint256 assetId, uint256 newPrice)
        public
        payable
        onlyOwner
    {
        require(assetId >= 0, "You can't change the price of an asset sub zero");
        require(newPrice >= 0, "You can't give away assets for free");
        assetPrice storage c = assetPricing[assetId];
        c.price = newPrice;
    }

    function changeAssetPriceBatch(uint256[] memory assetIds, uint256[] memory newPrices)
        public
        payable
        onlyOwner
    {
        for(uint x = 0; x < assetIds.length; x++) {
            require(assetIds[x] >= 0, "You can't change the price of an asset sub zero");
            require(newPrices[x] >= 0, "You can't give away assets for free");
            assetPrice storage c = assetPricing[assetIds[x]];
            c.price = newPrices[x];
        }
    }

    function withdrawFunds() 
        public 
        onlyOwner 
    {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function isVaultStocked(uint256 assetId, uint256 quantity) 
        public 
        view
        returns (bool)
    {
        // Use the assetTypeName to lookup contract address, store balanceOf for comparison
        // Swap with marketplace balance check
        uint256 assetCount = IERC1155(flufAssetsAddress).balanceOf(address(this), assetId);
        return assetCount >= quantity;
    }
    
    function buyAsset(uint256 assetId, uint256 quantity) 
        public 
        payable 
    {
        // If whitelist is enabled for this assetID we should check if the user is whitelisted
        if(whiteListEnabled[assetId] == true){
            require(whiteList[assetId][msg.sender] == true, "WHITELIST HALT: You are not whitelisted for this drop, check back later..");
        }
        // Check that vault has asset available
        require(isVaultStocked(assetId, quantity), "VAULT HALT: The asset you are trying to buy is not available");
        // Check that msg.sender sent enough for price
        require(msg.value == getAssetPrice(assetId) * quantity, "MARKET STOP: You must send the proper value to buy asset");
        IERC1155(flufAssetsAddress).safeTransferFrom(address(this), msg.sender, assetId, quantity, "");
    }
    
    function getEthBalance() 
        public 
        view 
        returns (uint256) 
    {
        return address(this).balance;
    }

    function getAssetPrice(uint assetId) 
        public 
        view 
        returns(uint256)
    {
        return assetPricing[assetId].price;
    }
    
    function emergencyTokenWithdraw(uint256 _asset, uint256 _amount)
        public
        payable
        onlyOwner
    {
        IERC1155(flufAssetsAddress).safeTransferFrom(address(this), msg.sender, _asset, _amount, "");
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}