// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./RaffleAdminAccessControl.sol";
import "./IRaffle.sol";
import "./VRFConsumerBase.sol";

/// @title A provably fair NFT raffle
/// @author Valerio Leo @valerioHQ
contract Raffle is IRaffle, RaffleAdminAccessControl, IERC721Receiver, IERC1155Receiver, VRFConsumerBase {
	bytes32 internal keyHash;
	uint256 internal fee;

	mapping(bytes32 => uint256) public randomnessRequests;

	RaffleInfo[] public raffleInfo;

	ERC1155 public raffleTicket;

	uint256 public withdrawGracePeriod;

	constructor(
		address raffleTicketAddress,
		bytes32 _keyHash,
		address VRFCoordinator,
		address LINKToken,
		uint256 _fee
	)
		VRFConsumerBase(
			VRFCoordinator, // VRF Coordinator
			LINKToken  // LINK Token
		)
		RaffleAdminAccessControl(
			msg.sender,
			raffleTicketAddress
		)
		public
	{
		keyHash = _keyHash;
		fee = _fee;

		setRaffleTicket(raffleTicketAddress);
		changeWithdrawGracePeriod(60 * 60 * 24 * 7); // 1 week in seconds
	}

	modifier raffleExists(uint256 raffleIndex) {
		require(raffleInfo.length > raffleIndex, 'Raffle: Raffle does not exists');
		_;
	}

	modifier raffleIsRunning(uint256 raffleIndex) {
		require(
			raffleInfo[raffleIndex].startDate <= now() &&
			now() <= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle not running'
		);
		_;
	}

	modifier raffleIsConcluded(uint256 raffleIndex) {
		require(now() >= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle is not concluded yet');
		_;
	}

	modifier raffleIsNotConcluded(uint256 raffleIndex) {
		require(now() <= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle is already concluded');
		_;
	}

	/**
	* @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	* by `operator` from `from`, this function is called.
	*
	* It must return its Solidity selector to confirm the token transfer.
	* If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	*
	* The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
	*/
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	/**
	* @dev Handles the receipt of a multiple ERC1155 token types. This function
		is called at the end of a `safeBatchTransferFrom` after the balances have
		been updated. To accept the transfer(s), this must return
		`bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
		(i.e. 0xbc197c81, or its own function selector).
	* @param operator The address which initiated the batch transfer (i.e. msg.sender)
	* @param from The address which previously owned the token
	* @param ids An array containing ids of each token being transferred (order and length must match values array)
	* @param values An array containing amounts of each token being transferred (order and length must match ids array)
	* @param data Additional data with no specified format
	* @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
	*/
	function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	/**
	 * @dev It allows to set a new raffle ticket.
	 * @param raffleTicketAddress The raffleTicketAddress. It must be ERC-1155 token.
	 */
	function setRaffleTicket(address raffleTicketAddress) public override onlyManager {
		require(raffleTicketAddress != address(0), 'Raffle: RaffleTicket address cannot be zero');

		raffleTicket = ERC1155(raffleTicketAddress);
	}

	/**
	*	@dev Handles the receipt of a single ERC1155 token type. This function is
		called at the end of a `safeTransferFrom` after the balance has been updated.
		To accept the transfer, this must return
		`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
		(i.e. 0xf23a6e61, or its own function selector).
	*	@param operator The address which initiated the transfer (i.e. msg.sender)
	*	@param from The address which previously owned the token
	*	@param id The ID of the token being transferred
	*	@param value The amount of tokens being transferred
	*	@param data Additional data with no specified format
	*	@return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
	*/
	function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	// ERC165 interface support
	function supportsInterface(bytes4 interfaceID) public pure override(IERC165, AccessControlEnumerable) returns (bool) {
			return  interfaceID == 0x01ffc9a7 ||    // ERC165
							interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
	}

	/**
	* @dev Initiate a new raffle.
	* Only the Owner can call this method.
	* @param startDate The timestamp after when a raffle starts
	* @param endDate The timestamp after when a raffle can be finalised
	* @return (uint256) the index of the raffle
	*/
	function startRaffle(uint startDate, uint endDate) public override onlyManager returns (uint256) {
		require(startDate > now(), 'Raffle: Start date should be later than current block time');
		require(startDate < endDate, 'Raffle: End date should be later than start date');

		raffleInfo.push();
		uint256 newIndex = raffleInfo.length - 1;

		raffleInfo[newIndex].startDate = startDate;
		raffleInfo[newIndex].endDate = endDate;
		raffleInfo[newIndex].randomResult = 0;

		emit RaffleStarted(newIndex, startDate, endDate);

		return newIndex;
	}

	/**
	* @dev This function helps to get a better picture of a given raffle. It also
	* @dev helps in verifying offchain the fairness of the Raffle.
	* @param raffleIndex The index of the Raffle to check.
	* @return (uint256) the number of players in the raffle
	*/
	function getPlayersLength(uint256 raffleIndex) public override view  returns (uint256) {
		return raffleInfo[raffleIndex].players.length;
	}

	/**
	* @dev This function helps to get a better picture of a given raffle by
	* @dev helping retrieving the number of Prizes
	* @param raffleIndex The index of the Raffle to check.
	* @return (uint256) the number of prizes in the raffle
	*/
	function getPrizesLength(uint256 raffleIndex) public override view  returns (uint256) {
		return raffleInfo[raffleIndex].prizes.length;
	}

	/**
	* @dev With this function the Owner can change the grace period
	* @dev to withdraw unclamed Prices
	* @param period The length of the grace period in seconds
	*/
	function changeWithdrawGracePeriod(uint256 period) public onlyManager override {
		require(period >= 60 * 60 * 24 * 7, 'Withdraw grace period too short'); // 1 week in seconds

		withdrawGracePeriod = period;
	}

	/**
	* @dev A handy getter for a Player of a given Raffle.
	* @param raffleIndex the index of the Raffle where to get the Player
	* @param playerIndex the index of the Player to get
	* @return (address) the address of the player
	*/
	function getPlayerAtIndex(
		uint256 raffleIndex,
		uint256 playerIndex
	)
		public
		view
		override
		raffleExists(raffleIndex)
		returns (address)
	{
		require(playerIndex < raffleInfo[raffleIndex].players.length, 'Raffle: No Player at index');

		return raffleInfo[raffleIndex].players[playerIndex];
	}

	/**
	* @dev A handy getter for the Prizes
	* @param raffleIndex the index of the Raffle where to get the Player
	* @param prizeIndex the index of the Prize to get
	* @return (address, uint256) the prize address and the prize tokenId
	*/
	function getPrizeAtIndex(uint256 raffleIndex, uint256 prizeIndex) public override view returns (address, uint256) {
		return (
			raffleInfo[raffleIndex].prizes[prizeIndex].tokenAddress,
			raffleInfo[raffleIndex].prizes[prizeIndex].tokenId
		);
	}

	/**
	 * @dev This method disclosed the committed message and closes the current raffle.
	 * Only the Owner can call this method
	 * @param raffleIndex the index of the Raffle where to draft winners
	 * @param entropy The message in clear. It will be used as part of entropy from Chainlink
	 */
	function draftWinners(
		uint256 raffleIndex,
		uint256 entropy
	)
		public
		override
		onlyManager
		raffleExists(raffleIndex)
		raffleIsConcluded(raffleIndex)
	{
		require(raffleInfo[raffleIndex].randomResult == 0, 'Raffle: Randomness already requested');

		raffleInfo[raffleIndex].randomResult = 1; // 1 is our flag for 'pending'

		if(getPlayersLength(raffleIndex) > 0 && getPrizesLength(raffleIndex) > 0) {
			getRandomNumber(raffleIndex, entropy);
		}
		else {
			raffleInfo[raffleIndex].randomResult = 2; // 2 is our flag for 'concluded without Players or Prizes'

			emit WinnersDrafted(raffleIndex, 2);
		}
	}

	/**
	 * @dev Allows a winner to withdraw his/her prize
	 * @param raffleIndex The index of the Raffle where to find the Price to withdraw
	 * @param prizeIndex The index of the Prize to withdraw
	 */
	function claimPrize(
		uint256 raffleIndex,
		uint prizeIndex
	)
		public
		override
		raffleExists(raffleIndex)
		raffleIsConcluded(raffleIndex)
	{
		require(
			raffleInfo[raffleIndex].randomResult != 0 &&
			raffleInfo[raffleIndex].randomResult != 1,
			'Raffle: Random Number not drafted yet'
		);

		address prizeWinner = getPrizeWinner(raffleIndex, prizeIndex);
		require(msg.sender == prizeWinner, 'Raffle: You are not the winner of this Prize');

		_transferPrize(raffleIndex, prizeIndex, prizeWinner);
	}

	/**
	* @dev It maps a given Prize with the address of the winner.
	* @param raffleIndex The index of the Raffle where to find the Price winner
	* @param prizeIndex The index of the prize to withdraw
	* @return (uint256) The index of the winning account
	*/
	function getPrizeWinner(uint256 raffleIndex, uint256 prizeIndex) public override view  returns (address) {
		uint winnerIndex = getPrizeWinnerIndex(raffleIndex, prizeIndex);

		return raffleInfo[raffleIndex].players[winnerIndex];
	}

	/**
	* @dev It maps a given Prize with the index of the winner.
	* @param raffleIndex The index of the Raffle where to find the Price winner
	* @param prizeIndex The index of the prize to withdraw
	* @return (uint256) The index of the winning account
	*/
	function getPrizeWinnerIndex(
		uint256 raffleIndex,
		uint256 prizeIndex
	)
		public
		override
		view
		raffleIsConcluded(raffleIndex)
		returns (uint256)
	{
		require(getPlayersLength(raffleIndex) > 0, 'Raffle: Raffle concluded without Players');
		require(
			raffleInfo[raffleIndex].randomResult != 0 &&
			raffleInfo[raffleIndex].randomResult != 1,
			'Raffle: Randomness pending'
		);

		bytes32 randomNumber = keccak256(abi.encode(raffleInfo[raffleIndex].randomResult + prizeIndex));
		return uint(randomNumber) % getPlayersLength(raffleIndex);
	}

	/**
	 * @dev Prevents locked NFT by allowing the Owner to withdraw an unclaimed
	 * @dev prize after a grace period has passed
	 * @param raffleIndex The index of the Raffle containing the Prize to withdraw
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function unlockUnclaimedPrize(
		uint256 raffleIndex,
		uint prizeIndex
	)
		public
		override
		onlyPrizeManager
		raffleIsConcluded(raffleIndex)
	{
		require(
			now() >= raffleInfo[raffleIndex].endDate + withdrawGracePeriod ||
			getPlayersLength(raffleIndex) == 0, // if there is no players, we can withdraw immediately
			'Raffle: Grace period not passed yet'
		);

		_transferPrize(raffleIndex, prizeIndex, msg.sender);
	}

	/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	* @param prizeType the type of prize to add. 0=ERC1155, 1=ERC721
	*/
	function _addPrize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId,
		PrizeType prizeType
	) internal {
		Prize memory prize;
		prize.tokenAddress = tokenAddress;
		prize.tokenId = tokenId;
		prize.prizeType = prizeType;

		raffleInfo[raffleIndex].prizes.push(prize);

		uint256 prizeIndex = raffleInfo[raffleIndex].prizes.length - 1;

		emit PrizeAdded(raffleIndex, prizeIndex);
	}

/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received ERC1155 NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	*/
	function addERC1155Prize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
		override
		onlyPrizeManager
		raffleExists(raffleIndex)
		raffleIsNotConcluded(raffleIndex)
	{ 
		ERC1155 prizeInstance = ERC1155(tokenAddress);

		prizeInstance.safeTransferFrom(msg.sender, address(this), tokenId, 1, '');

		_addPrize(raffleIndex, tokenAddress, tokenId, PrizeType.ERC1155);
	}

/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received ERC721 NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	*/
	function addERC721Prize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
		override
		onlyPrizeManager
		raffleExists(raffleIndex)
		raffleIsNotConcluded(raffleIndex)
	{ 
		ERC721 prizeInstance = ERC721(tokenAddress);

		prizeInstance.safeTransferFrom(msg.sender, address(this), tokenId);

		_addPrize(raffleIndex, tokenAddress, tokenId, PrizeType.ERC721);
	}

	/**
	* @dev Anyone with a valid ticket can enter the raffle. One player can also
	* @dev play multiple tickets.
	* @notice MUST trigger EnteredGame event
	* @param raffleIndex The index of the Raffle to enter
	* @param ticketsAmount the number of tickets to play
	*/
	function enterGame(
		uint256 raffleIndex,
		uint256 ticketsAmount
	)
		public
		override
		raffleExists(raffleIndex)
		raffleIsRunning(raffleIndex)
	{

		raffleTicket.safeTransferFrom(msg.sender, address(this), 0, ticketsAmount, '');

		for (uint i = 0; i < ticketsAmount; i++) {
			raffleInfo[raffleIndex].players.push(msg.sender);

			emit EnteredGame(raffleIndex, msg.sender, raffleInfo[raffleIndex].players.length - 1);
		}
	}

	/**
	* @dev It transfers the prize to a given address.
	* @notice MUST trigger WinnersDrafted event
	* @param raffleIndex The index of the Raffle to enter
	* @param prizeIndex The index of the prize to withdraw
	* @param winnerAddress The address of the winner
	*/
	function _transferPrize(uint256 raffleIndex, uint prizeIndex, address winnerAddress) internal {
		Prize storage prize = raffleInfo[raffleIndex].prizes[prizeIndex];

		if(prize.prizeType == PrizeType.ERC1155) {
			ERC1155 prizeInstance = ERC1155(prize.tokenAddress);

			prizeInstance.safeTransferFrom(address(this), winnerAddress, prize.tokenId, 1, '');
		} else {
			ERC721 prizeInstance = ERC721(prize.tokenAddress);

			prizeInstance.safeTransferFrom(address(this), winnerAddress, prize.tokenId);
		}

		raffleInfo[raffleIndex].prizes[prizeIndex].claimed = true;

		emit PrizeClaimed(raffleIndex, prizeIndex, winnerAddress);
	}

	/**
	* @dev Requests randomness from a user-provided seed
	* @param raffleIndex The index of the Raffle to to require randomness for
	* @param userProvidedSeed The seed provided by the Owner
	* @return requestId (bytes32) the request id
	*/
	function getRandomNumber(
		uint256 raffleIndex,
		uint256 userProvidedSeed
	)
		internal
		returns (bytes32 requestId)
	{
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

		bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
		randomnessRequests[requestId] = raffleIndex;
		raffleInfo[raffleIndex].randomResult = 1; // a flag for pending randomness

		return requestId;
	}

	/**
	* @dev Callback function used by VRF Coordinator
	* @notice MUST trigger WinnersDrafted event
	* @param requestId The id of the request being fulfilled
	* @param randomness The result of the randomness request
	*/
	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		uint256 raffleIndex = randomnessRequests[requestId];

		require(raffleInfo[raffleIndex].randomResult == 1, 'Raffle: Request already fulfilled');

		raffleInfo[raffleIndex].randomResult = randomness;

		emit WinnersDrafted(randomnessRequests[requestId], randomness);
	}

	/**
	 * @dev A simple time util
	 * @return (uint256) current block timestamp
	 */
	function now() internal view returns (uint256) {
		return block.timestamp;
	}
}
