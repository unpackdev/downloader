// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./console.sol";

import "./IRiddleKey.sol";
import "./AdminRole.sol";

contract RiddleKeyVault is Ownable, AdminRole, ERC1155Holder {
	using SafeMath for uint;
	using Address for address;

	struct KeyPriceHashMask {
		uint32 stage;
		uint price;
		uint32 amount;
	}

	event StartedSell(uint sellPeriodTime, uint timeDelayForStartLevel, uint sellStartTime);
	event AllKeySoldOut();
	event SoldKeyOut();

	IRiddleKey internal _riddleKey;
	mapping(uint32 => KeyPriceHashMask) internal _keyPriceHashMaskByStage;
	uint internal _sellStartTime;
	uint32 internal _lastStage = 0;
	bool internal _sellStarted = false;
	uint internal _sellPeriodTime = 7 days;
	uint internal _timeDelayForStartLevel = 24 hours;
	uint internal _soldOutKeyInStock = 0;

	constructor(address riddleKey) {
		_riddleKey = IRiddleKey(riddleKey);
	}

	function resetKeySaleStrategy() public onlyAdmin {
		for (uint32 i = 1; i < _lastStage + 1; i++) {
			_keyPriceHashMaskByStage[i].price = 0;
			_keyPriceHashMaskByStage[i].amount = 0;
		}
	}

	function initialize() external onlyAdmin {
		_riddleKey.initialize();
		resetKeySaleStrategy();
	}

	function getRiddleKey() public view returns (address) {
		return address(_riddleKey);
	}

	function setRiddleKey(address riddleKey) public onlyAdmin {
		_riddleKey = IRiddleKey(riddleKey);
	}

	function hashMaskStrategyForSaleOf(uint32 stage) public view returns (uint price, uint32 amount) {
		price = _keyPriceHashMaskByStage[stage].price;
		amount = _keyPriceHashMaskByStage[stage].amount;
		return (price, amount);
	}

	function getLastStage() public view returns (uint) {
		return _lastStage;
	}

	function getSellStartTime() public view returns (uint) {
		return _sellStartTime;
	}

	function getSellPeriodTime() public view returns (uint) {
		return _sellPeriodTime;
	}

	function getTimeDelayForStartLevel() public view returns (uint) {
		return _timeDelayForStartLevel;
	}

	function getCurrentKeyPrice() external view returns (uint) {
		return _currentKeyPrice();
	}

	function levelOf(uint tokenId) external view returns (uint) {
		return _riddleKey.levelOf(tokenId);
	}

	function tokenOf(uint32 level) external view returns (uint32) {
		return _riddleKey.tokenOf(level);
	}

	function currentSupplyOf(uint level) external view returns (uint) {
		return _riddleKey.currentSupplyOf(level);
	}

	function getSoldoutKeyStock() external view returns (uint) {
		return _soldOutKeyInStock;
	}

	function setHashMaskStrategy(uint32 stage, uint32 amount, uint price) external onlyAdmin {
		_keyPriceHashMaskByStage[stage] = KeyPriceHashMask({stage: stage, amount: amount, price: price});
		if (_lastStage < stage) {
			_lastStage = stage;
		}
	}

	function setSellEvent(uint sellPeriod, uint timeDelay) public onlyAdmin {
		_sellPeriodTime = sellPeriod;
		_timeDelayForStartLevel = timeDelay;
		_sellStarted = true;
		_sellStartTime = block.timestamp;

		emit StartedSell(sellPeriod, timeDelay, _sellStartTime);
	}

	function tranferKey(address to, uint tokenId, uint amount) external onlyOwner {
		_transferKey(to, tokenId, amount);
	}

	function buyKey(address to, uint tokenId, uint amount, uint providedETH) external onlyOwner {
		require(_riddleKey.levelOf(tokenId) == 1 || _sellStarted == true, 'Not permitted to buy this token');
		uint remainKeyCount = _riddleKey.balanceOf(address(this), tokenId);
		require(remainKeyCount > 0, 'All keys has been sold out already');

		uint keyPrice = _currentKeyPrice();
		require(providedETH >= keyPrice, 'given ETH price is not sufficient to buy a key');
		_transferKey(to, tokenId, amount);
		_soldOutKeyInStock = _soldOutKeyInStock.add(providedETH);
		emit SoldKeyOut();
	}

	function _transferKey(address to, uint tokenId, uint amount) internal {
		_riddleKey.safeTransferFrom(address(this), to, tokenId, amount, '');
		uint remainKeyCount = _riddleKey.balanceOf(address(this), tokenId);
		if (remainKeyCount == 0) {
			emit AllKeySoldOut();
		}
	}

	function _currentKeyPrice() private view returns (uint) {
		require(_lastStage > 0, 'Not set the price strategy yet');

		uint remainKeyCount = _riddleKey.balanceOf(address(this), 1);
		uint soldKeyCount = _riddleKey.maxSupplyOf(1) - remainKeyCount;

		uint currentKeyPrice = _keyPriceHashMaskByStage[1].price;
		uint previousAmount = 0;
		for (uint32 i = 1; i < _lastStage + 1; i++) {
			if (previousAmount.add(_keyPriceHashMaskByStage[i].amount) >= soldKeyCount) {
				currentKeyPrice = _keyPriceHashMaskByStage[i].price;
				break;
			}
			previousAmount = _keyPriceHashMaskByStage[i].amount;
		}
		return currentKeyPrice;
	}
}
