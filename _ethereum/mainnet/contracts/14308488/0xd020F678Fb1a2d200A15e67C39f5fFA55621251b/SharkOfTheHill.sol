// SPDX-License-Identifier: Commercial
// remember Open Source != Free Software
// for usage contact us at x@to.wtf
// created by https://to.wtf @ 1 Feb 2022
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ITuna.sol";

contract SharkOfTheHill is Ownable, Pausable, ReentrancyGuard {
	address public king;
	uint256 public currentKingAmount = 1 ether; //everything starts with 1 $TUNA
	address public tunaAddress = 0x675F8d4915578C0d6CfCFaB413E3d057d7525444;
	ITuna public tuna;
	uint256 public startRoundTime; //when a round starts
	string public kingMessage = "let the games begin";
	uint256 public minIncreasePercent = 1200; //20% default
	uint256 public roundsTimeout = 2 weeks;

	constructor() {
		king = msg.sender;
		tuna = ITuna(tunaAddress);
		startRoundTime = block.timestamp;
	}

	/**
	 * @notice min amount needed to become king
	 * @param amount - how much you want to add
	 * @param message - your kings message
	 */
	function claimThrone(uint256 amount, string memory message) external whenNotPaused nonReentrant {
		require(amount >= minAmountNeeded(), "check minAmountNeeded()");

		uint256 comission = _calcPercentage(amount, 100);
		tuna.transferFrom(msg.sender, address(this), comission);
		tuna.transferFrom(msg.sender, king, amount - comission);

		currentKingAmount = amount;
		king = msg.sender;
		kingMessage = message;
	}

	/**
	 * @notice min amount needed to become king
	 */
	function minAmountNeeded() public view returns (uint256) {
		return (currentKingAmount * minIncreasePercent) / 1000;
	}

	//calculate percentage
	function _calcPercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
		require(basisPoints >= 0);
		return (amount * basisPoints) / 10000;
	}

	/**
	 * @notice anyone can call it to rest the current round
	 */
	function resetRound() external nonReentrant {
		require(startRoundTime + roundsTimeout <= block.timestamp, "round not ended");
		currentKingAmount = 1 ether;
		startRoundTime = block.timestamp;
		uint256 balance = IERC20(tunaAddress).balanceOf(address(this));
		IERC20(tunaAddress).transfer(owner(), balance);
	}

	/**
	 *	==============================
	 *  ~~~~~~~ ADMIN FUNCTIONS ~~~~~~
	 *  ==============================
	 **/

	/**
	 * @notice sets the $TUNA token
	 */
	function setTunaToken(address tunaContract) external onlyOwner {
		tunaAddress = tunaContract;
		tuna = ITuna(tunaContract);
	}

	/**
	 * @notice sets the min increase % for next king. default: 10%
	 */
	function setMinIncreasePercent(uint256 newPercent) external onlyOwner {
		minIncreasePercent = newPercent;
	}

	/**
	 * @notice sets the round timeout
	 */
	function setRoundsTimeout(uint256 newTimeout) external onlyOwner {
		roundsTimeout = newTimeout;
	}

	//blocks staking but doesn't block unstaking / claiming
	function setPaused(bool _setPaused) public onlyOwner {
		return (_setPaused) ? _pause() : _unpause();
	}

	/**
	 * @notice withdraw fees & accidentally sent erc20 tokens
	 */
	function reclaimERC20(IERC20 token, uint256 _amount) external onlyOwner {
		require(address(token) != address(tuna), "cannot take tuna");
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "incorrect amount");
		token.transfer(msg.sender, _amount);
	}

	/**
	 * @notice withdraw accidentally sent erc721
	 */
	function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
		IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
	}

	/**
	 * @notice withdraw accidentally sent ETH
	 */
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
