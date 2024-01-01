/* solhint-disable private-vars-leading-underscore */

pragma solidity 0.8.18;

import "./IERC721.sol";
import "./TokenGatedAccount.sol";
import "./TBARegistry.sol";
import "./Rewards.sol";
import "./LiquidAccessories.sol";
import "./SoulboundAccessories.sol";

contract MiladyAvatar is IERC721 {
    IERC721 public immutable miladysContract;
    LiquidAccessories public liquidAccessoriesContract;
    SoulboundAccessories public soulboundAccessoriesContract;
    Rewards public rewardsContract;
    
    // state needed for TBA address calculation
    TBARegistry public immutable tbaRegistry;
    IERC6551Account public immutable tbaAccountImpl;

    string public baseURI;

    address immutable initialDeployer;

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
    
    // main entry point for a user to change their Avatar's appearance / equip status
    // if an accessoryId's unpacked accVariant == 0, we interpret this as an unequip action
    function updateEquipSlotsByAccessoryIds(uint _miladyId, uint[] memory _accessoryIds)
        public
    {
        require(msg.sender == ownerOf(_miladyId), "Not Milady TBA");

        for (uint i=0; i<_accessoryIds.length;) {
            (uint128 accType, uint128 accVariant) = accessoryIdToTypeAndVariantIds(_accessoryIds[i]);

            _updateEquipSlotByTypeAndVariant(_miladyId, accType, accVariant);

            unchecked { i++; }
        }
    }

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

    event AccessoryEquipped(uint indexed _miladyId, uint indexed _accessoryId);

    // core function for equip logic.
    // unequips items if equip would overwrite for that accessory type
    // assumes the accessory's accVariant != 0
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

    event AccessoryUnequipped(uint indexed _miladyId, uint indexed _accessoryId);

    // core function for unequip logic
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

    // allows soulbound accessories to "auto equip" themselves upon mint
    // see `SoulboundAccessories.mintAndEquipSoulboundAccessories`
    function equipSoulboundAccessories(uint _miladyId, uint[] calldata _accessoryIds)
        external
    {
        require(msg.sender == address(soulboundAccessoriesContract), "Not soulboundAccessories");

        for (uint i=0; i<_accessoryIds.length;) {
            _equipAccessoryIfOwned(_miladyId, _accessoryIds[i]);

            unchecked { i++; }
        }
    }

    // allows soulbound accessories to unequip the item upon unmint
    // see `SoulboundAccessories.unmintAndUnequipSoulboundAccessories`
    function unequipSoulboundAccessories(uint _miladyId, uint[] calldata _accessoryIds)
        external
    {
        require(msg.sender == address(soulboundAccessoriesContract), "Not soulboundAccessories");

        for (uint i=0; i<_accessoryIds.length;) {
            (uint128 accType,) = accessoryIdToTypeAndVariantIds(_accessoryIds[i]);
            _unequipAccessoryByTypeIfEquipped(_miladyId, accType);

            unchecked { i++; }
        }
    }

    // allows liquid accessoires to "auto unequip" themselves upon transfer away
    // see `LiquidAccessories._beforeTokenTransfer`
    function preTransferUnequipById(uint _miladyId, uint _accessoryId)
        external
    {
        require(msg.sender == address(liquidAccessoriesContract), "Not liquidAccessoriesContract");

        (uint128 accType, ) = accessoryIdToTypeAndVariantIds(_accessoryId);

        _unequipAccessoryByTypeIfEquipped(_miladyId, accType);
    }


    function totalAccessoryBalanceOfAvatar(uint miladyId, uint accessoryId)
        public
        view
        returns(uint)
    {
        return
            liquidAccessoriesContract.balanceOf(getAvatarTBA(miladyId), accessoryId)
          + soulboundAccessoriesContract.balanceOf(getAvatarTBA(miladyId), accessoryId);
    }

    // get the TokenGatedAccount for a particular Milady Avatar.
    function getAvatarTBA(uint _miladyId)
        public
        view
        returns (address)
    {
        return tbaRegistry.account(address(tbaAccountImpl), block.chainid, address(this), _miladyId, 0);
    }

    function getPayableAvatarTBA(uint _miladyId)
        public
        view
        returns (address payable)
    {
        return payable(getAvatarTBA(_miladyId));
    }

    function name() external pure returns (string memory) {
        return "Milady Avatar";
    }

    function symbol() external pure returns (string memory) {
        return "MILA";
    }

    function tokenURI(uint256 _tokenId) 
        external 
        view 
        returns (string memory) 
    {
        require(_tokenId <= 9999, "Invalid Milady/Avatar id");

        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

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

    function ownerOf(uint256 _tokenId) 
        public 
        view 
        returns (address owner) 
    {
        require(_tokenId <= 9999, "Invalid Milady/Avatar id");

        return tbaRegistry.account(address(tbaAccountImpl), block.chainid, address(miladysContract), _tokenId, 0);
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external {
        revertWithSoulboundMessage();
    }
    
    function safeTransferFrom(address, address, uint256) external {
        revertWithSoulboundMessage();
    }

    function transferFrom(address, address, uint256) external {
        revertWithSoulboundMessage();
    }

    function approve(address, uint256) external {
        revertWithSoulboundMessage();
    }

    function setApprovalForAll(address, bool) external {
        revertWithSoulboundMessage();
    }

    function getApproved(uint256) external view returns (address) {
        revertWithSoulboundMessage();
    }

    function isApprovedForAll(address, address) external view returns (bool) {
        return false;
    }

    function revertWithSoulboundMessage() pure internal {
        revert("Cannot transfer soulbound tokens");
    }

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

    function plaintextAccessoryInfoToAccessoryId(PlaintextAccessoryInfo memory accInfo)
        public
        pure
        returns (uint accessoryId)
    {
        uint128 accType = uint128(uint256(keccak256(abi.encodePacked(accInfo.accType))));
        uint128 accVariant = uint128(uint256(keccak256(abi.encodePacked(accInfo.accVariant))));
        accessoryId = typeAndVariantIdsToAccessoryId(accType, accVariant);
    }

    function plaintextAccessoryTextToAccessoryId(string memory accTypeString, string memory accVariantString)
        public
        pure
        returns (uint accessoryId)
    {
        return plaintextAccessoryInfoToAccessoryId(PlaintextAccessoryInfo(accTypeString, accVariantString));
    }

    function accessoryIdToTypeAndVariantIds(uint id)
        public
        pure
        returns (uint128 accType, uint128 accVariant)
    {
        return (uint128(id >> 128), uint128(id));
    }

    function typeAndVariantIdsToAccessoryId(uint128 accType, uint128 accVariant)
        public
        pure
        returns (uint)
    {
        return (uint(accType) << 128) | uint(accVariant);
    }
}