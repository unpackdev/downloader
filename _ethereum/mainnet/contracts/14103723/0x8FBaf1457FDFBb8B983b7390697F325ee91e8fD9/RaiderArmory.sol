// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: IRaider

interface IRaider {
    struct Raider {
        uint256 dna;
        uint256 active_weapon;
    }

    struct RaiderTraits {
        bool isFemale;
        uint256 skin;
        uint256 hair;
        uint256 boots;
        uint256 pants;
        uint256 outfit;
        uint256 headwear;
        uint256 accessory;
        uint256 active_weapon;
    }

    function getTokenRaider(uint256 _tokenId) external view returns (Raider memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// Part: IRaiderGold

interface IRaiderGold {
    function adminMint(address _account, uint256 _amount) external payable;
    function adminBurn(address _account, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// Part: IRaiderHunt

interface IRaiderHunt {
    function isStaker(address _address, uint256 _tokenId) external view returns (bool);
}

// Part: OpenZeppelin/openzeppelin-contracts@4.4.0/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/openzeppelin-contracts@4.4.0/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: RaiderArmory.sol

contract RaiderArmory is Ownable {
    // mapping from weapon id (index) to its score
    uint256[18] public weaponScore = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10
    ];
    // mapping from weapon id (index) to its price in $RGO (each cost 1 for now)
    uint256[18] public weaponCost = [
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        0.5 ether,
        1 ether,
        2 ether,
        3 ether,
        4 ether,
        5 ether,
        10 ether,
        11 ether,
        12 ether,
        13 ether,
        14 ether
    ];

    // mapping of a token's id to a weapon, to avoid iteration to check wether a token has a certain weapon
    mapping(uint256 => mapping(uint256 => bool)) public tokenToWeapon;

    IRaiderGold private rgo;
    IRaiderHunt private hunt;
    IRaider private raiders;
    address raidersAddress;

    constructor(
        address _raiderGoldAddress,
        address _raiderHuntAddress,
        address _raidersAddress
    ) {
        rgo = IRaiderGold(_raiderGoldAddress);
        hunt = IRaiderHunt(_raiderHuntAddress);
        raiders = IRaider(_raidersAddress);
        raidersAddress = _raidersAddress;
    }

    /**
     * @notice fetch weapon score for a weapon id
     * @param _weaponId the id of the weapon
     * @return uint256 weapon id
     */
    function getWeaponScore(uint256 _weaponId) public view returns (uint256) {
        return weaponScore[_weaponId];
    }

    /**
     * @notice fetch largest weapon score for a token's weapons
     * @param _tokenId the id of the token
     * @return uint8 the max score of a token's weapons
     */
    function getMaxWeaponScore(uint256 _tokenId) public view returns (uint256) {
        for (uint256 i = weaponScore.length - 1; i >= 0; i--) {
            if (tokenToWeapon[_tokenId][i]) {
                return weaponScore[i];
            }
        }
    }

    /**
     * @notice adds a weapon id to tokenToWeapon mapping
     * @dev used in raider contract when allocating mint weapon
     * @param _tokenId - the tokenId
     * @param _weaponId - the weaponId
     */
    function addWeaponToToken(uint256 _tokenId, uint256 _weaponId) public {
        require(msg.sender == raidersAddress, "Not allowed");
        tokenToWeapon[_tokenId][_weaponId] = true;
    }

    /**
     * @notice checks whether token owns weapon
     * @dev used in raider contract before updating active_weapon
     * @param _tokenId - the tokenId
     * @param _weaponId - the weaponId
     * @return bool
     */
    function hasWeapon(uint256 _tokenId, uint256 _weaponId)
        public
        returns (bool)
    {
        return tokenToWeapon[_tokenId][_weaponId];
    }

    /**
     * @notice buy weapon and add it to a token's weapon collection
     * @dev weaponId n can only be bought if the token owns weaponId - 1 (id 9 and up)
     * @param _tokenId - the token's id
     * @param _weaponId - the desired weapon's id
     */
    function buyWeapon(uint256 _tokenId, uint256 _weaponId) public {
        require(
            msg.sender == raiders.ownerOf(_tokenId) ||
                hunt.isStaker(msg.sender, _tokenId),
            "Not allowed"
        );
        require(tokenToWeapon[_tokenId][_weaponId] == false, "Already owned");
        if (_weaponId > 8) {
            require(tokenToWeapon[_tokenId][_weaponId - 1], "Not unlocked");
        }
        require(rgo.balanceOf(msg.sender) >= weaponCost[_weaponId], "Too poor");
        rgo.adminBurn(msg.sender, weaponCost[_weaponId]);
        tokenToWeapon[_tokenId][_weaponId] = true;
    }
}
