// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

import "./BDERC1155Tradable.sol";
import "./IWarrior.sol";
import "./IRegion.sol";

//Import ERC1155 standard for utilizing FAME tokens
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

///@title LootChestCollectible
///@notice The contract for managing BattleDrome Loot Chest Tokens

contract LootChestCollectible is BDERC1155Tradable, ERC1155Holder {

    //////////////////////////////////////////////////////////////////////////////////////////
    // Config
    //////////////////////////////////////////////////////////////////////////////////////////
    
    //Fungible Token Tiers
    enum ChestType {
        NULL,
        BRONZE,
        SILVER,
        GOLD,
        DIAMOND
    }

    //Chest level multipliers are used in math throughout, this is done by taking the integerized value of ChestType
    //ie: 
    //  bronze  =   1
    //  silver  =   2
    //  gold    =   3
    //  diamond =   4
    //And then taking 2 ^ ({val}-1)
    //So the resulting multipliers would be for example:
    //  bronze  =   1
    //  silver  =   2
    //  gold    =   4
    //  diamond =   8

    //Chest Contents Constants
    //Base value is multiplied by the appropriate chest level multiplier
    uint constant FIXED_VALUE_BASE = 125;

    //Chance Constants - chance/10000 eg: 100.00%
    //This applies to the bronze level chests, each subsequent chest has chances multiplied by it's multiplier
    uint constant CHANCE_BONUS_10       = 500; //5% - Bronze,       10% - Silver,   20% - Gold,     40% - Diamond
    uint constant CHANCE_BONUS_25       = 200; //2% - Bronze,       4% - Silver,    8% - Gold,      16% - Diamond
    uint constant CHANCE_BONUS_50       = 100; //1% - Bronze,       2% - Silver,    4% - Gold,      8% - Diamond
    uint constant CHANCE_BONUS_WARRIOR  = 100; //1% - Bronze,       2% - Silver,    4% - Gold,      8% - Diamond
    uint constant CHANCE_BONUS_REGION   =   5; //0.05% - Bronze,     0.1% - Silver,  0.2% - Gold,    0.4% - Diamond   

    //Costing Constants
    uint constant ICO_BASE_FAME_VALUE = 10000000 gwei;
    uint constant NEW_FAME_PER_OLD = 1000;
    uint constant NEW_FAME_ICO_VALUE = ICO_BASE_FAME_VALUE / NEW_FAME_PER_OLD;
    uint constant VOLUME_DISCOUNT_PERCENT = 1;  //Cost break when increasing tier when calculating cost of a chest tier
                                                //ie: this percentage is multiplied by the multiplier, and applied as a discount to price
    uint constant MIN_DEMAND_RATIO =  5000; //Percent * 10000 similar to chances above
    uint constant MAX_DEMAND_RATIO = 20000; //Percent * 10000 similar to chances above

    //Other Misc Config Constants
    uint8 constant RECENT_SALES_TO_TRACK = 64;              //Max of last 32 sales
    uint constant RECENT_SALES_TIME_SECONDS = 86400 * 30;   //Max of last 30 days

    //////////////////////////////////////////////////////////////////////////////////////////
    // Structs
    //////////////////////////////////////////////////////////////////////////////////////////

    struct ChestSale {
        uint64 timestamp;
        uint8 chest_type;
        uint32 quantity;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Local Storage Variables
    //////////////////////////////////////////////////////////////////////////////////////////

    //Associated Contracts
    IERC1155 FAMEContract;
    uint256 FAMETokenID;
    IWarrior WarriorContract;
    IRegion RegionContract;

    //Sales History (Demand Tracking)
    ChestSale[RECENT_SALES_TO_TRACK] recentSales;
    uint currentSaleIndex = 0;

    //////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////////////////////////////

    constructor(address _proxyRegistryAddress)
        BDERC1155Tradable(
            "LootChestCollectible",
            "BDLC",
            _proxyRegistryAddress,
            "https://metadata.battledrome.io/api/erc1155-loot-chest/"
        )
    {
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Errors
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@notice The contract does not have sufficient FAME to support `requested` chests of type `chestType`, maximum of `maxPossible` can be created with current balance.
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@param requested The number of chests requested
    *@param maxPossible The maximum number of chests of the requested type that can be created with current balance
    */
    error InsufficientContractBalance(uint8 chestType, uint256 requested, uint256 maxPossible);

    /**
    *@notice Insufficient Ether sent for the requested action. You sent `sent` Wei but `required` Wei was required
    *@param sent The amount of Ether (in Wei) that was sent by the caller
    *@param required The amount of Ether (in Wei) that was actually required for the requested action
    */
    error InsufficientEther(uint256 sent, uint256 required);

    /**
    *@notice Insufficient Chests of type: `chestType`, you only have `balance` chests of that type!
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@param balance The number of chests the user currently has of the specified type
    */
    error InsufficientChests(uint8 chestType, uint256 balance);

    /**
    *@notice Error minting new Warrior NFT!
    *@param code Error Code
    */
    error ErrorMintingWarrior(uint code);

    /**
    *@notice Error minting new Region NFT!
    *@param code Error Code
    */
    error ErrorMintingRegion(uint code);

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@notice Indicates that a user `opener` opened `quantity` chests of type `chestType` at `timeStamp`
    *@param opener The address that opened the chests
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@param quantity The number of chests opened in this event
    *@param timeStamp the timestamp that the chests were opened
    *@param fame The amount of FAME found in the box(s)
    *@param warriors The number of warriors found in the box(s)
    *@param regions The number of regions found in the box(s)
    */
    event LootBoxOpened(address indexed opener, uint8 indexed chestType, uint32 quantity, uint32 timeStamp, uint32 fame, uint32 warriors, uint32 regions);

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155 Overrides/Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function contractURI() public pure returns (string memory) {
        return "https://metadata.battledrome.io/contract/erc1155-loot-chest";
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        require(
                (
                    (msg.sender == address(FAMEContract) && _id == FAMETokenID) ||  //Allow reciept of FAME tokens
                    msg.sender == address(RegionContract) ||                        //Allow Region Contract to send us Region NFTs (to forward to users)
                    msg.sender == address(this)                                     //Allow any internal transaction originated here
                ),
                "INVALID_TOKEN!"                                                    //Otherwise kick back INVALID_TOKEN error code, preventing the transfer.
        );
        bytes4 rv = super.onERC1155Received(_operator, _from, _id, _amount, _data);
        return rv;
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
    // Loot Box Buy/Sell
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@notice Buy a number of chests of the specified type, paying ETH
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@param quantity The number of chests to buy
    */
    function buy(ChestType chestType, uint quantity) public payable {
        //First, is it possible to buy the proposed chests? If not, then revert to prevent people wasting money
        uint maxCreatable = maxSafeCreatable(chestType);
        if(maxCreatable >= quantity){
            //We have sufficient balance to create at least the requested amount
            //So calculate the required price of the requested chests:
            uint price = getPrice(chestType) * quantity;
            //Did the user send enough?
            if(msg.value>=price){
                //Good, they paid enough... Let's mint their chests then!
                _mint(msg.sender, uint(chestType), quantity, "");
                tokenSupply[uint(chestType)] = tokenSupply[uint(chestType)] + quantity; //Because we're bypassing the normal mint function.
                ChestSale storage saleRecord = recentSales[(currentSaleIndex++)%RECENT_SALES_TO_TRACK];
                saleRecord.timestamp = uint64(block.timestamp);
                saleRecord.chest_type = uint8(chestType);
                saleRecord.quantity = uint32(quantity);  
                //Check if they overpaid and refund:
                if(msg.value>price){
                    payable(msg.sender).transfer(msg.value-price);
                }
            }else{
                //Bad monkey! Not enough money!
                revert InsufficientEther(msg.value,price);
            }
        }else{
            //Insufficient balance, throw error:
            revert InsufficientContractBalance(uint8(chestType), quantity, maxCreatable);
        }
    }

    /**
    *@notice Sell a number of FAME back to the contract, in exchange for whatever the current payout is.
    *@param quantity The number of FAME to sell
    */
    function sell(uint quantity) public {
        uint payOutAmount = getBuyBackPrice(quantity);
        transferFAME(msg.sender,address(this),quantity);
        require(address(this).balance>=payOutAmount,"CONTRACT BALANCE ERROR!");
        if(payOutAmount>0) payable(msg.sender).transfer(payOutAmount);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Loot Box Opening
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@notice Open a number of your owned chests of the specified type
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@param quantity The number of chests to open
    *@return fameReward The amount of FAME found in the chests
    *@return warriors The number of bonus Warriors found in the chests
    *@return regions The number of bonus Regions found in the chests
    */
    function open(ChestType chestType, uint quantity) public ownersOnly(uint(chestType)) returns (uint fameReward, uint warriors, uint regions) {
        //First let's confirm if the user actually owns enough chests of the appropriate type that they've requested
        uint balance = balanceOf(msg.sender, uint(chestType));
        if(balance >= quantity){
            fameReward = 0;
            warriors = 0;
            regions = 0;
            uint chestTypeMultiplier = (2**(uint(chestType)-1));
            uint baseFAMEReward = FIXED_VALUE_BASE * chestTypeMultiplier;
            //Burn the appropriate number of chests:
            _burn(msg.sender,uint(chestType),quantity);
            //Iterate the chests requested to calculate rewards
            for(uint chest=0;chest<quantity;chest++){
                //Calculate the FAME Reward amount for this chest:
                uint fameRoll = roll(chest*2+0);
                if(fameRoll<(CHANCE_BONUS_50 * chestTypeMultiplier)){
                    fameReward += baseFAMEReward * 1500 / 1000;
                }else if(fameRoll<(CHANCE_BONUS_25 * chestTypeMultiplier)){
                    fameReward += baseFAMEReward * 1250 / 1000;
                }else if(fameRoll<(CHANCE_BONUS_10 * chestTypeMultiplier)){
                    fameReward += baseFAMEReward * 1100 / 1000;
                }else{
                    fameReward += baseFAMEReward;
                }
                //Calculate if any prize (NFT) was also received in this chest:
                uint prizeRoll = roll(chest*2+1);
                if(prizeRoll<(CHANCE_BONUS_REGION * chestTypeMultiplier)){
                    //Woohoo! Won a Region! BONUS!
                    regions++;
                }else if(fameRoll<(CHANCE_BONUS_WARRIOR * chestTypeMultiplier)){
                    //Woohoo! Won a Warrior!
                    warriors++;
                }
            }
            //Ok now that we've figured out their rewards, let's give it all to them!
            //First the FAME:
            transferFAME(address(this),msg.sender,fameReward);
            //Now if there are regions or warriors in the rewards, mint the appropriate NFTs:
            for(uint w=0;w<warriors;w++){
                //Unfortunately because of how warrior minting works, we need to pre-generate some random traits:
                //  For the record this was chosen for a good reason, it's more flexible and supports a wider set of use cases
                //  But it is a bit more work when implementing in an external contract like this...
                //First let's grab a random seed:
                uint randomSeed = uint(keccak256(abi.encodePacked(block.timestamp,blockhash(block.number))));
                //And then generate the remaining traits from it
                uint16 colorHue = uint16(uint(keccak256(abi.encodePacked(randomSeed,uint8(1)))));
                uint8 armorType = uint8(uint(keccak256(abi.encodePacked(randomSeed,uint8(2)))))%4;
                uint8 shieldType = uint8(uint(keccak256(abi.encodePacked(randomSeed,uint8(3)))))%4;
                uint8 weaponType = uint8(uint(keccak256(abi.encodePacked(randomSeed,uint8(4)))))%10;
                //Now mint the warrior:
                WarriorContract.mintCustomWarrior(msg.sender, 0, true, randomSeed, colorHue, armorType, shieldType, weaponType);
            }
            for(uint r=0;r<regions;r++){
                //When minting Regions, the caller (this contract) will end up owning them, so we need to first mint, then change ownership:
                //First we try to mint:
                try RegionContract.trustedCreateRegion() returns  (uint regionID){
                    //Now we transfer it to the user:
                    RegionContract.safeTransferFrom(address(this),msg.sender,regionID,1,"");
                } catch Error(string memory reason) {
                    revert(reason);
                } catch Panic(uint code) {
                    revert ErrorMintingRegion(code);
                } catch (bytes memory) {
                    revert ErrorMintingRegion(0);
                }
            }
            emit LootBoxOpened(msg.sender, uint8(chestType), uint32(quantity), uint32(block.timestamp), uint32(fameReward), uint32(warriors), uint32(regions));
        }else{
            //Bad monkey! You don't have that many chests to open!
            revert InsufficientChests(uint8(chestType), balance);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Costing Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@notice Get the Base Value (guaranteed FAME contents) of a given chest type
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@return value The Value (amount of FAME) included in the chest type
    */
    function getBaseValue(ChestType chestType) public pure returns (uint value) {
        require(chestType > ChestType.NULL && chestType <= ChestType.DIAMOND, "ILLEGAL CHEST TYPE");
        value = FIXED_VALUE_BASE * (2**(uint(chestType)-1));
    }

    /**
    *@notice Get the recent sales volume (total amount of FAME sold in chest Base Values)
    *@return volume The total Base Value (guaranteed included FAME) of all recent chest sales
    *@dev This is used to figure out demand for costing math
    */
    function getRecentSalesVolume() public view returns (uint volume) {
        volume = 1; //To avoid div/0
        for(uint i = 0; i<RECENT_SALES_TO_TRACK; i++){
            if(recentSales[i].timestamp >= block.timestamp - RECENT_SALES_TIME_SECONDS){
                volume += getBaseValue(ChestType(recentSales[i].chest_type)) * recentSales[i].quantity;
            }
        }
    }

    /**
    *@notice Calculate the current FAME price (price per FAME token in ETH)
    *@return price The current ETH price (in wei) of a single FAME token
    *@dev This is used to calculate the "market floor" price for FAME so that we can use it to caluclate cost of chests.
    */
    function getCurrentFAMEPrice() public view returns (uint price) {
        //First we look at the current (available/non-liable) fame balance, and the recent sales volume, and calculate a demand ratio:
        //  Note: recent sales volume is always floored at the value of at least one of the max chest, which allows
        //        for the situation where there is zero supply, to incentivize seeding the supply to accommodate chest sales.
        //        Otherwise, what happens is if the contract runs dry, and no sales happen because there is no supply, the 
        //        "recent sales" drop to zero, resulting in artificially deflated demand, even though "demand" might be high, but
        //        it can't be observed because lack of supply has choked off sales. (not to mention it also helps avoid div/0)
        //ie: if we have 10,000 FAME, and we've recently only sold 1000, then we have 10:1 ratio so plenty of supply to meet the demand
        //    however if we have 1000 FAME, and recently sold 2000, we have a 0.5:1 ratio, so low supply, which should drive up price...
        //Price is calculated by first calculating demand ratio, and then clamping it to min/max range (in config constants)
        //Then taking the ICO base value of new FAME, and dividing by the demand ratio.
        //As a practical example, let's assume the ICO base value was 10,000gwei per fame, 
        //And assume we have a demand ratio clamp range of 0.5 - 2.0
        //Then the following table demonstrates how the demand ratios would equate to FAME price
        //0.5:1     - 20,000 gwei/FAME
        //0.75:1    - 13,333 gwei/FAME
        //1:1       - 10,000 gwei/FAME
        //1.25:1    - 8,000  gwei/FAME
        //1.5:1     - 6,666  gwei/FAME
        //1.75:1    - 5,714  gwei/FAME
        //2:1       - 5,000  gwei/FAME
        //Keep in mind this mechanism is designed to be a fallback to market liquidity. Ideally if the market is healthy,  then on
        //exchange sites such as OpenSea, or other token exchanges, FAME will trade for normal market value and this contract will be ignored.
        //This contract serves a purpose during ramp-up of BattleDrome, to provide a buy-in mechanism, and a sell-off mechanism to distribute
        //some of the FAME from ICO backers, to seed initial market distribution, and jump-start new players.
        //It also serves a purpose if market liquidity results in poor conditions, provided people are still interested in the tokens/game
        //As it will serve as a floor price mechanism, allowing holders to liquidate if there is some demand, and players to buy in if there is supply
        
        //Get the raw sales volume
        uint rawSalesVolume = getRecentSalesVolume();
        //Find out the minimum sales volume (cost of a diamond chest)
        uint minSalesVolume = getBaseValue(ChestType.DIAMOND);
        //Raise the sales volume if needed
        uint adjustedSalesVolume = (rawSalesVolume<minSalesVolume) ? minSalesVolume : rawSalesVolume;
        //Now we figure out our "available balance"
        uint availableBalance = getContractFAMEBalance() - calculateCurrentLiability();
        //Calculate raw demand ratio
        uint rawDemandRatio = (availableBalance * 10000) / adjustedSalesVolume;
        //Then clamp the demand ratio within min/max bounds set in constants above
        uint demandRatio = (rawDemandRatio<MIN_DEMAND_RATIO)?MIN_DEMAND_RATIO:(rawDemandRatio>MAX_DEMAND_RATIO)?MAX_DEMAND_RATIO:rawDemandRatio;
        //And finally calculate the price based on resulting demand ratio
        price = (NEW_FAME_ICO_VALUE * 10000) / demandRatio;
    }

    /**
    *@notice Calculate the current price in Ether (wei) for the specified chest type
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@return price The current ETH price (in wei) of a chest of that type
    */
    function getPrice(ChestType chestType) public view returns (uint price) {
        uint8 discountedPriceMultiplier = uint8(100 - (VOLUME_DISCOUNT_PERCENT * (2**(uint(chestType)-1))));
        price = getCurrentFAMEPrice() * getBaseValue(chestType) * discountedPriceMultiplier / 100;
    }

    /**
    *@notice Calculate the Ether Price we will pay to buy back FAME from a user (in Wei)
    *@param amount The amount of FAME tokens on offer (the total price returned will be for this full amount)
    *@return price The current ETH price (in wei) that will be paid for the full amount specified
    */
    function getBuyBackPrice(uint amount) public view returns (uint price) {
        //Determine current FAME price, and then we multiply down because our buyback percentage is 90% of current market price
        //We also multiply by the amount to find the (perfect world) amount we will pay
        price = (getCurrentFAMEPrice() * 9 / 10) * amount;
        //Now we determine the max we will pay in a single transaction (capped at 25% of our current holdings in ETH, to prevent abuse)
        //This means that if one user tries to dump a large amount to take advantage of a favorable price, they will only be paid a limited amount
        //Forcing them to reduce their transaction (or risk being under-paid), and do a second transaction.
        uint maxPayout = address(this).balance / 4;
        //Next we cap the payout based on the maxPayout:
        price = price > maxPayout ? maxPayout : price;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Utility Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    /**
    *@dev Internal Helper Function to determine random roll when opening chests. Crude RNG, should be good enough, but is manipulable by miner theoretically
    *@param seedOffset Integer seed offset used for additional randomization
    *@return result Random roll from 0-10000 (random percentage to 2 decimal places)
    */
    function roll(uint seedOffset) internal view returns (uint16 result) {
        uint randomUint = uint(keccak256(abi.encodePacked(block.timestamp,blockhash(block.number),seedOffset)));
        result = uint16(randomUint % 10000);
    }

    /**
    *@notice ADMIN FUNCTION: Update the FAME Token ERC1155 Contract Address
    *@param newContract The address of the new contract
    */
    function setFAMEContractAddress(address newContract) public onlyOwner {
        FAMEContract = IERC1155(newContract);
    }

    /**
    *@notice ADMIN FUNCTION: Set the internal Token ID for FAME Tokens within the ERC1155 Contract
    *@param id The new Token ID
    */
    function setFAMETokenID(uint256 id) public onlyOwner {
        FAMETokenID = id;
    }

    /**
    *@notice ADMIN FUNCTION: Update the Warrior NFT ERC1155 Contract Address
    *@param newContract The address of the new contract
    */
    function setWarriorContractAddress(address newContract) public onlyOwner {
        WarriorContract = IWarrior(newContract);
    }
    
    /**
    *@notice ADMIN FUNCTION: Update the Region NFT ERC1155 Contract Address
    *@param newContract The address of the new contract
    */
    function setRegionContractAddress(address newContract) public onlyOwner {
        RegionContract = IRegion(newContract);
    }

    /**
    *@dev Utility/Helper function for internal use whenever we need to transfer fame between 2 addresses
    *@param sender The Sender Address (address from which the FAME will be deducted)
    *@param recipient The Recipient Address (address to which the FAME will be credited)
    *@param amount The amount of FAME tokens to transfer
    */
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

    /**
    *@notice Fetch the current FAME balance held within the Loot Chest Smart Contract
    *@return balance The current FAME Token Balance
    */
    function getContractFAMEBalance() public view returns (uint balance) {
        return FAMEContract.balanceOf(address(this),FAMETokenID);
    }

    /**
    *@dev Utility/Helper function for internal use, helps determine the worst case liability of a given chest type (amount of FAME that needs paying out)
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@return fame_liability The liability (amount of FAME this countract could potentially be expected to pay out in the worst case, or maximum reward scenario)
    */
    function calculateChestLiability(ChestType chestType) internal pure returns (uint fame_liability) {
        return getBaseValue(chestType) * 1500 / 1000;
    }

    /**
    *@notice The current total liability of this contract (total FAME that would be required to be paid out if all current chests in circulation contain the max reward)
    *@return fame_liability The current total liability (total FAME payout required in worse case from all chests in circulation)
    */
    function calculateCurrentLiability() public view returns (uint fame_liability) {
        for(uint8 ct=uint8(ChestType.BRONZE);ct<=uint8(ChestType.DIAMOND);ct++)
        {
            //Get current chest count of chest type
            uint chestCount = totalSupply(ct);
            //Then multiply by the liability of that chest type
            fame_liability += chestCount * calculateChestLiability(ChestType(ct));
        }
    }

    /**
    *@notice Checks based on current FAME balance, and current total liability, the max number of specified chestType that can be created safely (factoring in new liability for requested chests)
    *@param chestType The type of chest (1=Bronze,2=Silver,3=Gold,4=Diamond)
    *@return maxQuantity Maximum quantity of chests of specified type, that can be created safely based on current conditions.
    */
    function maxSafeCreatable(ChestType chestType) public view returns (uint maxQuantity) {
        maxQuantity = 0;
        uint currentLiability = calculateCurrentLiability();
        uint currentBalance = getContractFAMEBalance();
        if(currentLiability < currentBalance){
            uint freeBalance = currentBalance - currentLiability;
            maxQuantity = freeBalance / calculateChestLiability(chestType);
        }
    }

}
