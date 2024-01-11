import "./IPublicLockV10.sol";
import "./console.sol";


contract Mapping {
    mapping(uint => uint) public avatarsWeapons;
    address public _avatarLock;
    address public _buntaiWeaponLock;
    address public _gundanWeaponLock;

    constructor(
        address avatarLock,
        address buntaiWeaponLock,
        address gundanWeaponLock
    ) {
        _avatarLock = avatarLock;
        _buntaiWeaponLock = buntaiWeaponLock;
        _gundanWeaponLock = gundanWeaponLock;
    }

    function addMapping(uint avatarId, uint weaponId) public {
        require(msg.sender == IPublicLock(_avatarLock).ownerOf(avatarId), "Must own avatar");

        if (avatarId % 2 == 0) {
            require(msg.sender == IPublicLock(_buntaiWeaponLock).ownerOf(avatarId), "Must own buntai weapon");
        } else {
            require(msg.sender == IPublicLock(_gundanWeaponLock).ownerOf(avatarId), "Must own gundan weapon");
        }
        avatarsWeapons[avatarId] = weaponId;
    }

    function removeMapping(uint avatarId) public {
        require(msg.sender == IPublicLock(_avatarLock).ownerOf(avatarId), "Must own avatar");
        avatarsWeapons[avatarId] = 0;
    }

}