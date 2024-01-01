/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./TokenGatedAccount.sol";
import "./TBARegistry.sol";
import "./Rewards.sol";
import "./LiquidAccessories.sol";
import "./SoulboundAccessories.sol";

/**
 * @title MiladyAvatar
 * @notice A contract to manage Avatars, their equipment and interactions with accessories in the Milady OS ecosystem.
 * @dev Inherits from IERC721 and ReentrancyGuard. Interacts with LiquidAccessories, SoulboundAccessories, and Rewards contracts to facilitate accessory management and reward distribution.
 * @author Logan Brutsche
 */
contract MiladyAvatar is IERC721, ReentrancyGuard {
    IERC721 public immutable miladysContract;
    LiquidAccessories public liquidAccessoriesContract;
    SoulboundAccessories public soulboundAccessoriesContract;
    Rewards public rewardsContract;
    
    // state needed for TBA address calculation
    TBARegistry public immutable tbaRegistry;
    IERC6551Account public immutable tbaAccountImpl;

    string public baseURI;

    address immutable initialDeployer;

    /**
     * @notice Initializes the contract with the specified Milady's contract, TBARegistry, TBA Account Implementation and base URI.
     * @param _miladysContract The address of the Milady's contract.
     * @param _tbaRegistry The address of the TBARegistry.
     * @param _tbaAccountImpl The address of the TBA Account Implementation.
     * @param _baseURI The base URI for the ERC721 token.
     */
    constructor(
            IERC721 _miladysContract,
            TBARegistry _tbaRegistry,
            TokenGatedAccount _tbaAccountImpl,
            string memory _baseURI
    ) {
        initialDeployer = msg.sender;
        miladysContract = _miladysContract;
        tbaRegistry = _tbaRegistry;
        tbaAccountImpl = _tbaAccountImpl;
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the address of the LiquidAccessories, SoulboundAccessories, and Rewards contracts. Can only be called once and by the initial deployer.
     * @param _liquidAccessoriesContract The address of the LiquidAccessories contract.
     * @param _soulboundAccessoriesContract The address of the SoulboundAccessories contract.
     * @param _rewardsContract The address of the Rewards contract.
     */
    function setOtherContracts(
            LiquidAccessories _liquidAccessoriesContract, 
            SoulboundAccessories _soulboundAccessoriesContract, 
            Rewards _rewardsContract)
        external
    {
        require(msg.sender == initialDeployer, "Caller not initial deployer");
        require(address(liquidAccessoriesContract) == address(0), "Contracts already set");
        
        liquidAccessoriesContract = _liquidAccessoriesContract;
        soulboundAccessoriesContract = _soulboundAccessoriesContract;
        rewardsContract = _rewardsContract;
    }

    // indexed by miladyId -> accessoryType
    mapping (uint => mapping (uint128 => uint)) public equipSlots;
    
    /**
     * @notice Allows a user to update their Avatar's equipment by providing accessory IDs. 
     * This is the main entry point for a user to change their Avatar's appearance / equip status
     * if an accessoryId's unpacked accVariant == 0, we interpret this as an unequip action.
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessoryIds Array of accessory IDs to equip/unequip.
     */
    function updateEquipSlotsByAccessoryIds(uint _miladyId, uint[] memory _accessoryIds)
        public
        nonReentrant
    {
        require(msg.sender == ownerOf(_miladyId), "Not Milady TBA");

        for (uint i=0; i<_accessoryIds.length;) {
            (uint128 accType, uint128 accVariant) = accessoryIdToTypeAndVariantIds(_accessoryIds[i]);

            _updateEquipSlotByTypeAndVariant(_miladyId, accType, accVariant);

            unchecked { i++; }
        }
    }

    /**
     * @notice Internal function to update an equip slot by accessory type and variant.
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accType The type of the accessory.
     * @param _accVariantOrNull The variant of the accessory or 0 for unequip action.
     */
    function _updateEquipSlotByTypeAndVariant(uint _miladyId, uint128 _accType, uint128 _accVariantOrNull)
        internal
    {
        if (_accVariantOrNull == 0) {
            _unequipAccessoryByTypeIfEquipped(_miladyId, _accType);
        }
        else {
            uint accessoryId = typeAndVariantIdsToAccessoryId(_accType, _accVariantOrNull);
            _equipAccessoryIfOwned(_miladyId, accessoryId);
        }
    }

    /**
     * @notice The event emitted when an accessory is equipped.
     * @param _miladyId Milady that equiped the accessory
     * @param _accessoryId  The ID of the accessory that was equiped
     */
    event AccessoryEquipped(uint indexed _miladyId, uint indexed _accessoryId);

    
    /**
     * @notice Internal function to equip an accessory if owned by the Avatar.
     * @dev The core function for equip logic.
     * Unequips items if equip would overwrite for that accessory type 
     * assumes the accessory's accVariant != 0
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessoryId The ID of the accessory to equip.
     * @dev Assumes the accessory's accVariant != 0.
     */
    function _equipAccessoryIfOwned(uint _miladyId, uint _accessoryId)
        internal
    {
        require(totalAccessoryBalanceOfAvatar(_miladyId, _accessoryId) > 0, "Not accessory owner");

        (uint128 accType, uint accVariant) = accessoryIdToTypeAndVariantIds(_accessoryId);
        require(accVariant != 0);

        _unequipAccessoryByTypeIfEquipped(_miladyId, accType);

        equipSlots[_miladyId][accType] = _accessoryId;
        
        rewardsContract.registerMiladyForRewardsForAccessory(_miladyId, _accessoryId);

        emit AccessoryEquipped(_miladyId, _accessoryId);
    }

    /**
     * @notice The event emitted when an accessory is unequipped.
     * @param _miladyId Milady that equiped the accessory
     * @param _accessoryId The ID of the accessory that was equiped
     */
    event AccessoryUnequipped(uint indexed _miladyId, uint indexed _accessoryId);

    /**
     * @notice Internal function to unequip an accessory by type if it's equipped.
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accType The type of the accessory to unequip.
     */
    function _unequipAccessoryByTypeIfEquipped(uint _miladyId, uint128 _accType)
        internal
    {
        // if "something" is equiped in this slot
        if (equipSlots[_miladyId][_accType] != 0) { 
            rewardsContract.deregisterMiladyForRewardsForAccessoryAndClaim(_miladyId, equipSlots[_miladyId][_accType], getPayableAvatarTBA(_miladyId));

            emit AccessoryUnequipped(_miladyId, equipSlots[_miladyId][_accType]);

            equipSlots[_miladyId][_accType] = 0;
        }
    }

    /**
     * @notice Allows soulbound accessories to "auto equip" themselves upon mint.
     * @dev See `SoulboundAccessories.mintAndEquipSoulboundAccessories`
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessoryIds Array of accessory IDs to equip.
     */
    function equipSoulboundAccessories(uint _miladyId, uint[] calldata _accessoryIds)
        external
        nonReentrant
    {
        require(msg.sender == address(soulboundAccessoriesContract), "Not soulboundAccessories");

        for (uint i=0; i<_accessoryIds.length;) {
            _equipAccessoryIfOwned(_miladyId, _accessoryIds[i]);

            unchecked { i++; }
        }
    }

    /**
     * @notice Allows soulbound accessories to unequip themselves upon unmint.
     * @dev See `SoulboundAccessories.unmintAndUnequipSoulboundAccessories`
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessoryIds Array of accessory IDs to unequip.
     */
    function unequipSoulboundAccessories(uint _miladyId, uint[] calldata _accessoryIds)
        external
        nonReentrant
    {
        require(msg.sender == address(soulboundAccessoriesContract), "Not soulboundAccessories");

        for (uint i=0; i<_accessoryIds.length;) {
            (uint128 accType,) = accessoryIdToTypeAndVariantIds(_accessoryIds[i]);
            _unequipAccessoryByTypeIfEquipped(_miladyId, accType);

            unchecked { i++; }
        }
    }

    /**
     * @notice Allows liquid accessories to "auto unequip" themselves upon transfer away.
     * @dev See `LiquidAccessories._beforeTokenTransfer`
     * @param _miladyId The ID of the Milady Avatar.
     * @param _accessoryId The ID of the accessory to unequip.
     */
    function preTransferUnequipById(uint _miladyId, uint _accessoryId)
        external
        nonReentrant
    {
        require(msg.sender == address(liquidAccessoriesContract), "Not liquidAccessoriesContract");

        (uint128 accType, ) = accessoryIdToTypeAndVariantIds(_accessoryId);

        _unequipAccessoryByTypeIfEquipped(_miladyId, accType);
    }

    /**
     * @notice Retrieves the total balance of a specific accessory owned by a particular Avatar.
     * @param miladyId The ID of the Milady Avatar.
     * @param accessoryId The ID of the accessory.
     * @return The total balance of the specified accessory.
     */
    function totalAccessoryBalanceOfAvatar(uint miladyId, uint accessoryId)
        public
        view
        returns(uint)
    {
        return
            liquidAccessoriesContract.balanceOf(getAvatarTBA(miladyId), accessoryId)
          + soulboundAccessoriesContract.balanceOf(getAvatarTBA(miladyId), accessoryId);
    }

    /**
     * @notice Retrieves the TokenGatedAccount for a particular Milady Avatar.
     * @param _miladyId The ID of the Milady Avatar.
     * @return The address of the TokenGatedAccount.
     */
    function getAvatarTBA(uint _miladyId)
        public
        view
        returns (address)
    {
        return tbaRegistry.account(address(tbaAccountImpl), block.chainid, address(this), _miladyId, 0);
    }

    /**
     * @notice Retrieves the payable TokenGatedAccount for a particular Milady Avatar.
     * @param _miladyId The ID of the Milady Avatar.
     * @return The payable address of the TokenGatedAccount.
     */
    function getPayableAvatarTBA(uint _miladyId)
        public
        view
        returns (address payable)
    {
        return payable(getAvatarTBA(_miladyId));
    }

    /**
     * @notice Retrieves the name of the contract.
     * @return The name "Milady Avatar".
     */
    function name() external pure returns (string memory) {
        return "Milady Avatar";
    }

    function symbol() external pure returns (string memory) {
        return "MILA";
    }

    /**
     * @notice Retrieves the symbol of the contract.
     * @return The symbol "MILA".
     */
    function tokenURI(uint256 _tokenId) 
        external 
        view 
        returns (string memory) 
    {
        require(_tokenId <= 9999, "Invalid Milady/Avatar id");

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice Retrieves the balance of a particular address.
     * @param _who The address to query.
     * @return balance The balance of the address.
     */
    function balanceOf(address _who) 
        external 
        view 
        returns 
        (uint256 balance) 
    {
        (address tbaContractAddress,) = tbaRegistry.registeredAccounts(_who);
        if (tbaContractAddress == address(miladysContract)) {
            return 1;
        }
        else return 0;
    }
    
    /**
     * @notice Retrieves the owner of a particular token ID.
     * @param _tokenId The ID of the token.
     * @return owner The address of the owner.
     */
    function ownerOf(uint256 _tokenId) 
        public 
        view 
        returns (address owner) 
    {
        require(_tokenId <= 9999, "Invalid Milady/Avatar id");

        return tbaRegistry.account(address(tbaAccountImpl), block.chainid, address(miladysContract), _tokenId, 0);
    }

    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function safeTransferFrom(address, address, uint256, bytes calldata) external {
        revertWithSoulboundMessage();
    }
    
    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function safeTransferFrom(address, address, uint256) external {
        revertWithSoulboundMessage();
    }

    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function transferFrom(address, address, uint256) external {
        revertWithSoulboundMessage();
    }

    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function approve(address, uint256) external {
        revertWithSoulboundMessage();
    }

    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function setApprovalForAll(address, bool) external {
        revertWithSoulboundMessage();
    }

    /**
     * @notice Reverts with a message indicating that soulbound tokens cannot be transferred.
     */
    function getApproved(uint256) external view returns (address) {
        revertWithSoulboundMessage();
    }

    /**
     * @notice Always false.
     */
    function isApprovedForAll(address, address) external view returns (bool) {
        return false;
    }

    /**
     * @notice Internal function to revert any transaction with a message indicating the non-transferability of soulbound tokens.
     */
    function revertWithSoulboundMessage() pure internal {
        revert("Cannot transfer soulbound tokens");
    }

    /**
     * @notice Checks if the contract supports a particular interface.
     * @param interfaceId The ID of the interface.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    // accessory utils

    // the remaining functions describe the scheme whereby hashes (treated as IDs) of an accessory type and accessory variant
    // are encoded into the same uint256 that is used for a global ID for a particular accessory

    // an ID's upper 128 bits are the truncated hash of the category text;
    // the lower 128 bits are the truncated hash of the variant test

    struct PlaintextAccessoryInfo {
        string accType;
        string accVariant;
    }

    
    /**
     * @notice Converts an array of PlaintextAccessoryInfo structs to an array of accessory IDs.
     * @param accInfos An array of PlaintextAccessoryInfo structs.
     * @return accIds An array of accessory IDs.
     */
    function batchPlaintextAccessoryInfoToAccessoryIds(PlaintextAccessoryInfo[] memory accInfos)
        public
        pure
        returns (uint[] memory accIds)
    {
        accIds = new uint[](accInfos.length);
        for (uint i=0; i<accInfos.length;)
        {
            accIds[i] = plaintextAccessoryInfoToAccessoryId(accInfos[i]);

            unchecked { i++; }
        }
    }

    /**
     * @notice Converts a PlaintextAccessoryInfo struct to an accessory ID.
     * @dev The accType is derived from hashing the accessory type's plaintext description string.
     * @dev The accVariant is derived from hashing the accessory variant's plaintext description string.
     * @dev The accessory ID is derived from the accType and accVariant, both uint128, packed into a uint256.
     * @param accInfo A PlaintextAccessoryInfo struct.
     * @return accessoryId The accessory ID derived from the plaintext info.
     */
    function plaintextAccessoryInfoToAccessoryId(PlaintextAccessoryInfo memory accInfo)
        public
        pure
        returns (uint accessoryId)
    {
        uint128 accType = uint128(uint256(keccak256(abi.encodePacked(accInfo.accType))));
        uint128 accVariant = uint128(uint256(keccak256(abi.encodePacked(accInfo.accVariant))));
        accessoryId = typeAndVariantIdsToAccessoryId(accType, accVariant);
    }

    /**
     * @notice Converts plain text accessory type and variant strings to an accessory ID.
     * @param accTypeString A string representing the accessory type.
     * @param accVariantString A string representing the accessory variant.
     * @return accessoryId The accessory ID derived from the plaintext strings.
     */
    function plaintextAccessoryTextToAccessoryId(string memory accTypeString, string memory accVariantString)
        public
        pure
        returns (uint accessoryId)
    {
        return plaintextAccessoryInfoToAccessoryId(PlaintextAccessoryInfo(accTypeString, accVariantString));
    }

    /**
     * @notice Decodes an accessory ID into its type and variant IDs.
     * @param id The accessory ID.
     * @return accType The accessory type ID.
     * @return accVariant The accessory variant ID.
     */
    function accessoryIdToTypeAndVariantIds(uint id)
        public
        pure
        returns (uint128 accType, uint128 accVariant)
    {
        return (uint128(id >> 128), uint128(id));
    }

    /**
     * @notice Encodes accessory type and variant IDs, both uint128, into a single accessory ID.
     * @param accType The accessory type ID.
     * @param accVariant The accessory variant ID.
     * @return The accessory ID.
     */
    function typeAndVariantIdsToAccessoryId(uint128 accType, uint128 accVariant)
        public
        pure
        returns (uint)
    {
        return (uint(accType) << 128) | uint(accVariant);
    }
}