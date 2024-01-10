// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

import "./iNFT.sol";

contract SpaceMilk is ERC20, Ownable {
    struct CollectionInfo {
        string name;
        address contractAddress;
        uint128 boostCap;
        uint128 remainingBoost;
        uint128 hardCap;
        uint128 remainingSupply;
    }
    mapping(uint256 => CollectionInfo) public collectionInfo;

    struct UserInfo {
        uint128 waitingRewards;
        uint128 rewards;
    }
    mapping(address => mapping(uint256 => UserInfo)) public userInfo;
    mapping(address => mapping(uint256 => uint256)) public lastUpdate;

    uint256 public startTimer;

    event RewardPaid(address indexed user, uint256 collection, uint256 reward);
    event BurnedTokens(address indexed user, uint256 collection, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _timer)
    ERC20(_name, _symbol) {
        startTimer = _timer;

        // 6,182,917.50 SM Tokens for liquidity pool 
        _mint(msg.sender, 6182917500000000000000000);
    }

    /**
    =========================================
    Owner Functions
    @dev these functions can only be called 
        by the owner of contract. some functions
        here are meant only for backup cases.
    =========================================
    */
    function setCollectionInfo(uint256 _collectionIndex, string memory _name, uint128 _boostCap, uint128 _hardCap, address _contract) external onlyOwner {
        collectionInfo[_collectionIndex] = CollectionInfo(_name, _contract, _boostCap, _boostCap, _hardCap, _hardCap);
    }
    
    function setStartTimer(uint256 _newTimer) external onlyOwner {
        startTimer = _newTimer;
    }

    function updateUserTimer(address _user, uint256 _collection, uint256 _newTimer) external onlyOwner {
        lastUpdate[_user][_collection] = _newTimer;
    }

    /**
    ============================================
    Public & External Functions
    @dev functions that can be called by anyone
    ============================================
    */
    function fullRewardUpdate(address _user, uint256 _rate, uint256 _collection) external {
        require(msg.sender == address(collectionInfo[_collection].contractAddress), "Can't call direct");
        setRewards(_user, _rate, _collection);
    }

    function updateReward(address _from, uint256 _fromRate, address _to, uint256 _toRate, uint256 _collection)
    external {
        require(msg.sender == address(collectionInfo[_collection].contractAddress), "Can't call direct");
        uint256 timestamp = block.timestamp;
        if (_from != address(0)) {
            getPendingReward(_from, _fromRate, timestamp, _collection);
            lastUpdate[_from][_collection] = timestamp;
        }

        if (_to != address(0)) {
            if (_toRate != 0) {
                getPendingReward(_to, _toRate, timestamp, _collection);
                lastUpdate[_to][_collection] = timestamp;
            } else {
                lastUpdate[_to][_collection] = timestamp;
            }
        }
    }

    function getReward(address _to, uint256 _collection)
    external {
        require(msg.sender == address(collectionInfo[_collection].contractAddress), "Can't call direct");
        UserInfo memory _info = userInfo[_to][_collection];
        require(_info.rewards > 0, "No rewards to claim");

        _mint(_to, _info.rewards);
        emit RewardPaid(_to, _collection, _info.rewards);
        userInfo[_to][_collection] = UserInfo(_info.waitingRewards, 0);
	}

    function burn(address _from, uint256 _collection, uint256 _amount)
    external {
        require(msg.sender == address(collectionInfo[_collection].contractAddress), "Can't call direct");
		_burn(_from, _amount);
        emit BurnedTokens(_from, _collection, _amount);
	}

    function getTotalClaimable(address _user, uint256 _collection) external view returns(uint256) {
        CollectionInfo memory _collectionInfo = collectionInfo[_collection];

        require(_collectionInfo.remainingSupply > 0, "Supply is fully minted");
        UserInfo memory _info = userInfo[_user][_collection];
        uint256 _userTimer = lastUpdate[_user][_collection];

        uint256 userTimer = (block.timestamp - (_userTimer > startTimer - 1 ? _userTimer : startTimer));
        require(userTimer > 0, "Pending reward timer is more than 0");

        iNFT _c = iNFT(_collectionInfo.contractAddress);
        uint256 pendingMintingRate = _c.getMintingRate(_user);
        uint256 pendingRewards = pendingMintingRate * userTimer / 86400;
        pendingRewards += uint256(_info.waitingRewards);
        (uint128 newpendingRewards,) = calculateRewards(uint128(pendingRewards), _collectionInfo.remainingBoost, _collectionInfo.remainingSupply);

		return _info.rewards + newpendingRewards;
	}

    /**
    ============================================
    Internal Functions
    @dev functions that can be called by inside contract
    ============================================
    */
    function calculateRewards(uint128 _mintingAmount, uint128 remainingBoost, uint128 remainingSupply) internal pure returns (uint128, uint128) {
        uint128 boostRewards;
        uint128 finalMintingReward;
        uint128 removedBoost;

        unchecked {
            if (remainingBoost > _mintingAmount * 2) {
                boostRewards = _mintingAmount * 2;
                removedBoost = boostRewards;
            } else if (remainingBoost > 0) {
                boostRewards = _mintingAmount + remainingBoost;
                removedBoost = remainingBoost;
            } else {
                boostRewards = _mintingAmount;
                removedBoost = 0;
            }

            if (remainingSupply < _mintingAmount) {
                finalMintingReward = remainingSupply;
            } else {
                if (remainingSupply < boostRewards) {
                    finalMintingReward = remainingSupply;
                } else {
                    finalMintingReward = boostRewards;
                }
            }
        }

        return (finalMintingReward, removedBoost);
    }

    function setRewards(address _user, uint256 _rate, uint256 _collection) internal {
        CollectionInfo memory _collectionInfo = collectionInfo[_collection];

        if (_collectionInfo.remainingSupply > 0) {
            UserInfo memory _info = userInfo[_user][_collection];
            uint256 _timestamp = block.timestamp;
            uint256 _userTimer = lastUpdate[_user][_collection];

            uint256 userTimer = (_timestamp - (_userTimer > startTimer - 1 ? _userTimer : startTimer));

            uint256 mintingReward = _rate * userTimer / 86400;
            mintingReward += uint256(_info.waitingRewards);
            (uint128 finalReward, uint128 boostSupply) = calculateRewards(uint128(mintingReward), _collectionInfo.remainingBoost, _collectionInfo.remainingSupply);

            collectionInfo[_collection] = CollectionInfo(
                _collectionInfo.name,
                _collectionInfo.contractAddress,
                _collectionInfo.boostCap,
                _collectionInfo.remainingBoost - boostSupply,
                _collectionInfo.hardCap,
                _collectionInfo.remainingSupply - finalReward
            );
            userInfo[_user][_collection] = UserInfo(0, _info.rewards + finalReward);
            lastUpdate[_user][_collection] = _timestamp;
        }
    }

    function getPendingReward(address _user, uint256 _rate, uint256 _timestamp, uint256 _collection) internal {
        UserInfo memory _info = userInfo[_user][_collection];
        uint256 userTimer = lastUpdate[_user][_collection];

        unchecked {
            uint256 _startTimer = startTimer;
            uint256 _timer = (_timestamp - (userTimer > _startTimer - 1 ? userTimer : _startTimer));
            uint256 _newRate = _rate * _timer / 86400;

            userInfo[_user][_collection] = UserInfo(_info.waitingRewards + uint128(_newRate), _info.rewards);
        }
    }
}