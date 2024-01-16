pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IMembershipRegistry.sol";
import "./StakeHouseUniverse.sol";
import "./BaseModuleGuards.sol";
import "./FlagHelper.sol";

/// @title StakeHouse core member registry. Functionality is built around this core
/// @dev Every member is known as a KNOT and the StakeHouse is a collection of KNOTs
contract StakeHouseRegistry is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IMembershipRegistry, BaseModuleGuards {
    using FlagHelper for uint16;

    /// @notice Index pointer used to assign every member an index coordinate starting at 1
    uint256 public memberKNOTIndexPointer;

    /// @notice Total number of KNOTs that have rage quit from the house
    uint256 public numberOfRageQuitKnots;

    /// @notice Total number of KNOTs that have been kicked from the house
    uint256 public numberOfKickedKnots;

    /// @notice Member metadata struct - taking advantage of packing
    struct MemberInfo {
        uint160 applicant; // address of account that applied to add the KNOT to the StakeHouse registry
        uint80 knotMemberIndex; // index integer assigned to KNOT when added to the StakeHouse
        uint16 flags; // flags tracking the state of the KNOT i.e. whether active, kicked and or rage quit
    }

    /// @notice Member information packed into 1 var - ETH 1 applicant address, KNOT index pointer and flag info
    mapping(bytes => MemberInfo) public memberIDToMemberInfo;

    /// @notice KNOT index pointer to member ID (Validator pub key)
    mapping(uint256 => bytes) public memberIndexToMemberId;

    /// @notice Address of the member gate keeper smart contract or address(0) if not enabled
    IGateKeeper public gateKeeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(StakeHouseUniverse _universe) external initializer {
        __initModuleGuards(_universe);
        __ReentrancyGuard_init();
        __Ownable_init();
    }

    /// @inheritdoc IMembershipRegistry
    function setGateKeeper(IGateKeeper _gateKeeper) external onlyOwner override {
        require(address(universe) != address(0), "Only proxy");
        gateKeeper = _gateKeeper;
    }

    /// @inheritdoc IMembershipRegistry
    function isMemberPermitted(bytes calldata _blsPubKey) external override view returns (bool) {
        if (address(gateKeeper) != address(0)) {
            return gateKeeper.isMemberPermitted(_blsPubKey);
        }

        // if no gatekeeper, members are always permitted
        return true;
    }

    /// @inheritdoc IMembershipRegistry
    function addMember(address _applicant, bytes calldata _memberId) override external onlyModule nonReentrant {
        require(_applicant != address(0), "Invalid applicant");
        require(_memberId.length == 48, "Invalid member ID");
        require(msg.sender == address(universe), "Only banking");
        require(memberIDToMemberInfo[_memberId].knotMemberIndex == 0, "Member already added");
        require(universe.memberKnotToStakeHouse(_memberId) == address(this), "Member added to another StakeHouse");

        if (memberKNOTIndexPointer == 0) {
            // Give the house creator ownership over ability to set a gate keeper
            transferOwnership(_applicant);
        }

        // Increment the index pointer for a StakeHouse - this will equal total number of members for a StakeHouse
        unchecked { // number of members in a single house unlikely to exceed ( (2 ^ 256) - 1 )
            memberKNOTIndexPointer += 1;
        }

        // Assign the new index pointer to the StakeHouse member
        memberIndexToMemberId[memberKNOTIndexPointer] = _memberId;

        // Store the member info as a nicely packed variable for GAS savings
        memberIDToMemberInfo[_memberId] = MemberInfo({
            applicant: uint160(_applicant),
            knotMemberIndex: uint80(memberKNOTIndexPointer),
            flags: uint16(1) // this means the KNOT is active
        });

        emit MemberAdded(memberKNOTIndexPointer);
    }

    /// @inheritdoc IMembershipRegistry
    function kick(bytes calldata _memberId) external override onlyModule {
        uint16 flags = memberIDToMemberInfo[_memberId].flags;
        require(flags.exists(), "Specified member does not exist");

        if (!flags.isKicked()) {
            unchecked {
                numberOfKickedKnots += 1;
            }

            memberIDToMemberInfo[_memberId].flags = memberIDToMemberInfo[_memberId].flags.kickMember();

            emit MemberKicked(memberIDToMemberInfo[_memberId].knotMemberIndex);
        }
    }

    /// @inheritdoc IMembershipRegistry
    function rageQuit(bytes calldata _memberId) external override onlyModule {
        uint16 flags = memberIDToMemberInfo[_memberId].flags;
        require(flags.exists(), "Specified member does not exist");
        require(!flags.hasRageQuit(), "Member has already rage quit");

        unchecked {
            numberOfRageQuitKnots += 1;
        }

        memberIDToMemberInfo[_memberId].flags = memberIDToMemberInfo[_memberId].flags.rageQuit();

        emit MemberRageQuit(memberIDToMemberInfo[_memberId].knotMemberIndex);
    }

    /// @inheritdoc IMembershipRegistry
    function numberOfMemberKNOTs() external override view returns (uint256) {
        return memberKNOTIndexPointer;
    }

    /// @inheritdoc IMembershipRegistry
    function numberOfActiveKNOTsThatHaveNotRageQuit() external override view returns (uint256 active) {
        unchecked {
            active = memberKNOTIndexPointer - numberOfRageQuitKnots;
        }
    }

    /// @inheritdoc IMembershipRegistry
    function isActiveMember(bytes calldata _memberId) override external view returns (bool) {
        return _isActiveMember(_memberId, memberIDToMemberInfo[_memberId].flags);
    }

    /// @inheritdoc IMembershipRegistry
    function hasMemberRageQuit(bytes calldata _memberId) public override view returns (bool) {
        uint16 _memberFlags = memberIDToMemberInfo[_memberId].flags;
        require(_memberFlags.exists(), "Invalid member");
        return _memberFlags.exists()
            && _memberFlags.hasRageQuit()
            && universe.memberKnotToStakeHouse(_memberId) == address(this);
    }

    /// @inheritdoc IMembershipRegistry
    function getMemberInfoAtIndex(uint256 _memberKNOTIndex) public override view returns (
        address applicant,
        uint256 knotMemberIndex,
        uint16 flags,
        bool isActive
    ) {
        require(_memberKNOTIndex > 0, "Index ID cannot be zero");
        require(_memberKNOTIndex <= memberKNOTIndexPointer, "Invalid index");
        return getMemberInfo(memberIndexToMemberId[_memberKNOTIndex]);
    }

    /// @inheritdoc IMembershipRegistry
    function getMemberInfo(bytes memory _memberId) public override view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    ) {
        MemberInfo storage memberInfo = memberIDToMemberInfo[_memberId];
        applicant = address(memberInfo.applicant);
        knotMemberIndex = uint256(memberInfo.knotMemberIndex);
        flags = memberInfo.flags;
        isActive = _isActiveMember(_memberId, flags);
    }

    /// @dev given member flag values, determines if a member is active or not
    function _isActiveMember(bytes memory _memberId, uint16 _memberFlags) internal view returns (bool) {
        require(_memberFlags.exists(), "Invalid member");
        return _memberFlags.exists()
            && !_memberFlags.isKicked()
            && !_memberFlags.hasRageQuit()
            && universe.memberKnotToStakeHouse(_memberId) == address(this);
    }
}
