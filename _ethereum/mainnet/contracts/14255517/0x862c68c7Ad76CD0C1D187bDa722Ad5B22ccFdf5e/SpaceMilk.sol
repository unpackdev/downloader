// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./ISpaceCows.sol";

contract SpaceMilk is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    modifier isAllowAddress(address addr) {
        require(msg.sender == address(spaceCows), "Can't call direct");
        _;
    }

    struct CollectionInfo {
        string name;
        uint256 boostCap;
        uint256 hardCap;
    }

    mapping(address => mapping(uint256 => uint256)) public rewards;
	mapping(address => mapping(uint256 => uint256)) public lastUpdate;

    // mapping collection caps
    mapping(uint256 => CollectionInfo) public collectionInfo;
    // mapping total supply before burn 
    mapping(uint256 => uint256) public totalSupplyByCollection;
    // mapping of remaining boost by collection
    mapping(uint256 => uint256) public remainingBoostByCollection;
    // mapping of remaining supply by collection
    mapping(uint256 => uint256) public remainingSupplyByCollection;

    event RewardPaid(address indexed user, uint256 collection, uint256 reward);
    event BurnedTokens(address indexed user, uint256 collection, uint256 amount);

    ISpaceCows public spaceCows;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC20_init(_name, _symbol);
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // 6,182,917.50 SM Tokens for liquidity pool 
        _mint(msg.sender, 6182917500000000000000000);
    }
    
    function updateUserTimeOnMint(address _user, uint256 _collection)
    external
    isAllowAddress(msg.sender) {
        uint256 time = block.timestamp;
        lastUpdate[_user][_collection] = time;
    }

    function updateUserTime(address _user, uint256 _collection)
    internal {
        uint256 time = block.timestamp;
        lastUpdate[_user][_collection] = time;
    }

    function calculateRewards(uint256 _mintingAmount, uint256 _collection) internal view returns (uint256, uint256) {
        uint256 boostRewards;
        uint256 finalMintingReward;
        uint256 removedBoost;
        uint256 remainingBoost = remainingBoostByCollection[_collection];
        uint256 remainingSupply = remainingSupplyByCollection[_collection];

        if (remainingBoost > _mintingAmount.mul(2)) {
            boostRewards = _mintingAmount.mul(2);
            removedBoost = boostRewards;
        } else if (remainingBoost > 0) {
            boostRewards = _mintingAmount.add(remainingBoostByCollection[_collection]);
            removedBoost = remainingBoostByCollection[_collection];
        } else {
            boostRewards = _mintingAmount;
            removedBoost = 0;
        }

        if (remainingSupply < _mintingAmount) {
            finalMintingReward = remainingSupplyByCollection[_collection];
        } else {
            if (remainingSupply < boostRewards) {
                finalMintingReward = remainingSupplyByCollection[_collection];
            } else {
                finalMintingReward = boostRewards;
            }
        }

        return (finalMintingReward, removedBoost);
    }

    function setRewards(address _user, uint256 _collection) internal {
        if (remainingSupplyByCollection[_collection] > 0) {
            uint256 userTimer = lastUpdate[_user][_collection];

            if (userTimer > 0) {
                uint256 time = block.timestamp;
                uint256 mintingRate;

                mintingRate = spaceCows.getMintingRate(_user);

                uint256 mintingReward = mintingRate.mul(time.sub(userTimer)).div(86400);
                (uint256 finalReward, uint256 boostSupply) = calculateRewards(mintingReward, _collection);

                rewards[_user][_collection] += finalReward;
                totalSupplyByCollection[_collection] += finalReward;
                remainingSupplyByCollection[_collection] -= finalReward;
                remainingBoostByCollection[_collection] -= boostSupply;
            } else {
                updateUserTime(_user, _collection);
                return;
            }

            updateUserTime(_user, _collection);
        } else {
            return;
        }
    }

    // called on transfers
    function updateReward(address _from, address _to, uint256 _collection)
    external
    isAllowAddress(msg.sender) {
        setRewards(_from, _collection);
        
        if (_to != address(0)) {
            setRewards(_to, _collection);
        }
    }

    function getReward(address _to, uint256 _collection)
    external
    isAllowAddress(msg.sender) {
		uint256 reward = rewards[_to][_collection];
        require(reward > 0, "No rewards to claim");

        rewards[_to][_collection] = 0;
        _mint(_to, reward);
        emit RewardPaid(_to, _collection, reward);
	}

    function burn(address _from, uint256 _collection, uint256 _amount)
    external
    isAllowAddress(msg.sender) {
		_burn(_from, _amount);
        emit BurnedTokens(_from, _collection, _amount);
	}

    function getTotalClaimable(address _user, uint256 _collection) external view returns(uint256) {
        require(remainingSupplyByCollection[_collection] > 0, "Supply is fully minted");
        uint256 userTimer = lastUpdate[_user][_collection];
        require(userTimer > 0, "Pending reward timer is more than 0");

		uint256 time = block.timestamp;
        uint256 pendingMintingRate;

        pendingMintingRate = spaceCows.getMintingRate(_user);

        uint256 pendingRewards = pendingMintingRate.mul(time.sub(userTimer)).div(86400);
        (uint256 newpendingRewards,) = calculateRewards(pendingRewards, _collection);

		return rewards[_user][_collection] + newpendingRewards;
	}

    function setSpaceCowsAddress(address _nftContract) external onlyOwner {
        spaceCows = ISpaceCows(_nftContract);
    }

    function setCollectionInfo(uint256 _collectionIndex, string memory _collectionName, uint256 _boostCap, uint256 _hardCap) external onlyOwner {
        collectionInfo[_collectionIndex] = CollectionInfo(_collectionName, _boostCap, _hardCap);
        remainingBoostByCollection[_collectionIndex] = _boostCap;
        remainingSupplyByCollection[_collectionIndex] = _hardCap;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}