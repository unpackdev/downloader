// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title A provably fair NFT raffle
/// @author Valerio Leo @valerioHQ
interface IRaffle {
	enum PrizeType {
		ERC1155,
		ERC721
	}

	struct Prize {
		address tokenAddress;
		uint256 tokenId;
		bool claimed;
		PrizeType prizeType;
	}

	struct RaffleInfo {
		uint endDate;
		uint startDate;
		Prize[] prizes;
		address[] players;
		uint256 randomResult;
	}

	event RaffleStarted(uint256 raffleIndex, uint indexed startDate, uint indexed endDate);
	event EnteredGame(uint256 raffleIndex, address indexed player, uint256 playerIndexInRaffle);
	event PrizeAdded(uint256 raffleIndex, uint256 prizeIndex);
	event PrizeClaimed(uint256 raffleIndex, uint256 prizeIndex, address indexed winner);
	event WinnersDrafted(uint256 raffleIndex, uint256 randomNumber);

	/**
	 * @dev It allows to set a new raffle ticket.
	 * @param raffleTicketAddress The raffleTicketAddress. It must be ERC-1155 token.
	 */
	function setRaffleTicket(address raffleTicketAddress) external;

	/**
	 * @dev Initiate a new raffle. It should allow only when a raffle is not
	 * already running. Only the Owner can call this method.
	 * @param startDate The timestamp after when a raffle starts
	 * @param endDate The timestamp after when a raffle can be finalised
	 */
	function startRaffle(uint startDate, uint endDate) external returns (uint256);

	/**
	 * @dev This function helps to get a better picture of a given raffle. It also
	 * @dev helps in verifying offchain the fairness of the Raffle.
	 * @param raffleIndex The index of the Raffle to check.
	 */
	function getPlayersLength(uint256 raffleIndex) external view returns (uint256);

	/**
	 * @dev This function helps to get a better picture of a given raffle by
	 * @dev helping retrieving the number of Prizes
	 * @param raffleIndex The index of the Raffle to check.
	 */
	function getPrizesLength(uint256 raffleIndex) external view returns (uint256);

	/**
	 * @dev With this function the Owner can change the grace period
	 * @dev to withdraw unclamed Prices
	 * @param period The index of the Raffle to check.
	 */
	function changeWithdrawGracePeriod(uint256 period) external;

	/**
	 * @dev A handy getter for a Player of a given Raffle.
	 * @param raffleIndex the index of the Raffle where to get the Player
	 * @param playerIndex the index of the Player to get
	 */
	function getPlayerAtIndex(uint256 raffleIndex, uint256 playerIndex) external view returns (address);

	/**
	 * @dev A handy getter for the Prizes
	 * @param raffleIndex the index of the Raffle where to get the Player
	 * @param prizeIndex the index of the Prize to get
	 */
	function getPrizeAtIndex(uint256 raffleIndex, uint256 prizeIndex) external view returns (address, uint256);

	/**
	 * @dev This method disclosed the committed message and closes the current raffle.
	 * Only the Owner can call this method
	 * @param raffleIndex the index of the Raffle where to draft winners
	 * @param entropy The message in clear. It will be used as part of entropy from Chainlink
	 */
	function draftWinners(uint256 raffleIndex, uint256 entropy) external;

	/**
	 * @dev Allows a winner to withdraw his/her prize
	 * @param raffleIndex The index of the Raffle where to find the Price to withdraw
	 * @param prizeIndex The index of the Prize to withdraw
	 */
	function claimPrize(uint256 raffleIndex, uint prizeIndex) external;

		/**
	 * @dev It maps a given Prize with the address of the winner.
	 * @param raffleIndex The index of the Raffle where to find the Price winner
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function getPrizeWinner(uint256 raffleIndex, uint256 prizeIndex) external view returns (address);

		/**
	 * @dev It maps a given Prize with the index of the winner.
	 * @param raffleIndex The index of the Raffle where to find the Price winner
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function getPrizeWinnerIndex(uint256 raffleIndex, uint256 prizeIndex) external view returns (uint256);

	/**
	 * @dev Prevents locked NFT by allowing the Owner to withdraw an unclaimed
	 * @dev prize after a grace period has passed
	 * @param raffleIndex The index of the Raffle containing the Prize to withdraw
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function unlockUnclaimedPrize(uint256 raffleIndex, uint prizeIndex) external;

	/**
	 * @dev Once a non-ticket NFT is received, it is considered as prize
	 * @dev play multiple tickets.
	 * @dev With this function, we add the received NFT as raffle Prize
	 * @param tokenAddress the address of the NFT received
	 * @param tokenId the id of the NFT received
	 */
	function addERC1155Prize(uint256 raffleIndex, address tokenAddress, uint256 tokenId) external;

	/**
	 * @dev Once a non-ticket NFT is received, it is considered as prize
	 * @dev play multiple tickets.
	 * @dev With this function, we add the received NFT as raffle Prize
	 * @param tokenAddress the address of the NFT received
	 * @param tokenId the id of the NFT received
	 */
	function addERC721Prize(uint256 raffleIndex, address tokenAddress, uint256 tokenId) external;

	/**
	 * @dev Anyone with a valid ticket can enter the raffle. One player can also
	 * @dev play multiple tickets.
	 * @param raffleIndex The index of the Raffle to enter
	 * @param ticketsAmount the number of tickets to play
	 */
	function enterGame(uint256 raffleIndex, uint256 ticketsAmount) external;
}