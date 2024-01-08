// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./SafeMath32.sol";
import "./IRiddleKeyVault.sol";
import "./IRiddleBrainVault.sol";
import "./AdminRole.sol";

contract RiddleCore is Ownable, AdminRole {
	using SafeMath for uint;
	using SafeCast for uint;
	using SafeMath32 for uint32;
	using Address for address;

	event AddedBrain(address indexed sender, uint amount);
	event AddedKey(address indexed sender, uint amount);
	event ConfirmedSubmitRiddle(address user, uint level);
	event ConfirmedBuyHint(address user, uint level);
	event LockedLevel(uint level);
	event UnlockedLevel(uint level);
	event PassedAllLevels(address user);

	struct KeyInfo {
		uint index;
		string rKey;
	}

	struct UserInfo {
		uint season;
		uint256 brainAmount;
		uint32 level;
		mapping(uint => KeyInfo) keyInfo;	// level => keyInfo
		mapping(uint => bool) hasKeyOfLevel;   // level => result
		mapping(uint => mapping(uint => bool)) hasHintOfNumberForLevel; // level => hint_number => result
	}

	struct LevelInfo {
		bool locked;
		uint256 brainAmountNeed;
		uint256 startedTime;
		uint256 cooldownTime;
		uint256 periodTime;
		mapping(uint => uint) brainAmountNeedForHint;	// hint number => amount of brains
		uint32 count;
		uint32 solvedCount;
	}

	mapping(address => UserInfo) private _userInfo;
	mapping(uint => LevelInfo) private _levelInfo;
	uint private _currentLevel;
	uint private _currentSeason = 1;
	address payable private _wallet;
	IRiddleKeyVault private _riddleKeyVault;
	IRiddleBrainVault private _riddleBrainVault;

	constructor(address riddleBrainVault, address riddleKeyVault, address payable wallet) public onlyOwner {
		_wallet = wallet;
		_riddleKeyVault = IRiddleKeyVault(riddleKeyVault);
		_riddleBrainVault = IRiddleBrainVault(riddleBrainVault);
		initializeLevelInfo();
	}

	modifier checkUserLevel(uint level) {
		require(_userInfo[msg.sender].level == level, 'user level mismatch');
		_;
	}

	modifier checkLevel(uint level) {
		require((level < 5), 'level incorrect');
		_;
	}

	modifier isSetBrainPrice() {
		uint _brainPrice = _riddleBrainVault.getBrainPrice();
		require(_brainPrice > 0, "Not set brain price yet");
		_;
	}

	modifier checkLevelAvailability(uint level) {
		require((_levelInfo[level].startedTime.add(_levelInfo[level].periodTime) < block.timestamp), 'The level period has been passed. Level is no longer available');
		_;
	}

	function startNewSeason(uint season) external onlyOwner {
		initializeLevelInfo();
		_riddleKeyVault.initialize();
		_riddleKeyVault.setSellEvent(7 days, 24 hours);
		_currentSeason = season;
	}

	function initializeLevelInfo() public onlyOwner {
		for (uint32 level = 1; level < 5; level++) {
			_setLevelInfo(level, true, 0, 0, 0, 0);
		}
		_currentLevel = 0;
	}

	function getWallet() external view returns (address) {
		return _wallet;
	}

	function getUserInfo(address user) public view returns (uint brainAmount, uint season, uint32 level, bool hasKey, uint keyIndex, bool hint1, bool hint2) {
		brainAmount = _userInfo[user].brainAmount;
		level = _userInfo[user].level;
		season = _userInfo[user].season;
		hasKey = _userInfo[user].hasKeyOfLevel[level];
		if (hasKey) {
			keyIndex = _userInfo[user].keyInfo[level].index;
		}
		hint1 = _userInfo[user].hasHintOfNumberForLevel[level][1];
		hint2 = _userInfo[user].hasHintOfNumberForLevel[level][2];
	}

	function ownedKeyOfUserByLevel(address user, uint level) public view returns (bool hasKey, uint keyIndex) {
		hasKey = _userInfo[user].hasKeyOfLevel[level];
		if (hasKey) {
			keyIndex = _userInfo[user].keyInfo[level].index;
		}
	}

	function getCurrentLevel() external view returns (uint) {
		return _currentLevel;
	}

	function getCurrentSeason() external view returns (uint) {
		return _currentSeason;
	}

	function isStartedOf(uint level) external view returns (bool) {
		return _levelInfo[level].locked == false;
	}

	function isValidRKey(string memory rKey) external view returns (bool) {
		return (keccak256(abi.encodePacked(_userInfo[msg.sender].keyInfo[_userInfo[msg.sender].level].rKey)) == keccak256(abi.encodePacked(rKey)));
	}

	function getLevelInfo(uint level) external view returns (
		bool locked,
		uint startedTime,
		uint cooldownTime,
		uint periodTime,
		uint brainAmountNeed,
		uint brainAmountNeedForHint1,
		uint brainAmountNeedForHint2
	) {
		locked = _levelInfo[level].locked;
		startedTime = _levelInfo[level].startedTime;
		cooldownTime = _levelInfo[level].cooldownTime;
		periodTime = _levelInfo[level].periodTime;
		brainAmountNeed = _levelInfo[level].brainAmountNeed;
		brainAmountNeedForHint1 = _levelInfo[level].brainAmountNeedForHint[1];
		brainAmountNeedForHint2 = _levelInfo[level].brainAmountNeedForHint[2];
	}

	function buyKeyForLevelOne(uint tokenId, string memory rKey) external payable {
		UserInfo storage user = _userInfo[msg.sender];
		uint _levelOfToken = _riddleKeyVault.levelOf(tokenId);
		require(_levelInfo[_levelOfToken].brainAmountNeed > 0, 'Not set the amount of brain for submission');
		require(_levelOfToken == 1, 'Not permitted');
		if (user.season == _currentSeason) {
			require(user.level < 2, 'Can not buy the key');
			require(user.hasKeyOfLevel[_levelOfToken] == false, 'Already bought one');
		}

		_riddleKeyVault.buyKey(msg.sender, tokenId, 1, msg.value);
		_wallet.transfer(msg.value);
		user.hasKeyOfLevel[_levelOfToken] = true;
		user.keyInfo[_levelOfToken] = KeyInfo({
			index: _riddleKeyVault.currentSupplyOf(_levelOfToken),
			rKey: rKey
		});
		user.level = 1;
		user.season = _currentSeason;
		_riddleBrainVault.transferBrainsTo(msg.sender, _levelInfo[_levelOfToken].brainAmountNeed);
		user.brainAmount = user.brainAmount.add(_levelInfo[_levelOfToken].brainAmountNeed);
		emit AddedKey(msg.sender, 1);
	}

	function buyBrainBatch(uint batchNum) external payable isSetBrainPrice {
		uint32 _countOfBatchNum = _riddleBrainVault.countOf(batchNum);
		require(_countOfBatchNum > 0, 'Wrong batch');

		uint32 _discountOfBatchNum = _riddleBrainVault.discountOf(batchNum);
		uint _brainPrice = _riddleBrainVault.getBrainPrice();
		uint _priceForBatch = _brainPrice.mul(_countOfBatchNum.mul(_discountOfBatchNum.div(100)));
		require(msg.value >= _priceForBatch, 'Not sufficient price');

		_riddleBrainVault.transferBrainBatchTo(msg.sender, batchNum);
		_wallet.transfer(msg.value);
		_userInfo[msg.sender].brainAmount = _userInfo[msg.sender].brainAmount.add(_countOfBatchNum);
		AddedBrain(msg.sender, _countOfBatchNum);
	}

	function buyBrains(uint count) external payable isSetBrainPrice {
		uint _brainPrice = _riddleBrainVault.getBrainPrice();
		uint _priceOfBrains = _brainPrice.mul(count);
		require(msg.value >= _priceOfBrains, 'Not sufficient price');
		_riddleBrainVault.transferBrainsTo(msg.sender, count);
		_wallet.transfer(msg.value);
		_userInfo[msg.sender].brainAmount = _userInfo[msg.sender].brainAmount.add(count);
		AddedBrain(msg.sender, count);
	}

	function buyHint(uint level, uint hintNum) external checkLevel(level) {
		require(hintNum > 0 && hintNum < 3, 'Wrong hint number');
		require(_levelInfo[level].brainAmountNeedForHint[hintNum] > 0, 'Not set the brain amount for buying hint yet');
		require(_userInfo[msg.sender].brainAmount >= _levelInfo[level].brainAmountNeedForHint[hintNum], 'Not sufficient brains to buy a hint in this level');
		_riddleBrainVault.burnBrainsOf(msg.sender, _levelInfo[level].brainAmountNeedForHint[hintNum]);
		_userInfo[msg.sender].brainAmount = _userInfo[msg.sender].brainAmount.sub(_levelInfo[level].brainAmountNeedForHint[hintNum]);
		_userInfo[msg.sender].hasHintOfNumberForLevel[level][hintNum] = true;
		emit ConfirmedBuyHint(msg.sender, level);
	}

	function submitRiddle(uint level) external checkUserLevel(level) checkLevel(level) {
		UserInfo storage user = _userInfo[msg.sender];
		require(_levelInfo[level].locked == false, 'Level not started yet');
		require(user.brainAmount >= _levelInfo[level].brainAmountNeed, 'insufficient brains');
		_riddleBrainVault.burnBrainsOf(msg.sender, _levelInfo[level].brainAmountNeed);
		user.brainAmount = user.brainAmount.sub(_levelInfo[level].brainAmountNeed);
		emit ConfirmedSubmitRiddle(msg.sender, level);
	}

	function openChest(uint level, string memory prevRKey, string memory nextRKey) external checkUserLevel(level) checkLevel(level) {
		UserInfo storage user = _userInfo[msg.sender];
		require(user.season == _currentSeason, 'user is not on the current season');
		require(keccak256(abi.encodePacked(_userInfo[msg.sender].keyInfo[level].rKey)) == keccak256(abi.encodePacked(prevRKey)), 'rKey mismatch');
		require(level == _userInfo[msg.sender].level, 'Level mismatch');
		uint nextToken = _riddleKeyVault.tokenOf(user.level.add(1));
		if (user.level == 4) {
				emit PassedAllLevels(msg.sender);
		}
		user.level = level.add(1).toUint32();
		user.hasKeyOfLevel[_riddleKeyVault.levelOf(nextToken)] = true;
		_riddleKeyVault.tranferKey(msg.sender, nextToken, 1);
		_riddleBrainVault.transferBrainsTo(msg.sender, _levelInfo[level.add(1)].brainAmountNeed);
		user.brainAmount = user.brainAmount.add(_levelInfo[level.add(1)].brainAmountNeed);
		user.keyInfo[level.add(1)] = KeyInfo({
			index: _riddleKeyVault.currentSupplyOf(level.add(1)),
			rKey: nextRKey
		});
	}

	function lockLevel(uint level) external onlyAdmin {
		_setLevelInfo(level, true, 0, 0, 0, 0);
		emit LockedLevel(level);
	}

	function unlockLevel(uint level, uint cooldown, uint period, uint brainAmountNeed, uint32 riddleCount, uint brainAmountNeedForHint1, uint brainAmountNeedForHint2) external checkLevel(level) onlyAdmin {
		_setLevelInfo(level, false, cooldown, period, brainAmountNeed, riddleCount);
		_currentLevel = level;
		if (brainAmountNeedForHint1 > 0) {
			_levelInfo[level].brainAmountNeedForHint[1] = brainAmountNeedForHint1;
		}
		if (brainAmountNeedForHint2 > 0) {
			_levelInfo[level].brainAmountNeedForHint[2] = brainAmountNeedForHint2;
		}
		emit UnlockedLevel(level);
	}

	function setHintPriceByBrain(uint level, uint hintNum, uint brainAmountNeed) external {
		require(hintNum < 3, 'invalid hint number');
		require(level > 0 && level < 5, 'invalid level');
		_levelInfo[level].brainAmountNeedForHint[hintNum] = brainAmountNeed;
	}

	function setCooldownTimeOfLevel(uint level, uint cooldown) external onlyAdmin checkLevel(level) {
		require(level > 0 && level < 5, 'Level incorrect');
		require(cooldown > 0, 'Cooldown time incorrect');
		_levelInfo[level].cooldownTime = cooldown;
	}

	function setRiddleCountOfLevel(uint level, uint32 riddleCount) external onlyAdmin {
		_levelInfo[level].count = riddleCount;
	}

	function setPeriodTimeOfLevel(uint level, uint period) external onlyAdmin {
		require(level > 0 && level < 5, 'level incorrect');
		require(period > 0, 'cooldown time incorrect');
		_levelInfo[level].periodTime = period;
	}

	function _setLevelInfo(uint level, bool locked, uint cooldown, uint period, uint brainAmountNeed, uint32 riddleCount) private {
		LevelInfo storage levelInfo = _levelInfo[level];
		levelInfo.locked = locked;
		levelInfo.startedTime = locked ? 0 : block.timestamp;
		levelInfo.brainAmountNeed = brainAmountNeed;
		levelInfo.count = riddleCount;
		levelInfo.solvedCount = 0;
		if (locked == false) {
			if (cooldown > 0) {
				levelInfo.cooldownTime = cooldown;
			}
			if (period > 0) {
				levelInfo.periodTime = period;
			}
		}
	}
}
