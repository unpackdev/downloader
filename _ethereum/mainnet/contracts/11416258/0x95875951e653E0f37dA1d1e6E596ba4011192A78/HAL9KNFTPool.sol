/**
 *Submitted for verification at Etherscan.io on 2020-08-26
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol"; // for WETH
import "./SafeMath.sol";
import "./ERC1155Tradable.sol";
import "./IHal9kVault.sol";
import "./console.sol";

contract HAL9KNFTPool is OwnableUpgradeSafe {
	ERC1155Tradable public hal9kLtd;
    IHal9kVault public hal9kVault;
	uint256 private waitTimeUnit;
	mapping(uint256 => address[]) private boughtAddress;
    struct UserInfo {
        uint256 lastUpdateTime;
        uint256 stakeAmount;
        uint256 startTime;
        uint256 stage;
    }

    mapping(address => UserInfo) private lpUsers;

	// Events
	event stageUpdated(address addr, uint256 stage, uint256 lastUpdateTime);
	event vaultAddressChanged(address newAddress, address oldAddress);
	event didHal9kStaking(address addr, uint256 startedTime);
	event withdrawnLP(address addr, uint256 lastUpdateTime);
	event waitTimeUnitUpdated(address addr, uint256 waitTimeUnit);
	event minted(address addr, uint256 cardId, uint256 mintAmount);
	event burned(address addr, uint256 cardId, uint256 burnAmount);
	event upgraded(address addr, uint256 newCardId);
	event eventSet(uint256 cardId, uint256 starTime, uint256 endTime);

	mapping(uint256 => mapping(address => bool)) public _cardBought;

	struct SellEvent {
		uint256 sellStartTime;
		uint256 sellEndTime;
		uint256 cardAmount;
		uint256 soldAmount;
		uint256 price;
	}
	mapping(uint256 => SellEvent) public _eventData;

	// functions
	function initialize(ERC1155Tradable _hal9kltdAddress, IHal9kVault _hal9kVaultAddress, address superAdmin) public initializer {
    	OwnableUpgradeSafe.__Ownable_init();
		_superAdmin = superAdmin;
		hal9kLtd = _hal9kltdAddress;
		hal9kVault = IHal9kVault(_hal9kVaultAddress);
		waitTimeUnit = 1 days;
	}

	// Change the hal9k vault address
    function changeHal9kVaultAddress(address _hal9kVaultAddress) external onlyOwner {
        address oldAddress = address(hal9kVault);
        hal9kVault = IHal9kVault(_hal9kVaultAddress);
        emit vaultAddressChanged(_hal9kVaultAddress, oldAddress);
    }
	
	function updateWaitTimeUnit(uint256 timeUnit) public onlyOwner {
		waitTimeUnit = timeUnit;
		emit waitTimeUnitUpdated(msg.sender, waitTimeUnit);
	}

    function getDaysPassedAfterStakingStart() public view returns (uint256) {
        require(lpUsers[msg.sender].stakeAmount > 0, "Staking not started yet");
        return (block.timestamp - lpUsers[msg.sender].startTime) / waitTimeUnit;
    }
	
	function getDaysPassedAfterLastUpdateTime() public view returns (uint256) {
		require(lpUsers[msg.sender].stakeAmount > 0, "Staking not started yet");
        return (block.timestamp - lpUsers[msg.sender].lastUpdateTime) / waitTimeUnit;
	}

	function getCurrentStage(address user) public view returns(uint256 stage) {
		require(lpUsers[user].stakeAmount > 0, "Staking not started yet");
		return lpUsers[user].stage;
	}

	function getStakedAmountOfUser(address user) public view returns(uint256 stakeAmount) {
		require(lpUsers[user].stakeAmount > 0, "Staking not started yet");
		return lpUsers[user].stakeAmount;
	}

	function getStakeStartTime(address user) public view returns(uint256 startTime) {
		require(lpUsers[user].stakeAmount > 0, "Staking not started yet");
		return lpUsers[user].startTime;
	}

	function getLastUpdateTime(address user) public view returns(uint256 startTime) {
		require(lpUsers[user].stakeAmount > 0, "Staking not started yet");
		return lpUsers[user].lastUpdateTime;
	}

	function isHal9kStakingStarted(address user) public view returns(bool started){
		if (lpUsers[user].startTime > 0) return true;
		return false;
	}

	function doHal9kStaking(address sender, uint256 stakeAmount, uint256 currentTime) public {
		require(hal9kVault == IHal9kVault(_msgSender()), "Caller is not Hal9kVault Contract");
		require(stakeAmount > 0, "Stake amount invalid");
		if (lpUsers[sender].startTime > 0) {
			lpUsers[sender].stakeAmount += stakeAmount;
		} else {
			lpUsers[sender].startTime = currentTime;
			lpUsers[sender].stakeAmount = stakeAmount;
			lpUsers[sender].lastUpdateTime = currentTime;
			lpUsers[sender].stage = 0;
		}
		emit didHal9kStaking(sender, lpUsers[sender].startTime);
	}

	function withdrawLP(address sender, uint256 stakeAmount) public {
		require(hal9kVault == IHal9kVault(_msgSender()), "Caller is not Hal9kVault Contract");
		require(stakeAmount > 0, "Stake amount invalid");
		require(lpUsers[sender].startTime > 0, "Staking not started");
		if (lpUsers[sender].stakeAmount > stakeAmount) {
			lpUsers[sender].stakeAmount -= stakeAmount;
		} else {
			lpUsers[sender].stakeAmount = 0;
			lpUsers[sender].lastUpdateTime = 0;
			lpUsers[sender].startTime = 0;
			lpUsers[sender].stage = 0;
		}
		emit withdrawnLP(sender, lpUsers[sender].startTime);
	}

	// backOrForth : back if true, forward if false
	function moveStageBackOrForth(bool backOrForth) public { 
		require(lpUsers[msg.sender].startTime > 0 && lpUsers[msg.sender].stakeAmount > 0, "Staking not started yet");

		if (backOrForth == false) {	// If user moves to the next stage
			if (lpUsers[msg.sender].stage == 0) {
				lpUsers[msg.sender].stage = 1;
				lpUsers[msg.sender].lastUpdateTime = block.timestamp;
			} else if (lpUsers[msg.sender].stage >= 1) {
				lpUsers[msg.sender].stage += 1;
				lpUsers[msg.sender].lastUpdateTime = block.timestamp;
			}
		} else {	// If user decides to go one stage back
			if (lpUsers[msg.sender].stage == 0) {
				lpUsers[msg.sender].stage = 0;
			} else if (lpUsers[msg.sender].stage > 3) {
				lpUsers[msg.sender].stage = 3;
				lpUsers[msg.sender].lastUpdateTime = block.timestamp;
			} else {
				lpUsers[msg.sender].stage -= 1;
				lpUsers[msg.sender].lastUpdateTime = block.timestamp;
			}
		}

		console.log("Changed stage: ", lpUsers[msg.sender].stage);
		emit stageUpdated(msg.sender, lpUsers[msg.sender].stage, lpUsers[msg.sender].lastUpdateTime);
	}

	// Give NFT to User
	function mintCardForUser(uint256 _pid, uint256 _cardId, uint256 _cardCount) public {
		// Check if cards are available to be minted
		require(_cardCount > 0, "Mint amount should be more than 1");
		require(hal9kLtd._exists(_cardId) != false, "Card not found");
		require(hal9kLtd.totalSupply(_cardId) <= hal9kLtd.maxSupply(_cardId), "Card limit is reached");
		
		// Validation
		uint256 stakeAmount = hal9kVault.getUserInfo(_pid, msg.sender);
		console.log("Mint Card For User (staked amount): ", stakeAmount, lpUsers[msg.sender].stakeAmount);
		console.log("Caller of MintCardForUser function: ", msg.sender, _cardCount);
		require(stakeAmount > 0 && stakeAmount == lpUsers[msg.sender].stakeAmount, "Invalid user");

		hal9kLtd.mint(msg.sender, _cardId, _cardCount, "");
		emit minted(msg.sender, _cardId, _cardCount);
	}
	
	function isAlreadyBought(uint256 _cardId, address buyer) public view returns(bool) {
		return _cardBought[_cardId][buyer] == true ? true : false;
	}

	function isSellEventEnded(uint256 _cardId) public view returns(bool) {
		return _eventData[_cardId].sellStartTime > 0 && _eventData[_cardId].sellEndTime > 0 && _eventData[_cardId].sellEndTime < block.timestamp ? true : false;
	}

	function getSellEventData(uint256 _cardId) public view returns(SellEvent memory) {
		require(_cardId >= 0, "Invalid card id");
		return _eventData[_cardId];
	}

	function setSellEvent(uint256 _cardId, uint256 _startTime, uint256 _endTime, uint256 _amount, uint256 _price) public onlyOwner{
		require(_cardId >= 0, "Invalid card id");
		require(_startTime >= 0, "Invalid startTime");
		require(_endTime >= 0, "Invalid endTime");
		require(_startTime <= _endTime, "End time must be bigger than startTime");
		require(_price >= 0, "Invalid price");
		_eventData[_cardId].sellStartTime = _startTime;
		_eventData[_cardId].sellEndTime = _endTime;
		_eventData[_cardId].cardAmount = _amount;
		_eventData[_cardId].soldAmount = 0;
		_eventData[_cardId].price = _price;
		for (uint256 i = 0; i < boughtAddress[_cardId].length; i ++) {
			_cardBought[_cardId][boughtAddress[_cardId][i]] = false;
		}
		delete boughtAddress[_cardId];
		emit eventSet(_cardId, _startTime, _endTime);
	}

	function mintCardForUserDuringSellEvent(uint256 _cardId, uint256 _cardCount) public payable{
		require(_eventData[_cardId].sellStartTime >= 0 && _eventData[_cardId].sellEndTime >= 0, "Sell event is not set");
		require(_eventData[_cardId].sellEndTime >= _eventData[_cardId].sellStartTime, "Is the sell event set correctly?");
		require(_eventData[_cardId].soldAmount < _eventData[_cardId].cardAmount, "All cards are sold");
		require(block.timestamp >= _eventData[_cardId].sellStartTime, "Sell event is not started");
		require(block.timestamp <= _eventData[_cardId].sellEndTime, "Sell event is ended");
		require(_cardBought[_cardId][msg.sender] != true, "You've already bought the card");
		require(msg.value == _eventData[_cardId].price, "Invalid price");

		require(_cardCount > 0, "Mint amount should be more than 1");
		require(hal9kLtd._exists(_cardId) != false, "Card not found");
		require(hal9kLtd.totalSupply(_cardId) <= hal9kLtd.maxSupply(_cardId), "Card limit is reached");

		address payable receiver = payable(address(owner()));
		receiver.transfer(msg.value);

		hal9kLtd.mint(msg.sender, _cardId, _cardCount, "");

		_cardBought[_cardId][msg.sender] = true;
		boughtAddress[_cardId].push(msg.sender);
		_eventData[_cardId].soldAmount = _eventData[_cardId].soldAmount + 1;
		emit minted(msg.sender, _cardId, _cardCount);
	}

	// Burn NFT from user
	function burnCardForUser(uint256 _pid, uint256 _cardId, uint256 _cardCount) public {
		require(_cardCount > 0, "Burn amount should be more than 1");
		require(hal9kLtd._exists(_cardId) == true, "Card doesn't exist");
		require(hal9kLtd.totalSupply(_cardId) > 0, "No cards exist");

		uint256 stakeAmount = hal9kVault.getUserInfo(_pid, msg.sender);
		require(stakeAmount > 0 && stakeAmount == lpUsers[msg.sender].stakeAmount, "Invalid user");

		hal9kLtd.burn(msg.sender, _cardId, _cardCount);
		emit burned(msg.sender, _cardId, _cardCount);
	}

	function upgradeCard(uint256 _pid, uint256 _fromCardId, uint256 _fromCardCount, uint256 _toCardId, uint256 _upgradeCardId) public {
		require(_fromCardCount > 0, "Original card should be more than 1");
		require(hal9kLtd._exists(_fromCardId) == true, "From card doesn't exist");
		require(hal9kLtd._exists(_toCardId) == true, "To card doesn't exist");
		require(hal9kLtd._exists(_upgradeCardId) == true, "Upgrade card doesn't exist");
		require(hal9kLtd.totalSupply(_fromCardId) > 0, "No cards exist");
		require(hal9kLtd.totalSupply(_toCardId) <= hal9kLtd.maxSupply(_toCardId), "Unable to upgrade because card limit is reached.");

		uint256 stakeAmount = hal9kVault.getUserInfo(_pid, msg.sender);
		require(stakeAmount > 0 && stakeAmount == lpUsers[msg.sender].stakeAmount, "Invalid user");

		hal9kLtd.burn(msg.sender, _fromCardId, _fromCardCount);
		hal9kLtd.burn(msg.sender, _upgradeCardId, 1);
		hal9kLtd.mint(msg.sender, _toCardId, 1, "");

		emit upgraded(msg.sender, _toCardId);
	}

    address private _superAdmin;

    event SuperAdminTransfered(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlySuperAdmin() {
        require(
            _superAdmin == _msgSender(),
            "Super admin : caller is not super admin."
        );
        _;
    }
	
    function burnSuperAdmin() public virtual onlySuperAdmin {
        emit SuperAdminTransfered(_superAdmin, address(0));
        _superAdmin = address(0);
    }

    function newSuperAdmin(address newOwner) public virtual onlySuperAdmin {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit SuperAdminTransfered(_superAdmin, newOwner);
        _superAdmin = newOwner;
    }
}