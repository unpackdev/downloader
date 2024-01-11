// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AccessControlUpgradeable.sol";
import "./ISVG721.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

/// @title ProtonautSale
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Sale contract for L1.
contract ProtonautSale is
	AccessControlUpgradeable,
	ReentrancyGuardUpgradeable,
	PausableUpgradeable
{
	ISVG721 public Svg721;
	uint256 public price;
	uint256 public maxPurchaseLimit;

	mapping(address => uint256) public userPurchaseLimits;

	event Sold(address indexed _buyer, uint256 _tokenId, uint256 price);
	event SetPrice(uint256 _price);

	/// @param _Svg721 address of Svg721 contract
	/// @param _price price of protonaut
	function initialize(
		address _Svg721,
		uint256 _price,
		uint256 _maxPurchaseLimit
	) public virtual initializer {
		__Ownable_init();
		__ReentrancyGuard_init();
		__Pausable_init();

		Svg721 = ISVG721(_Svg721);
		price = _price;
		maxPurchaseLimit = _maxPurchaseLimit;
	}

	/// @param numberOfTokens tokens to purchase
	function purchase(uint256 numberOfTokens)
		external
		payable
		nonReentrant
		whenNotPaused
	{
		require(
			numberOfTokens + userPurchaseLimits[_msgSender()] <=
				maxPurchaseLimit,
			'Purchase limit exceeded'
		);
		require(msg.value >= price * (numberOfTokens), 'Not enough funds');
		userPurchaseLimits[_msgSender()] += numberOfTokens;

		for (uint256 index = 0; index < numberOfTokens; index++) {
			uint256 tokenId = Svg721.mint(msg.sender);
			emit Sold(msg.sender, tokenId, price);
		}
	}

	/// @notice Removes all eth from the contract
	function withdrawETH() external onlyOwner {
		address payable to = payable(msg.sender);
		to.transfer(address(this).balance);
	}

	/// @notice set the price of the protonaut
	/// @param _price price of the protonaut
	function setPrice(uint256 _price) external onlyAdmin {
		price = _price;
		emit SetPrice(_price);
	}

	function pause(bool enabled) external onlyAdmin {
		if (enabled) {
			_pause();
		} else {
			_unpause();
		}
	}
}
