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

// Part: IRaiderArmory

interface IRaiderArmory {
    function addWeaponToToken(uint256 _tokenId, uint256 _weaponId) external;

    function hasWeapon(uint256 _tokenId, uint256 _weaponId)
        external
        returns (bool);

    function getMaxWeaponScore(uint256 _tokenId) external view returns (uint8);
}

// Part: IRaiderGold

interface IRaiderGold {
    function adminMint(address _account, uint256 _amount) external payable;
    function adminBurn(address _account, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
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

// File: RaiderHunt.sol

contract RaiderHunt is Ownable {
    // weapon score index to staking reward mapping
    uint256[18] public weaponStakingReward = [
        1157407407407 wei, // 0.1 per day
        6944444444444 wei, // 0.6 per day
        8101851851852 wei, // 0.7 per day
        9259259259259 wei, // 0.8 per day
        10416666666667 wei, // 0.9 per day
        11574074074074 wei, // 1 per day
        24305555555556 wei, // 2.1 per day
        24305555555556 wei, // 2.2 per day
        26620370370370 wei, // 2.3 per day
        27777777777778 wei, // 2.4 per day
        28935185185185 wei // 2.5 per day
    ];

    // boolean to control staking
    bool public stakingLive = false;

    // mapping from tokenId to timestamp of staked
    mapping(uint256 => uint256) public tokenIdToTimeStaked;
    // mapping from staked tokenId to staker
    mapping(uint256 => address) public tokenIdToStaker;
    // mapping from staker to tokenIds staked
    mapping(address => uint256[]) public stakerToTokenIds;

    // raider interface
    IRaider private raider;
    // token interface
    IRaiderGold private rgo;
    // armory interface
    IRaiderArmory private armory;

    constructor(address _raiderGoldAddress, address _raiderAddress) {
        rgo = IRaiderGold(_raiderGoldAddress);
        raider = IRaider(_raiderAddress);
    }

    /************/
    /* INTERNAL */
    /************/

    /**
     * @notice drops an element from a storage array
     * @dev used for staked raider tokens. Expensive, so unstakeAll is preferred where possible
     * @param _array - the array to drop the element from
     * @param _id - the element to remove
     */
    function dropIdFromArray(uint256[] storage _array, uint256 _id) private {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == _id) {
                length--;
                if (i < length) {
                    _array[i] = _array[length];
                }
                _array.pop();
                break;
            }
        }
    }

    /************/
    /* EXTERNAL */
    /************/

    /**
     * @notice stakes (multiple) tokens
     * @param _tokenIds - array of tokenId(s) to stake
     */
    function stakeRaidersById(uint256[] memory _tokenIds) public {
        require(stakingLive, "Not live");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 id = _tokenIds[i];
            require(raider.ownerOf(id) == msg.sender, "Not yours");

            raider.transferFrom(msg.sender, address(this), id);
            tokenIdToTimeStaked[id] = block.timestamp;
            tokenIdToStaker[id] = msg.sender;
            stakerToTokenIds[msg.sender].push(id);
        }
    }

    /**
     * @notice unstakes all tokens of a staker
     */
    function unstakeAll() public {
        uint256 rewards;

        require(stakerToTokenIds[msg.sender].length > 0, "Nothing staked");

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToTokenIds[msg.sender][i - 1];
            raider.transferFrom(address(this), msg.sender, id);
            rewards += getRewardsByTokenId(id);
            stakerToTokenIds[msg.sender].pop();
            tokenIdToStaker[id] = address(0);
        }

        rgo.adminMint(msg.sender, rewards);
    }

    /**
     * @notice unstakes chosen token(s) of a staker
     * @param _tokenIds - tokenIds to unstake
     */
    function unstakeRaidersById(uint256[] memory _tokenIds) public {
        uint256 rewards;

        require(stakerToTokenIds[msg.sender].length > 0, "Nothing staked");
        require(_tokenIds.length > 0, "No tokens");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 id = _tokenIds[i];
            require(tokenIdToStaker[id] == msg.sender, "Not yours");
            raider.transferFrom(address(this), msg.sender, id);
            rewards += getRewardsByTokenId(id);
            dropIdFromArray(stakerToTokenIds[msg.sender], id);
            tokenIdToStaker[id] = address(0);
        }

        rgo.adminMint(msg.sender, rewards);
    }

    /**
     * @notice claims all accrued rewards across staked token(s)
     */
    function claimAll() public {
        uint256 rewards;

        require(stakerToTokenIds[msg.sender].length > 0, "Nothing staked");

        for (uint256 i = 0; i < stakerToTokenIds[msg.sender].length; i++) {
            uint256 id = stakerToTokenIds[msg.sender][i];
            rewards += getRewardsByTokenId(id);
            tokenIdToTimeStaked[id] = block.timestamp;
        }

        rgo.adminMint(msg.sender, rewards);
    }

    /**
     * @notice fetches rewards acrued for tokenId
     * @param _tokenId - tokenId to fetch accrued rewards for
     * @return integer value of rewards accrued for token
     */
    function getRewardsByTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(tokenIdToStaker[_tokenId] != address(0), "Not yours");
        return ((block.timestamp - tokenIdToTimeStaked[_tokenId]) *
            weaponStakingReward[armory.getMaxWeaponScore(_tokenId)]);
    }

    /**
     * @notice fetches total rewards acrued for staker
     * @param _staker - address of staker to fetch total rewards for
     * @return integer value of rewards accrued for staker across tokens
     */
    function getTotalRewardsAccrued(address _staker)
        public
        view
        returns (uint256)
    {
        uint256 rewards;
        uint256[] memory raiderTokenIds = stakerToTokenIds[_staker];
        for (uint256 i = 0; i < raiderTokenIds.length; i++) {
            uint256 id = raiderTokenIds[i];
            rewards += ((block.timestamp - tokenIdToTimeStaked[id]) *
                weaponStakingReward[armory.getMaxWeaponScore(id)]);
        }

        return rewards;
    }

    /**
     * @notice fetches the amount of tokens staked by staker
     * @param _staker - address of original staker
     * @return num of tokens staked by staker
     */
    function getRaidersStakedCount(address _staker)
        public
        view
        returns (uint256)
    {
        return stakerToTokenIds[_staker].length;
    }

    /**
     * @notice fetches the tokens staked by staker
     * @param _staker - address of original staker
     * @return tokens staked by staker
     */
    function getRaidersStaked(address _staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[_staker];
    }

    /**
     *  @notice returns whether the address is staking the token
     *  @dev used e.g. in armory to check whether someone is staking the token
     *  @param _address - the address to check against
     *  @param _tokenId - the tokenId to check against
     *  @return bool whether the address is the staker of the token
     */
    function isStaker(address _address, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        if (tokenIdToStaker[_tokenId] == _address) {
            return true;
        } else {
            return false;
        }
    }

    /************/
    /* OWNER */
    /************/

    /**
     * @notice adds armory contract for interface use
     * @param _armoryContract - address of armory contract
     */
    function addRaiderArmoryContract(address _armoryContract)
        external
        onlyOwner
    {
        armory = IRaiderArmory(_armoryContract);
    }

    /**
     * @notice flips staking status
     */
    function flipStakeStatus() external onlyOwner {
        stakingLive = !stakingLive;
    }
}
