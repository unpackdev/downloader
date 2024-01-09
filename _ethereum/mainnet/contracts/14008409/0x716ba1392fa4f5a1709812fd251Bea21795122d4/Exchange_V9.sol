 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IAzimuth.sol";
import "./IEcliptic.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";

contract UrbitexExchangeV5 is Context, Ownable {

    // updated 2022-01-15
    // urbitex.io 

    //  azimuth: points state data store
    //
    IAzimuth public azimuth;
    
    // fee: exchange transaction fee 
    // 
    uint32 public fee;

    // ListedAsset: struct which stores the price and seller's address for a point listed in the marketplace
    // price as uint96 will pack 160 bit address and 96 bit price into one storage slot, saving gas
    struct ListedAsset {
        address addr;
        uint96 price;
        address reservedBuyer;
    }

    // assets: registry which stores the ListedAsset entries
    //
    mapping(uint32 => ListedAsset) assets;

    // EVENTS

    event MarketPurchase(
        address indexed _from,
        address indexed _to,
        uint32 _point,
        uint96 _price
    );

    event ListingRemoved(
        uint32 _point
    );

    event ListingAdded(
        uint32 _point,
        uint96 _price 
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store and set exchange fee
    //
    constructor(IAzimuth _azimuth, uint32 _fee) 
        payable 
    {     
        azimuth = _azimuth;
        fee = _fee;
    }

    // setRegistryEntry(): utility function to add or remove entries in the registry
    function setRegistryEntry(uint32 _point, address _address, uint96 _price, address _reservedBuyer) internal
    {
        ListedAsset storage asset = assets[_point];

        asset.addr = _address;
        asset.price = _price;
        asset.reservedBuyer = _reservedBuyer;
    }

    //  purchase(): purchase and transfer point from the seller to the buyer
    //
    function purchase(uint32 _point)
        external
        payable
    {
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        
        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset storage asset = assets[_point];

        address reservedBuyer = asset.reservedBuyer;
        address addr = asset.addr;
        uint96 price = asset.price;

        // if a reserved buyer has been set, check that it matches _msgSender()
        require(reservedBuyer == address(0) || reservedBuyer == _msgSender());
        
        // check that the seller's address in the registry matches the point's current owner
        require(addr == seller);

        // buyer must pay the exact price as what's stored in the registry for that point
        require(uint96(msg.value) == price);

        // in order to save on gas fees, a check that the seller has approved the exchange as a 
        // transfer proxy can happen off-chain. 

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // clear the values for that point in the registry
        delete assets[_point];

        // deduct exchange fee and transfer remaining amount to the seller  
        Address.sendValue(seller, msg.value/1000*(1000-fee));

        emit MarketPurchase(seller, _msgSender(), _point, price);
    }

    //  safePurchase(): Exactly like the purchase() function except with validation checks
    //
    function safePurchase(uint32 _point, bool _unbooted, uint32 _spawnCount, bool _isProxyL2)
        external
        payable
    {

        // make sure the booted status matches the buyer's expectations
        require(_unbooted == (azimuth.getKeyRevisionNumber(_point) == 0));

        // make sure the buyer is aware of any L2 proxy set
        require(azimuth.isSpawnProxy(_point, 0x1111111111111111111111111111111111111111) == _isProxyL2);

        // make sure the number of spawned child points matches the buyer's expectations
        require(_spawnCount == azimuth.getSpawnCount(_point));

        // get the current ecliptic contract
        IEcliptic ecliptic = IEcliptic(azimuth.owner());        

        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset storage asset = assets[_point];

        address reservedBuyer = asset.reservedBuyer;
        address addr = asset.addr;
        uint96 price = asset.price;

        // if a reserved buyer has been set, check that it matches _msgSender()
        require(reservedBuyer == address(0) || reservedBuyer == _msgSender(), "Not reserved buyer");

        // check that the address in the registry matches the point's current owner
        require(addr == seller, "invalid listing");

        // buyer must pay the exact price as what's stored in the registry for that point
        require(msg.value == price, "invalid price");

        // in order to save on gas fees, a check that the seller has approved the exchange as a 
        // transfer proxy can happen off-chain. 

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // clear the values for that point in the registry
        delete assets[_point];

        // deduct exchange fee and transfer remaining amount to the seller
        Address.sendValue(seller, msg.value/1000*(1000-fee));

        emit MarketPurchase(seller, _msgSender(), _point, price);
    }

    // addListing(): add a point to the registry, including its corresponding price and owner address.
    // optional reserved buyer address can be included. 
    //
    function addListing(uint32 _point, uint96 _price, address _reservedBuyer) external
    {
        // intentionally using isOwner() instead of canTransfer(), which excludes third-party proxy addresses.
        // the exchange owner also has no ability to list anyone else's assets, it can strictly only be the point owner.
        // 
        require(azimuth.isOwner(_point, _msgSender()), "not owner");

        // add the price of the point and the seller address to the registry
        //         
        setRegistryEntry(_point, _msgSender(), _price, _reservedBuyer);        
        
        emit ListingAdded(_point, _price);

    }

    // removeListing(): clear the information for this point in the registry. This function has also been made available
    // to the exchange owner to remove stale listings.
    //
    function removeListing(uint32 _point) external 
    {   
        require(azimuth.isOwner(_point, _msgSender()) || _msgSender() == owner(), "not owner");
        
        delete assets[_point];

        emit ListingRemoved(_point);
    }

    // getAssetInfo(): check the listed price and seller address of a point 
    // 
    function getAssetInfo(uint32 _point) external view returns (address, uint96, address) {
        return (assets[_point].addr, assets[_point].price, assets[_point].reservedBuyer);
    }

    // EXCHANGE OWNER OPERATIONS
             
    function withdraw(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        Address.sendValue(_target, address(this).balance);
    }

    function close(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        selfdestruct(_target);
    }
}