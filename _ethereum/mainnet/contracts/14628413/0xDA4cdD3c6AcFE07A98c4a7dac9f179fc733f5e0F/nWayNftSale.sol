// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./ApexaNFT.sol";
import "./Whitelist.sol";

contract NFTSale is Whitelist {
	using Address for address;
	using SafeMath for uint256;
	using Counters for Counters.Counter;
	Counters.Counter private NftId;
	ApexaNFT public nftContract;

	mapping(address => Counters.Counter) public userPurchaseCounter;
	uint256 public purchaseLimit;
	bool public isSaleEnabled;
	uint256 public price;

	string public placeholderURI;

	event Sold(uint256 _nftId, address _buyer, uint256 _price);
	event EnableSale(bool _isSaleEnabled);

	constructor(
		address _nftAddress,
		uint256 _purchaseLimit,
		uint256 _price,
		bool _checkForWhitelist,
		string memory _placeholderURI
	) {
		require(_nftAddress.isContract(), '_nftAddress must be a contract');
		nftContract = ApexaNFT(_nftAddress);
		purchaseLimit = _purchaseLimit;
		price = _price;
		checkForWhitelist = _checkForWhitelist;
		placeholderURI = _placeholderURI;
	}

	/**
	 * @notice - Enable/Disable Sales
	 * @dev - callable only by owner
	 *
	 * @param _isSaleEnabled - enable? sales
	 */
	function setSaleEnabled(bool _isSaleEnabled) public onlyOwner {
		isSaleEnabled = _isSaleEnabled;
		emit EnableSale(isSaleEnabled);
	}

	function setPlaceholderURI(string memory _placeholderURI) external onlyAdmin {
		placeholderURI = _placeholderURI;
	}

	/**
	 * @notice - Set Placeholder URI
	 * @dev - callable only by owner
	 *
	 * @param _price - price of NFTs
	 */
	function setPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	function _purchase() internal {
		address buyer = _msgSender();
		require(userPurchaseCounter[buyer].current() < purchaseLimit, 'Purchase amount exceeds the limit per wallet');

		uint256 _nftId = nftContract.mint(buyer, placeholderURI);

		userPurchaseCounter[buyer].increment();

		emit Sold(_nftId, buyer, price);
	}

	/**
	 * Purchase nftContract
	 *
	 */
	function purchase() external payable onlyDuringSale onlyWhitelisted {
		require(msg.value == price, 'Insufficient or excess funds');
		_purchase();
	}

	/**
	 * Purchase Batch of NFTs
	 *
	 * @param numberOfTokens - TokenIds to be purchased
	 */
	function batchPurchase(uint256 numberOfTokens) external payable onlyDuringSale onlyWhitelisted {
		require(msg.value == price * numberOfTokens, 'Insufficient or excess funds');

		for (uint256 i = 0; i < numberOfTokens; i++) {
			_purchase();
		}
	}

	/**
	 * Withdraw any ETH funds on contract
	 */
	function withdrawETH() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function withdrawFunds(
		address tokenAddress,
		uint256 amount,
		address wallet
	) external onlyOwner {
		IERC20(tokenAddress).transfer(wallet, amount);
	}

	modifier onlyDuringSale() {
		require(isSaleEnabled, 'Sale is not enabled');
		_;
	}
}
