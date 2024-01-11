// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IFlightTickets.sol";
import "./Rocks.sol";

contract TicketMint is Ownable {
	event TicketUsed(
		address indexed from,
		uint256 indexed zoneId,
		uint256[] ticketTypes,
		uint256[] ticketAmounts,
		uint256 timestamp
	);

	address public signerAddress;

	IFlightTickets public ticketsContract;
	Rocks public rocksContract;

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}

	uint256 constant ROCK_A = 0;
	uint256 constant ROCK_B = 1;
	uint256 constant ROCK_C = 2;
	uint256 constant ROCK_D = 3;
	uint256 constant ROCK_E = 4;
	uint256 constant ROCK_F = 5;
	uint256 constant ROCK_G = 6;
	uint256 constant ROCK_H = 7;
	uint256 constant ROCK_I = 8;
	uint256 constant ROCK_J = 9;
	uint256 constant ROCK_K = 10;
	uint256 constant ROCK_L = 11;
	uint256 constant ROCK_M = 12;
	uint256 constant ROCK_N = 13;
	uint256 constant ROCK_O = 14;

	uint256 constant TICKET_FIRST_CLASS_PPP = 0;
	uint256 constant TICKET_FIRST_CLASS_PP = 1;
	uint256 constant TICKET_FIRST_CLASS_P = 2;
	uint256 constant TICKET_FIRST_CLASS = 3;
	uint256 constant TICKET_BUSINESS = 4;
	uint256 constant TICKET_ECONOMY = 5;

	uint256 constant ZONE_VALLES = 0;
	uint256 constant ZONE_OLYMPUS = 1;
	uint256 constant ZONE_POLAR = 2;

	uint256 public economyMintPrice = 0.08 ether;

	mapping(uint256 => mapping(uint256 => RockData[])) public rocksMap;

	struct RockData {
		uint256 id;
		uint256 quantity;
	}

	constructor() {
		// VALLES
		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_G, 1));
		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_M, 2));

		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_D, 1));
		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_M, 2));

		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_P].push(RockData(ROCK_G, 1));
		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS_P].push(RockData(ROCK_M, 1));

		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS].push(RockData(ROCK_D, 1));
		rocksMap[ZONE_VALLES][TICKET_FIRST_CLASS].push(RockData(ROCK_J, 1));

		rocksMap[ZONE_VALLES][TICKET_BUSINESS].push(RockData(ROCK_A, 1));

		rocksMap[ZONE_VALLES][TICKET_ECONOMY].push(RockData(ROCK_D, 1));

		// OLYMPUS
		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_H, 1));
		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_N, 2));

		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_E, 1));
		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_N, 2));

		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_P].push(RockData(ROCK_H, 1));
		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS_P].push(RockData(ROCK_N, 1));

		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS].push(RockData(ROCK_E, 1));
		rocksMap[ZONE_OLYMPUS][TICKET_FIRST_CLASS].push(RockData(ROCK_K, 1));

		rocksMap[ZONE_OLYMPUS][TICKET_BUSINESS].push(RockData(ROCK_B, 1));

		rocksMap[ZONE_OLYMPUS][TICKET_ECONOMY].push(RockData(ROCK_E, 1));

		// POLAR
		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_I, 1));
		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_PPP].push(RockData(ROCK_O, 2));

		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_F, 1));
		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_PP].push(RockData(ROCK_O, 2));

		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_P].push(RockData(ROCK_I, 1));
		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS_P].push(RockData(ROCK_O, 1));

		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS].push(RockData(ROCK_F, 1));
		rocksMap[ZONE_POLAR][TICKET_FIRST_CLASS].push(RockData(ROCK_L, 1));

		rocksMap[ZONE_POLAR][TICKET_BUSINESS].push(RockData(ROCK_C, 1));

		rocksMap[ZONE_POLAR][TICKET_ECONOMY].push(RockData(ROCK_F, 1));
	}

	/**
	 * @dev Sets the address that generates the signatures for whitelisting
	 */
	function setSignerAddress(address _signerAddress) external onlyOwner {
		signerAddress = _signerAddress;
	}

	/**
	 * @dev Sets the tickets smart contract
	 */
	function setTicketsContract(address _ticketsContractAddress) external onlyOwner {
		ticketsContract = IFlightTickets(_ticketsContractAddress);
	}

	/**
	 * @dev Sets the rocks smart contract
	 */
	function setRocksContract(address _rocksContractAddress) external onlyOwner {
		rocksContract = Rocks(_rocksContractAddress);
	}

	/**
	 * @dev Sets the mint price to be paid by economy tickets holders
	 */
	function setEconomyMintPrice(uint256 _economyMintPrice) external onlyOwner {
		economyMintPrice = _economyMintPrice;
	}

	/**
	 * @dev Allows to withdraw the Ether in the contract.
	 */
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// END ONLY OWNER

	/**
	 * @dev Mints rocks for the given tickets
	 */
	function mint(
		uint256[] memory _ticketTypes,
		uint256[] memory _ticketAmounts,
		uint256 _zone,
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		bytes calldata _signature
	) external payable {
		require(
			ECDSA.recover(generateMessageHash(_fromTimestamp, _toTimestamp, address(this)), _signature) ==
				signerAddress,
			"Invalid signature for the caller"
		);
		require(block.timestamp >= _fromTimestamp, "Too early to mint");
		require(block.timestamp <= _toTimestamp, "The signature has expired");

		require(
			_ticketTypes.length == _ticketAmounts.length,
			"Amount of mints per tickets does not match the ticket array"
		);
		require(_zone <= ZONE_POLAR, "The given zone is not valid");

		uint256 totalToPay;
		uint256[15] memory _rocks;
		for (uint256 i; i < _ticketTypes.length; i++) {
			require(_ticketTypes[i] <= TICKET_ECONOMY, "Invalid ticket type");
			require(_ticketAmounts[i] > 0, "Amount must be greater than 0");

			if (_ticketTypes[i] == TICKET_ECONOMY) {
				totalToPay += _ticketAmounts[i] * economyMintPrice;
			}

			for (uint256 f; f < rocksMap[_zone][_ticketTypes[i]].length; f++) {
				_rocks[rocksMap[_zone][_ticketTypes[i]][f].id] +=
					rocksMap[_zone][_ticketTypes[i]][f].quantity *
					_ticketAmounts[i];
			}
		}

		require(msg.value >= totalToPay, "Not enough ETH to mint");

		uint256 typesCount;
		for (uint256 i; i < _rocks.length; i++) {
			if (_rocks[i] == 0) {
				continue;
			}

			typesCount++;
		}

		require(typesCount > 0, "Nothing to mint");

		uint256[] memory _ids = new uint256[](typesCount);
		uint256[] memory _amounts = new uint256[](typesCount);
		uint256 c;

		for (uint256 i; i < _rocks.length; i++) {
			if (_rocks[i] > 0) {
				_ids[c] = i;
				_amounts[c] = _rocks[i];

				c++;
			}
		}

		ticketsContract.useTickets(msg.sender, _ticketTypes, _ticketAmounts);
		rocksContract.mint(msg.sender, _ids, _amounts);
		emit TicketUsed(msg.sender, _zone, _ticketTypes, _ticketAmounts, block.timestamp);
	}

	/**
	 * @dev Generates the message hash for the given parameters
	 */
	function generateMessageHash(
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		address _contractAddress
	) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked("\x19Ethereum Signed Message:\n84", _fromTimestamp, _toTimestamp, _contractAddress)
			);
	}
}
