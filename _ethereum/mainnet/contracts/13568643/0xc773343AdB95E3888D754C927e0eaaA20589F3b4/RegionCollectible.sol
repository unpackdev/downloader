// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

import "./BDERC1155Tradable.sol";
import "./LibRegion.sol";
import "./IWarrior.sol";

//Import ERC1155 standard for utilizing FAME tokens
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

/**
 * @title RegionCollectible
 * RegionCollectible - The contract for managing BattleDrome Region NFTs
 */

contract RegionCollectible is BDERC1155Tradable, ERC1155Holder {
    using LibRegion for LibRegion.region;

    mapping(uint256 => LibRegion.region) regions;
    mapping(uint256 => uint256) locationOfWarrior;
    mapping(uint256 => uint256[]) warriorsAtLocation;
    mapping(string => bool) regionNames;
    mapping(string => uint256) regionsByName;
    mapping(address => bool) trustedContracts;

    uint256 currentRegionCount;
    uint256 currentRegionPricingCounter;

    IERC1155 FAMEContract;
    IWarrior WarriorContract;
    uint256 FAMETokenID;
    uint256 regionTaxDivisor;

    constructor(address _proxyRegistryAddress)
        BDERC1155Tradable(
            "RegionCollectible",
            "BDR",
            _proxyRegistryAddress,
            "https://metadata.battledrome.io/api/erc1155-region/"
        )
    {}

    function contractURI() public pure returns (string memory) {
        return "https://metadata.battledrome.io/contract/erc1155-region";
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////

    modifier onlyTrustedContracts() {
        //Check that the message came from a Trusted Contract
        require(trustedContracts[msg.sender]);
        _;
    }

    modifier onlyOwnersOrTrustedContracts(uint256 regionID) {
        //Check that the message either came from an owner, or a trusted contract
        require(
            balanceOf(msg.sender, regionID) > 0 || trustedContracts[msg.sender]
        );
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    event RegionAltered(uint64 indexed region, uint32 timeStamp);
    event RegionCreated(
        uint64 indexed region,
        address indexed owner,
        uint64 price,
        uint32 timeStamp
    );
    event RegionSold(
        uint64 indexed region,
        address indexed owner,
        uint64 price,
        uint32 timeStamp
    );
    event RegionBought(
        uint64 indexed region,
        address indexed owner,
        uint64 price,
        uint32 timeStamp
    );

    //////////////////////////////////////////////////////////////////////////////////////////
    // Region Factory
    //////////////////////////////////////////////////////////////////////////////////////////

    //Standard factory function, allowing minting regions.
    function internalCreateRegion() internal returns (uint256 theNewRegion) {
        //Generate a new random seed for the region
        uint256 randomSeed = uint256(blockhash(block.number - 1)); //YES WE KNOW this isn't truely random. it's predictable, and vulnerable to malicious miners...
        //Doesn't actually matter in this case. That's all ok. It's only for generating cosmetics etc...

        //Calculate new Token ID for minting
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        //Log the original creator of this region
        creators[_id] = msg.sender;

        //Generate a new region metadata structure, and add it to the regions array
        regions[_id].initialize(msg.sender, randomSeed);
        if (currentRegionCount > 0) {
            generateInitialRegionConnections(_id);
        }

        //Mint the new token in the ledger
        _mint(msg.sender, _id, 1, "");
        tokenSupply[_id] = 1;
        currentRegionCount += 1;

        //Return new region index
        return _id;
    }

    function trustedCreateRegion()
        public
        onlyTrustedContracts
        returns (uint256 theNewRegion)
    {
        uint256 _id = internalCreateRegion();

        emit RegionCreated(uint64(_id), msg.sender, 0, uint32(block.timestamp));
        return _id;
    }

    function newRegion() public returns (uint256 theNewRegion) {
        //Calculate the fee:
        uint256 regionFee = getRegionCost(0);

        //Take fee from the owner
        transferFAME(msg.sender, address(this), regionFee);

        uint256 _id = internalCreateRegion();

        //Process the paid fee for this region
        processRegionCreationFee(_id, regionFee);

        currentRegionPricingCounter += 1;

        emit RegionCreated(
            uint64(_id),
            msg.sender,
            uint64(regionFee),
            uint32(block.timestamp)
        );
        return _id;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155 Overrides Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
        regions[_id].header.owner = _to;
    }

    function internalTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        super._safeTransferFrom(_from, _to, _id, _amount, _data);
        regions[_id].header.owner = _to;
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        require(
            (msg.sender == address(FAMEContract) && _id == FAMETokenID) ||
                msg.sender == address(this),
            "INVALID_TOKEN!"
        );
        return super.onERC1155Received(_operator, _from, _id, _amount, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BDERC1155Tradable, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // General Utility Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function processRegionCreationFee(uint256 regionID, uint256 feeAmount)
        internal
    {
        //Withhold half, in order to bank for buyback
        uint256 withheld = feeAmount / 2;
        //Send the rest to the region purse
        FAMEToRegion(regionID, feeAmount - withheld, false);
    }

    function touch(uint256 regionID) internal {
        emit RegionAltered(uint64(regionID), uint32(block.timestamp));
    }

    function setFAMEContractAddress(address newContract) public onlyOwner {
        FAMEContract = IERC1155(newContract);
    }

    function setWarriorContractAddress(address newContract) public onlyOwner {
        WarriorContract = IWarrior(newContract);
    }

    function setFAMETokenID(uint256 id) public onlyOwner {
        FAMETokenID = id;
    }

    function setRegionTaxDivisor(uint256 divisor) public onlyOwner {
        regionTaxDivisor = divisor;
    }

    function transferFAME(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        FAMEContract.safeTransferFrom(
            sender,
            recipient,
            FAMETokenID,
            amount,
            ""
        );
    }

    function FAMEToRegion(
        uint256 id,
        uint256 amount,
        bool tax
    ) internal {
        uint256 taxAmount = tax ? amount / regionTaxDivisor : 0;
        if (tax && taxAmount <= 0) taxAmount = 1;
        regions[id].header.balance += (amount - taxAmount);
        if (taxAmount > 0)
            transferFAME(address(this), regions[id].header.owner, taxAmount);
    }

    function getRegionIDByName(string memory name)
        public
        view
        returns (uint256)
    {
        return regionsByName[name];
    }

    function nameExists(string memory _name) public view returns (bool) {
        return regionNames[_name] == true;
    }

    function setName(uint256 regionID, string memory name)
        public
        ownersOnly(regionID)
    {
        //Check if the name is unique
        require(!nameExists(name));
        //Set the name
        regions[regionID].header.bytesName = LibRegion.stringToBytes32(name);
        //Add region's name to index
        regionNames[name] = true;
        regionsByName[name] = regionID;
        touch(regionID);
    }

    function addTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = true;
    }

    function removeTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = false;
    }

    function canConnectInternal(uint256 regionIDA, uint256 regionIDB)
        internal
        view
        returns (bool)
    {
        uint8 maxConnections = LibRegion.getMaxConnectionCount();
        return (regions[regionIDA].connections.length < maxConnections &&
            regions[regionIDB].connections.length < maxConnections);
    }

    function addConnectionInternal(uint256 regionIDA, uint256 regionIDB)
        internal
    {
        //Need to make sure reciprocal connection is made.
        regions[regionIDA].addConnection(regionIDB);
        regions[regionIDB].addConnection(regionIDA);
    }

    function generateInitialRegionConnections(uint256 regionID) internal {
        LibRegion.region storage r = regions[regionID];
        uint256 counter = 0;
        while (r.needsAnotherConnection()) {
            uint256 targetRegionID = (LibRegion.random(
                r.header.seed,
                counter++
            ) % currentRegionCount) + 1;
            if (canConnectInternal(regionID, targetRegionID))
                addConnectionInternal(regionID, targetRegionID);
        }
    }

    function incrementCurrentRegionPricingCounter()
        public
        onlyTrustedContracts
    {
        currentRegionPricingCounter++;
    }

    function decrementCurrentRegionPricingCounter()
        public
        onlyTrustedContracts
    {
        currentRegionPricingCounter--;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Basic Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function getCurrentRegionCount() public view returns (uint256) {
        return currentRegionCount;
    }

    function getCurrentRegionPricingCounter() public view returns (uint256) {
        return currentRegionPricingCounter;
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return regions[_id].header.owner;
    }

    function getRegionCost(int256 offset) public view returns (uint256) {
        return
            LibRegion.getRegionCost(
                uint256(int256(currentRegionPricingCounter) + offset)
            );
    }

    function getRegionName(uint256 regionID)
        public
        view
        returns (string memory)
    {
        return regions[regionID].getName();
    }

    function getRegionHeader(uint256 regionID)
        public
        view
        returns (LibRegion.regionHeader memory)
    {
        return regions[regionID].header;
    }

    function getRandomProperty(uint256 regionID, string memory propertyIndex)
        public
        view
        returns (uint256)
    {
        return regions[regionID].getRandomProperty(propertyIndex);
    }

    function getRegionConfig(uint256 regionID, uint256 configIndex)
        public
        view
        returns (uint256)
    {
        return regions[regionID].config[configIndex];
    }

    function getRegionConnections(uint256 regionID)
        public
        view
        returns (uint256[] memory)
    {
        return regions[regionID].connections;
    }

    function getRegionConnectionCount(uint256 regionID)
        public
        view
        returns (uint16)
    {
        return uint16(regions[regionID].connections.length);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

    function payRegion(
        uint256 regionID,
        uint256 amount,
        bool tax
    ) public {
        //Take sent amount from msg.sender
        transferFAME(msg.sender, address(this), amount);
        //Transfer the paid amount to the region
        FAMEToRegion(regionID, amount, tax);
        //And alert of an update to the region:
        touch(regionID);
    }

    function transferFAMEFromRegionToRegion(
        uint256 senderID,
        uint256 recipientID,
        uint256 amount,
        bool tax
    ) public onlyTrustedContracts {
        require(regions[senderID].header.balance >= amount);
        regions[senderID].header.balance -= amount;
        FAMEToRegion(recipientID, amount, tax);
        touch(senderID);
        touch(recipientID);
    }

    function transferFAMEFromWarriorToRegion(
        uint256 warriorID,
        uint256 regionID,
        uint256 amount
    ) public onlyTrustedContracts {
        WarriorContract.transferFAMEFromWarriorToAddress(
            warriorID,
            address(this),
            amount
        );
        FAMEToRegion(regionID, amount, true);
        touch(regionID);
    }

    function transferFAMEFromRegionToWarrior(
        uint256 regionID,
        uint256 warriorID,
        uint256 amount
    ) public onlyTrustedContracts {
        require(regions[regionID].header.balance >= amount);
        regions[regionID].header.balance -= amount;
        WarriorContract.payWarrior(warriorID, amount, true);
        touch(regionID);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Buy/Sell of regions
    //////////////////////////////////////////////////////////////////////////////////////////
    function sellRegion(uint256 regionID) public ownersOnly(regionID) {
        //Calculate the payout:
        uint256 regionPayout = getRegionCost(-1) / 2;

        //Take ownership of the region from the seller
        internalTransferFrom(msg.sender, address(this), regionID, 1, "");

        //Decrement the region pricing counter
        currentRegionPricingCounter -= 1;

        //Pay the Seller
        transferFAME(address(this), msg.sender, regionPayout);

        //Emit the event
        emit RegionSold(
            uint64(regionID),
            msg.sender,
            uint64(regionPayout),
            uint32(block.timestamp)
        );
    }

    function buyRegion(uint256 regionID) public {
        //Only allow buying a region that is for sale (owned by this contract)
        require(
            regions[regionID].header.owner == address(this),
            "REGION NOT FOR SALE!"
        );

        //Calculate the fee:
        uint256 regionFee = getRegionCost(0);

        //Take fee from the buyer
        transferFAME(msg.sender, address(this), regionFee);

        //Process the paid fee for this region
        processRegionCreationFee(regionID, regionFee);

        //Increment the region pricing counter
        currentRegionPricingCounter += 1;

        //Assign the region to the buyer
        internalTransferFrom(address(this), msg.sender, regionID, 1, "");

        //Emit the event
        emit RegionBought(
            uint64(regionID),
            msg.sender,
            uint64(regionFee),
            uint32(block.timestamp)
        );
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Master Setters for Updating Metadata store on Region NFTs
    //////////////////////////////////////////////////////////////////////////////////////////

    function setRegionDescription(uint256 regionID, string memory description)
        public
        ownersOnly(regionID)
    {
        regions[regionID].header.description = description;
    }

    function setRegionLinkURL(uint256 regionID, string memory url)
        public
        ownersOnly(regionID)
    {
        regions[regionID].header.linkURL = url;
    }

    function setMetaURL(uint256 regionID, string memory url)
        public
        ownersOnly(regionID)
    {
        regions[regionID].header.regionMetaURL = url;
    }

    function setConfig(
        uint256 regionID,
        uint256 index,
        uint256 value
    ) public onlyOwnersOrTrustedContracts(regionID) {
        regions[regionID].config[index] = value;
    }
}
