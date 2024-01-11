// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Address.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./ApexaNFT.sol";
import "./Whitelist.sol";

contract Sale is Ownable, ReentrancyGuard, Whitelist {
	using Address for address;
	using Address for address payable;
	using Counters for Counters.Counter;

	ApexaNFT public immutable nft;
	bool public onSale;
	bool public onClaim;

	uint256 public price;

	uint256 public saleSupply;
	uint256 public currentSupply;
	uint256 public currentSaleId;

	uint256 public claimSupply;
	uint256 public currentClaim;
	uint256 public currentClaimId;

	string public Url;
	uint256 public lastMintedInPreviousBatch;

	mapping(uint256 => mapping(uint256 => bool)) public hasClaimed;

	event Purchase(uint256 tokenId, address indexed buyer, uint256 price);
	event Claimed(uint256 tokenId, address indexed user, uint256 claimedToken);

	event SaleStarted(uint256 batchId, uint256 timestamp, uint256 count);
	event SaleEnded(uint256 batchId, uint256 timestamp);

	event ClaimStarted(uint256 claimId, uint256 timestamp, uint256 count);
	event ClaimEnded(uint256 claimId, uint256 timestamp);

	constructor(
		address _nft,
		uint256 _price,
		string memory _url
	) Ownable() ReentrancyGuard() {
		require(bytes(_url).length > 0, 'Invalid url');
		require(_nft.isContract(), 'Invalid NFT Address');
		require(_price > 0, 'Invalid price');
		nft = ApexaNFT(_nft);
		price = _price;
		Url = _url;
		currentSaleId = 1; // sale 1 was already completed
	}

	/// @notice To start a sale
	/// @dev Called by owner to start a sale
	/// @param count no of tokens available for sale during the sale
	function startSale(uint256 count) external onlyOwner returns (bool) {
		require(onClaim == false, 'Claim is running');
		require(onSale == false, 'Sale is already running');
		onSale = true;
		saleSupply = count;
		currentSupply = 0;
		currentSaleId++;
		emit SaleStarted(currentSaleId, block.timestamp, count);
		lastMintedInPreviousBatch = nft.totalSupply();
		return true;
	}

	/// @notice To end a sale
	/// @dev Called by owner to end a sale and update the last minted token
	function endSale() external onlyOwner returns (bool) {
		require(onSale == true, 'Sale is not started');
		onSale = false;
		lastMintedInPreviousBatch = nft.totalSupply();
		emit SaleEnded(currentSaleId, block.timestamp);
		return true;
	}

	/// @notice To start a claiming period
	/// @dev Called by owner to start a claiming period
	/// @param count no of tokens available to claim by the token holders during the period
	function startClaim(uint256 count) external onlyOwner returns (bool) {
		require(onSale == false, 'Sale is running');
		onClaim = true;
		claimSupply = count;
		currentClaim = 0;
		currentClaimId++;
		lastMintedInPreviousBatch = nft.totalSupply();
		emit ClaimStarted(currentClaimId, block.timestamp, count);
		return true;
	}

	/// @notice To end a sale
	/// @dev Called by owner to end a sale and update the last minted token
	function endClaim() external onlyOwner returns (bool) {
		require(onClaim == true, 'Claim is not started');
		onClaim = false;
		lastMintedInPreviousBatch = nft.totalSupply();
		emit ClaimEnded(currentClaimId, block.timestamp);
		return true;
	}

	modifier onlyDuringSale() {
		require(onSale, 'Sale is not started');
		_;
	}

	modifier onlyDuringClaim() {
		require(onClaim, 'Claim is not started');
		_;
	}

	/// @notice To purchase a token
	/// @dev Called by the user to purchase a token and can be called only during a sale
	/// @return id id of the purchased token
	function purchase() external payable nonReentrant onlyDuringSale onlyWhitelisted returns (uint256) {
		require(msg.value == price, 'Invalid Price');
		require(currentSupply < saleSupply, 'Sale supply alredy sold');
		address user = _msgSender();
		uint256 id = nft.mint(user, Url);
		emit Purchase(id, user, price);
		currentSupply++;
		return id;
	}

	/// @notice To purchase a `count` tokens
	/// @dev Called by the user to purchase `count` number of tokens and can be called only during a sale
	/// @param count number of tokens user is trying to purchase
	/// @return ids array of id of the purchased tokens
	function batchPurchase(uint256 count)
		external
		payable
		nonReentrant
		onlyDuringSale
		onlyWhitelisted
		returns (uint256[] memory)
	{
		require(msg.value == price * count, 'Invalid Price');
		require(currentSupply + count <= saleSupply, 'Max supply already sold');
		address user = _msgSender();
		string memory _url = Url;
		uint256[] memory ids = new uint256[](count);
		for (uint256 i = 0; i < count; i++) {
			ids[i] = nft.mint(user, _url);
			emit Purchase(ids[i], user, price);
		}
		currentSupply += count;
		return ids;
	}

	/// @notice To claim a token
	/// @dev Called by the token owners to claim a token and can be called only during a claim
	/// @param tokenId id of the token owned by the user
	/// @return id id of the claimed token
	function claim(uint256 tokenId) external nonReentrant onlyDuringClaim onlyWhitelisted returns (uint256) {
		require(tokenId <= lastMintedInPreviousBatch, 'Can not claim for this token');
		require(!hasClaimed[currentClaimId][tokenId], 'Already claimed');
		require(currentClaim <= claimSupply, 'Exceeding max claim supply');
		address user = _msgSender();
		require(nft.ownerOf(tokenId) == user, 'Only token owner can claim');
		uint256 id = nft.mint(user, Url);
		hasClaimed[currentClaimId][tokenId] = true;
		emit Claimed(tokenId, user, id);
		currentClaim++;
		return id;
	}

	/// @notice To claim tokens for a batch
	/// @dev Called by the users to claim tokens for a batch of tokens in once tx.
	/// @param ids array of token ids to claim
	/// @return claimedIds array of ids of the claimed tokens
	function batchClaim(uint256[] calldata ids)
		external
		onlyDuringClaim
		nonReentrant
		onlyWhitelisted
		returns (uint256[] memory)
	{
		uint256 len = ids.length;
		require(currentClaim + len <= claimSupply, 'Exceeding max claim supply');
		uint256 ccId = currentClaimId;
		uint256 _currentClaim;
		uint256 id;
		string memory _url = Url;
		address user = _msgSender();
		uint256[] memory claimedIds = new uint256[](len);
		for (uint256 i = 0; i < len; i++) {
			id = ids[i];
			require(
				!hasClaimed[ccId][id] && id <= lastMintedInPreviousBatch && nft.ownerOf(id) == user,
				'Invalid tokenId'
			);
			claimedIds[i] = nft.mint(user, _url);
			hasClaimed[ccId][id] = true;
			emit Claimed(id, user, claimedIds[i]);
			_currentClaim++;
		}
		currentClaim += _currentClaim;
		return claimedIds;
	}

	/// @notice To update placeholder uri
	/// @dev Called by the admin to update the placeholder
	/// @param url new placeholder url
	function updateURL(string calldata url) external onlyOwner returns (bool) {
		require(bytes(url).length > 0, 'Invalid URL');
		Url = url;
		return true;
	}

	/// @notice To update price
	/// @dev Called by the admin to update the price
	/// @param _price new price
	function updatePrice(uint256 _price) external onlyOwner returns (bool) {
		require(_price > 0, 'Invalid price');
		price = _price;
		return true;
	}

	/// @notice To collect ether balance
	/// @dev Called by the admin to collect the ether balance held by the contract
	/// @param acc address to transfer the tokens
	/// @return bal balance transferred
	function withdraw(address acc) external onlyOwner returns (uint256) {
		uint256 bal = address(this).balance;
		payable(acc).sendValue(bal);
		return bal;
	}

	/// @notice To collect `token` balance
	/// @dev Called by the admin to collect the `token` balance held by the contract
	/// @param token address of the token
	/// @param acc address to transfer the tokens
	/// @return bal balance transferred
	function withdraw(address token, address acc) external onlyOwner returns (uint256) {
		IERC20 tk = IERC20(token);
		uint256 bal = tk.balanceOf(address(this));
		bool sent = tk.transfer(acc, bal);
		require(sent, 'Token Transfer failed');
		return bal;
	}
}
