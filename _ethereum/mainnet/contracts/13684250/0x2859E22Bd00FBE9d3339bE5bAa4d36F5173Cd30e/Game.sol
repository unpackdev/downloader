//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import "./Ownable.sol";
import "./Prize.sol";

contract Game is Ownable {
	uint256 private constant CURRENT_FIRST = 1;
	uint256 private constant CURRENT_SECOND = 2;
	uint256 private constant CURRENT_THIRD = 3;
	uint256 private constant HALL_OF_FAME_FIRST = 4;
	uint256 private constant PARTICIPANT = 5;

	// ----- Structs

	struct Player {
		bytes32 name;
		string url;
		uint64 lastPayment;
		uint128 score;
		bool receivedPastFirstPrize;
	}

	struct HighScore {
		uint96 score;
		address addr;
	}

	HighScore[3] public highScores;


	// ----- Variables

	address payable private _owner;
	Prize public immutable prize;
	address[] public playerAddresses;
	mapping(address => Player) public players;


	// ----- Events

	event NewPayment(address addr, Player player, uint value);


	// ----- Functions

	constructor(
		address prizeAddress
	) Ownable() {
		_owner = payable(_msgSender());
		prize = Prize(prizeAddress);
	}

	// Validates new payment, creates/updates player, and creates payment
	function pay(
		string memory name,
		string memory url
	) external payable {
		require(bytes(name).length != 0, "Name can't be blank");
		require(_validAsciiString(name), "Name can't contain special chars");
		require(bytes(name).length <= 32, "Max name length is 32 bytes");
		require(bytes(url).length <= 128, "Max URL length is 128 bytes");

		Player storage player = players[_msgSender()];

		bytes32 nameBytes = stringToBytes32(name);

		if(player.score == 0) {
			playerAddresses.push(_msgSender());
			prize.mint(_msgSender(), PARTICIPANT, 1, "");

			player.name = nameBytes;
			player.url = url;
		} else {
			if (nameBytes != player.name) {
				player.name = nameBytes;
			}
			if (keccak256(abi.encodePacked((url))) != keccak256(abi.encodePacked((player.url)))) {
				player.url = url;
			}
		}

		_createPayment();
	}

	function lifetimeBalance() external view returns (uint256) {
		uint256 total = 0;
		for (uint256 i = 0; i < playerAddresses.length; i++) {
			total += players[playerAddresses[i]].score;
		}
		return total;
	}

	// Returns all players
	function getPlayers() external view returns (Player[] memory) {
		Player[] memory allPlayers = new Player[](playerAddresses.length);

		for(uint i; i < playerAddresses.length; i++){
			allPlayers[i] = players[playerAddresses[i]];
		}

		return allPlayers;
	}

	// Returns all player addresses
	function getPlayerAddresses() external view returns (address[] memory) {
		return playerAddresses;
	}

	// Creates player if it does not exist, and creates payment
	receive() external payable {
		if(players[_msgSender()].score == 0) {
			prize.mint(_msgSender(), PARTICIPANT, 1, "");
			playerAddresses.push(_msgSender());
			players[_msgSender()] = Player(stringToBytes32("Anonymous"), "", 0, 0, false);
		}

		_createPayment();
	}

	function withdrawAll() public onlyOwner {
		_owner.transfer(address(this).balance);
	}

	function withdraw(uint amount) public onlyOwner {
		require(amount <= address(this).balance, "Amount exceeds balance");
		_owner.transfer(amount);
	}

	function withdrawTo(
		uint amount,
		address payable to
	) public onlyOwner {
		require(amount <= address(this).balance, "Amount exceeds balance");

		to.transfer(amount);
	}

	// ----- Private

	function _sortHighScores(
		uint96 newScore
	) private {
		// Nothing to do if this is not a new highscore
		if(newScore <= highScores[2].score) return;

		// Set i outside loop, because we need it later
		uint i;

		// This will hold our previous scores
		// As long as highScores remains unchanged, we can also use this as cheaper way
		// to access highScores (because accessing memory variables is cheaper)
		HighScore[3] memory previousHighScores = highScores;

		// Loop through scores, from top to bottom
		for(; i < previousHighScores.length; i++) {
			// Find first score that we've beaten
			if(newScore > previousHighScores[i].score) {
				if(_msgSender() == previousHighScores[i].addr) {
					// We've beaten our own score, update it
					// Return early as we don't need to change the rest
					highScores[i].score = newScore;
					return;
				}

				// Update highScores[i] with ours
				highScores[i].score = newScore;
				highScores[i].addr = _msgSender();

				// We're done here
				// Let's update the remaining scores next
				break;
			}
		}

		// It's time to push down the remaining scores

		// We'll resume with the score after the one we just set
		i++;

		// We'll also set j, which will follow i's value
		uint j = i;

		for(; i < highScores.length; i++) {
			if(previousHighScores[j - 1].addr == _msgSender()) {
				// We'll fast forward to the next value to use,
				// but we'll keep i the same, so we are still iterating
				// through the right scores
				j++;
			}

			highScores[i].score = previousHighScores[j - 1].score;
			highScores[i].addr = previousHighScores[j - 1].addr;
			j++;
		}
	}

	function _createPayment() private {
		require(msg.value >= 0.01 ether, "Minimum amount is 0.01 ETH");

		Player storage player = players[_msgSender()];

		player.score += uint128(msg.value);
		player.lastPayment = uint64(block.timestamp);

		uint96 newScore = uint96(player.score);

		emit NewPayment(_msgSender(), player, msg.value);

		// Return early if player did not change highScores
		if(newScore <= highScores[2].score) return;

		HighScore[3] memory previousHighScores = highScores;

		_sortHighScores(newScore);

		if(highScores[0].addr != previousHighScores[0].addr) {
			// There is a new #1 player

			if(previousHighScores[0].addr == address(0)) {
				// We have not had a #1 player before, so let's mint the NFT
				prize.mint(highScores[0].addr, CURRENT_FIRST, 1, "");
			} else {
				// We did have a #1 player before, so let's transfer the NFT
				prize.safeTransferFrom(previousHighScores[0].addr, highScores[0].addr, CURRENT_FIRST, 1, "");

				if(players[previousHighScores[0].addr].receivedPastFirstPrize != true) {
					// Previous #1 player did not receive hall of fame prize, mint one now
					prize.mint(previousHighScores[0].addr, HALL_OF_FAME_FIRST, 1, "");
					players[previousHighScores[0].addr].receivedPastFirstPrize = true;
				}
			}
		}

		if(highScores[1].addr != previousHighScores[1].addr) {
			// There is a new #2 player

			if(previousHighScores[1].addr == address(0)) {
				// We have not had a #2 player before, so let's mint the NFT
				prize.mint(highScores[1].addr, CURRENT_SECOND, 1, "");
			} else {
				// We did have a #2 player before, so let's transfer the NFT
				prize.safeTransferFrom(previousHighScores[1].addr, highScores[1].addr, CURRENT_SECOND, 1, "");
			}
		}

		if(highScores[2].addr != previousHighScores[2].addr) {
			// There is a new #3 player

			if(previousHighScores[2].addr == address(0)) {
				// We have not had a #3 player before, so let's mint the NFT
				prize.mint(highScores[2].addr, CURRENT_THIRD, 1, "");
			} else {
				// We did have a #3 player before, so let's transfer the NFT
				prize.safeTransferFrom(previousHighScores[2].addr, highScores[2].addr, CURRENT_THIRD, 1, "");
			}
		}
	}

	function stringToBytes32(string memory source) public pure returns (bytes32 result) {
		bytes memory tempEmptyStringTest = bytes(source);
		if (tempEmptyStringTest.length == 0) {
			return 0x0;
		}

		assembly {
			result := mload(add(source, 32))
		}
	}

	function _validAsciiString(string memory text) private pure returns (bool) {
		bytes memory b = bytes(text);

		for(uint i; i < b.length; i++){
			if(!(b[i] >= 0x20 && b[i] <= 0x7E)) return false;
		}

		return true;
	}
}
