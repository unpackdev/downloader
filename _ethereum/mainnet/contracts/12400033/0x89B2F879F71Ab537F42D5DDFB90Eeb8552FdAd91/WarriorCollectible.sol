// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC1155Tradable.sol";
import "./LibWarrior.sol";

//Import ERC1155 standard for utilizing FAME tokens
import "./IERC1155.sol"; //Token interface for interacting with token contracts

/**
 * @title WarriorCollectible
 * WarriorCollectible - The contract for managing BattleDrome Warrior NFTs
 */

contract WarriorCollectible is ERC1155Tradable {

    using LibWarrior for LibWarrior.warrior;

    mapping(uint256=>LibWarrior.warrior) warriors;
	mapping(string=>bool) warriorNames;
	mapping(string=>uint) warriorsByName;
    mapping(address=>bool) trustedContracts;

    IERC1155 FAMEContract;
    uint256 FAMETokenID;
    uint256 warriorTaxDivisor;

    constructor(address _proxyRegistryAddress)
        ERC1155Tradable(
        "WarriorCollectible",
        "WAR",
        _proxyRegistryAddress
    ) public {
        _setBaseMetadataURI("https://metadata.battledrome.io/api/erc1155-warrior/");
        warriorTaxDivisor = 100;
    }

    function contractURI() public pure returns (string memory) {
        return "https://metadata.battledrome.io/contract/erc1155-warrior";
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////////////////////////////
    
	modifier onlyTrustedContracts() {
		//Check that the message came from a Trusted Contract
		require(trustedContracts[msg.sender]);
		_;
	}
    
	modifier onlyState(uint warriorID, LibWarrior.warriorState state) {
		require(warriors[warriorID].state == state);
		_;
	}

	modifier costsPoints(uint warriorID, uint _points) {
        require(warriors[warriorID].stats.points >= uint64(_points));
        warriors[warriorID].stats.points -= uint64(_points);
        _;
    }

    modifier notWhileTraining(uint warriorID) {
        require(block.timestamp > warriors[warriorID].trainingUntil);
        _;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////////////////////////////////////////////

    event WarriorAltered(
        uint64 indexed warrior,
        uint32 timeStamp
        );
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Warrior Factory
    //////////////////////////////////////////////////////////////////////////////////////////

    //Custom Minting Function for utility (to be called by trusted contracts)
	function mintCustomWarrior(address owner, uint32 generation, bool special, uint randomSeed, uint16 colorHue, uint8 armorType, uint8 shieldType, uint8 weaponType) public onlyTrustedContracts returns(uint theNewWarrior) {
        //Calculate new Token ID for minting
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        //Log the original creator of this warrior
        creators[_id] = owner;
		//Generate a new warrior metadata structure, and add it to the warriors array
        warriors[_id]=LibWarrior.newWarriorFixed(owner, generation, special, randomSeed, colorHue, armorType, shieldType, weaponType);
        //Mint the new token in the ledger
        _mint(owner, _id, 1, "");
        tokenSupply[_id] = 1;
		//Return new warrior index
        return _id;
	}

    //Standard factory function, allowing minting warriors.
	function newWarrior() public returns(uint theNewWarrior) {
        //Generate a new random seed for the warrior
        uint randomSeed = uint(blockhash(block.number - 1));    //YES WE KNOW this isn't truely random. it's predictable, and vulnerable to malicious miners... 
                                                                //Doesn't actually matter in this case. That's all ok. It's only for generating cosmetics etc...
        //Calculate the fee:
        uint warriorFee = LibWarrior.getWarriorCost();

        //Take fee from the owner
        transferFAME(msg.sender,address(this),warriorFee);

        //Calculate new Token ID for minting
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        //Log the original creator of this warrior
        creators[_id] = msg.sender;

		//Generate a new warrior metadata structure, and add it to the warriors array
        warriors[_id]=LibWarrior.newWarrior(msg.sender, randomSeed);

		//Transfer the paid fee to the warrior as initial starting FAME
        FAMEToWarrior(_id,warriorFee,false);

        //Mint the new token in the ledger
        _mint(msg.sender, _id, 1, "");
        tokenSupply[_id] = 1;

		//Return new warrior index
        return _id;
	}

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155 Overrides for custom functionality
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public {        
        super.safeTransferFrom(_from,_to,_id,_amount,_data);
        warriors[_id].owner = _to;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // ERC1155Receiver Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external view returns(bytes4) {
        require(msg.sender == address(FAMEContract) && _id == FAMETokenID, "INVALID_TOKEN!");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // General Utility Functions
    //////////////////////////////////////////////////////////////////////////////////////////

    function touch(uint warriorID) internal {
        emit WarriorAltered(uint64(warriorID),uint32(block.timestamp));
    }

    function setFAMEContractAddress(address newContract) public onlyOwner {
        FAMEContract = IERC1155(newContract);
    }

    function setFAMETokenID(uint256 id) public onlyOwner {
        FAMETokenID = id;
    }
    
    function setWarriorTaxDivisor(uint256 divisor) public onlyOwner {
        warriorTaxDivisor = divisor;
    }

    function transferFAME(address sender, address recipient, uint256 amount) internal {
        FAMEContract.safeTransferFrom(sender, recipient, FAMETokenID, amount, "");
    }

    function FAMEToWarrior(uint256 id, uint256 amount, bool tax) internal {
        uint256 taxAmount = tax ? amount/warriorTaxDivisor : 0; 
        if (tax && taxAmount<=0) taxAmount = 1;
        warriors[id].balance += (amount - taxAmount);
        if(taxAmount>0) transferFAME(address(this),warriors[id].owner,taxAmount);
    }

	function getWarriorIDByName(string memory name) public view returns(uint) {
		return warriorsByName[name];
	}

    function nameExists(string memory _name) public view returns(bool) {
        return warriorNames[_name] == true;
    }

    function setName(uint warriorID, string memory name) public ownersOnly(warriorID) {
		//Check if the name is unique
		require(!nameExists(name));
        //Set the name
        warriors[warriorID].bytesName = LibWarrior.stringToBytes32(name);
        //Add warrior's name to index
        warriorNames[name] = true;
        warriorsByName[name] = warriorID;
        touch(warriorID);
    }

    function addTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = true;
    }

    function removeTrustedContract(address trustee) public onlyOwner {
        trustedContracts[trustee] = false;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Basic Getters
    //////////////////////////////////////////////////////////////////////////////////////////

    function ownerOf(uint _id) public view returns(address) {
        return warriors[_id].owner;
    }

    function getWarriorCost() public pure returns(uint) {
        return LibWarrior.getWarriorCost();
    }

    function getWarriorName(uint warriorID) public view returns(string memory) {
        return warriors[warriorID].getName();
    }

    function getWarrior(uint warriorID) public view returns(LibWarrior.warrior memory) {
        return warriors[warriorID];
    }

    function getWarriorStats(uint warriorID) public view returns(LibWarrior.warriorStats memory) {
        return warriors[warriorID].stats;
    }

    function getWarriorEquipment(uint warriorID) public view returns(LibWarrior.warriorEquipment memory) {
        return warriors[warriorID].equipment;
    }

    function getCosmeticProperty(uint warriorID, uint propertyIndex) public view returns (uint48) {
        return uint48(warriors[warriorID].getCosmeticProperty(propertyIndex));
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Transaction/Payment Handling
    //////////////////////////////////////////////////////////////////////////////////////////

	function payWarrior(uint warriorID, uint amount, bool tax) public {
        //Take sent amount from msg.sender
        transferFAME(msg.sender,address(this),amount);
		//Transfer the paid amount to the warrior
        FAMEToWarrior(warriorID,amount,tax);
        //And alert of an update to the warrior:
        touch(warriorID);
	}

    function transferFAMEFromWarriorToWarrior(uint senderID, uint recipientID, uint amount, bool tax) public onlyTrustedContracts {
        require(warriors[senderID].balance >= amount);
        warriors[senderID].balance -= amount;
        FAMEToWarrior(recipientID,amount,tax);
        touch(senderID);
        touch(recipientID);        
    }

    function transferFAMEFromWarriorToAddress(uint warriorID, address recipient, uint amount) public onlyTrustedContracts {
        require(warriors[warriorID].balance >= amount);
        warriors[warriorID].balance -= amount;
        transferFAME(address(this),recipient,amount);
        touch(warriorID);
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    // Master Setters for Updating Metadata store on Warrior NFTs
    //////////////////////////////////////////////////////////////////////////////////////////

    function setWarriorState(uint warriorID, LibWarrior.warriorState _warriorState, uint32 _trainingUntil) public onlyTrustedContracts {
        warriors[warriorID].state = _warriorState;
        warriors[warriorID].trainingUntil = _trainingUntil;
        touch(warriorID);
    }

    function setWarriorStats(uint warriorID, LibWarrior.warriorStats memory _statsData) public onlyTrustedContracts {
        warriors[warriorID].stats = _statsData;
        touch(warriorID);
    }

    function setWarriorEquipment(uint warriorID, LibWarrior.warriorEquipment memory _equipmentData) public onlyTrustedContracts {
        warriors[warriorID].equipment = _equipmentData;
        touch(warriorID);
    }

}
