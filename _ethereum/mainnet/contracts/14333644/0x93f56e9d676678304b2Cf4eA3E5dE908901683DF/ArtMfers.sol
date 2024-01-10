// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./Base.sol";

/*  AͣRͬᴛⷮ MⷨFEͤRͬS͛
 *
 * ░█████╗░██████╗░████████╗  ███╗░░░███╗███████╗███████╗██████╗░░██████╗
 * ██╔══██╗██╔══██╗╚══██╔══╝  ████╗░████║██╔════╝██╔════╝██╔══██╗██╔════╝
 * ███████║██████╔╝░░░██║░░░  ██╔████╔██║█████╗░░█████╗░░██████╔╝╚█████╗░
 * ██╔══██║██╔══██╗░░░██║░░░  ██║╚██╔╝██║██╔══╝░░██╔══╝░░██╔══██╗░╚═══██╗
 * ██║░░██║██║░░██║░░░██║░░░  ██║░╚═╝░██║██║░░░░░███████╗██║░░██║██████╔╝
 * ╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░
 *
 */
contract ArtMfers is Ownable, Base, ReentrancyGuard {
	using SafeMath for uint256;

	constructor(address[3] memory receiverAddresses_, uint8[3] memory receiverPercentages_) ERC721A("Art Mfers", "AMFER") {
		receiverAddresses = receiverAddresses_;
		for (uint256 i; i < receiverAddresses_.length; i++) {
			team[receiverAddresses_[i]] = TeamMember(receiverPercentages_[i], 0);
		}
	}

	/**
	 * @dev Mint airdrop tokens to a specific addresses
	 * @param to list of addresses to mint token for
	 * @param quantity list for how many to mint to each adddress
	 */
	function airdrop(address[] memory to, uint8[] memory quantity) external onlyOwner {
		uint8 totalQuantity;
		for (uint8 i = 0; i < quantity.length; i++) {
			totalQuantity += quantity[i];
			_mint(to[i], quantity[i], "", false);
			emit Airdrop(to[i], quantity[i]);
		}
		if (totalQuantity + mintedAirdrops > maxAirdrops) revert ToManyToMint();
		mintedAirdrops += totalQuantity;
	}

	/**
	 * @dev Mint tokens to a specific address
	 * @param to address to mint token for
	 * @param quantity for how many to mint
	 */
	function mint(address to, uint8 quantity) external payable nonReentrant {
		if (!mintedStarted) revert MintingIsNotStarted();
		if (quantity > MAX_TOKENS_PER_PURCHASE) revert TooManyToMintInOneTransaction();
		if (quantity + totalSupply() - mintedAirdrops > MAX_TOKENS - maxAirdrops) revert ToManyToMint();

		if (msg.value < MINT_PRICE.mul(quantity)) revert NotEnoughtETH();

		distributeFunds();
		if (currentBatchMinted + quantity >= batchSize) {
			currentBatchMinted = 0;
			sendFunds();
		} else {
			currentBatchMinted += quantity;
		}

		_mint(to, quantity, "", false);
		emit Minted(_msgSender(), to, quantity);
	}


	/**
	 * @dev split the eth based on team percentages
	 */
	function distributeFunds() internal {
		for (uint256 i; i < receiverAddresses.length; i++) {
			address receiverAddress = receiverAddresses[i];
			uint256 percentage = team[receiverAddress].percentage;
			team[receiverAddress].balance += (msg.value * percentage) / 100;
		}
	}

	/**
	 * @dev send the collected eth to the team
	 */
	function sendFunds() internal {
		for (uint256 i; i < receiverAddresses.length; i++) {
			address receiverAddress = receiverAddresses[i];
			uint256 balance = team[receiverAddress].balance;
			team[receiverAddress].balance = 0;
			_sendValueTo(receiverAddress, balance);
		}
	}

	/**
	 * @dev Withdraw an amount to a given address
	 * @param tos addresses to receive the ETH
	 * @param valuesToWithdraw from remaining balance
	 */
	function withdrawTeamMemberBalanceTo(address[] memory tos, uint256[] memory valuesToWithdraw) external nonReentrant {
		uint256 maxToWithdraw = team[_msgSender()].balance;
		if (maxToWithdraw == 0) revert NoBalanceToWithdraw();

		for (uint256 i = 0; i < tos.length; i++) {
			uint256 valueToWithdraw = valuesToWithdraw[i];

			if (maxToWithdraw < valueToWithdraw) revert ToMuchToWithdraw();

			if (valueToWithdraw == 0) valueToWithdraw = maxToWithdraw;

			maxToWithdraw -= valueToWithdraw;

			team[_msgSender()].balance -= valueToWithdraw;

			_sendValueTo(tos[i], valueToWithdraw);
		}
	}

	/**
	 * @dev Change the current team member address with a new one
	 * @param newAddress Address which can withdraw the ETH based on percentage
	 */
	function changeTeamMemberAddress(address newAddress) external {
		bool found;
		for (uint256 i; i < receiverAddresses.length; i++) {
			if (receiverAddresses[i] == _msgSender()) {
				receiverAddresses[i] = newAddress;
				found = true;
				break;
			}
		}
		if (!found) revert NotAllowed();

		team[newAddress] = team[_msgSender()];
		delete team[_msgSender()];
	}
}
