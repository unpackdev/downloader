// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";

library BatchCounters {
	struct Counter {
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter, uint256 amount) internal returns (uint256 start, uint256 end) {
		start = counter._value + 1;
		counter._value += amount;
		end = counter._value + 1;
	}
}

interface ITreasuryDAO {
	function raise() external payable;
}

contract ProjectSummit is ERC721, Ownable {
	using Strings for uint256;
	using BatchCounters for BatchCounters.Counter;
	BatchCounters.Counter private _tokenIds;

	struct Phase {
		string name;
		uint256 start;
		uint256 end;
		uint256 mintFee;
		uint256 reserve;
		string baseURI;
	}

	event PhaseAdded(Phase newPhase);
	event PhaseUpdated(Phase phase);
	event TicketReserved(uint256 phase);

	uint8 public constant MAX_MINT = 4;

	string private defaultBase;
	uint256 public maxSupply;

	mapping(bytes32 => uint256) public userTickets;
	mapping(bytes32 => uint256) private userMints;
	uint256 public tickets;

	Phase[] public phases;
	uint256 public currentPhase;

	address public treasury;

	uint8 public state;

	constructor(address _treasury, string memory _base) ERC721("ProjectSummit", "SUMMIT") {
		treasury = _treasury;
		defaultBase = _base;
	}

	modifier onlyState(uint8 _state) {
		require(state == _state, "Not Allowed");
		_;
	}

	function setState(uint8 _state) external onlyOwner {
		state = _state;
	}

	function setDefaultBase(string memory _base) external onlyOwner {
		defaultBase = _base;
	}

	function setBaseURI(uint256 phase, string memory _baseURI) external onlyOwner {
		phases[phase].baseURI = _baseURI;
	}

	function getTokenPhase(uint256 tokenId) internal view returns (uint256 phase) {
		phase = 0;
		uint256 max = phases[phase].end;
		while (max < tokenId) {
			phase++;
			max = phases[phase].end;
		}
	}

	function getUserHash(address user, uint256 phase) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(user, phase));
	}

	function totalSupply() public view returns (uint256) {
		return _tokenIds.current() + tickets;
	}

	function totalPhases() public view returns (uint256) {
		return phases.length;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "Token Invalid");
		uint256 tokenPhase = getTokenPhase(tokenId);
		return
			bytes(phases[tokenPhase].baseURI).length > 0
				? string(abi.encodePacked(phases[tokenPhase].baseURI, tokenId.toString(), ".json"))
				: string(abi.encodePacked(defaultBase, tokenId.toString()));
	}

	function getUserTickets(address user) public view returns (uint256) {
		return userTickets[getUserHash(user, currentPhase)];
	}

	function getUserMints(address user) public view returns (uint256) {
		return userMints[getUserHash(user, currentPhase)];
	}

	function _batchFrom(uint256 start, uint256 end) internal {
		for (uint256 i = start; i < end; i++) {
			_mint(msg.sender, i);
		}
	}

	function _batch(uint256 amount) internal {
		(uint256 start, uint256 end) = _tokenIds.increment(amount);
		_batchFrom(start, end);
	}

	function _batchLimit(uint256 amount, bytes32 userHash) internal {
		userMints[userHash] += amount;
		_batch(amount);
	}

	function reserveTickets(uint256 amount) external payable onlyState(1) {
		require(totalSupply() + amount <= maxSupply, "Max Supply Reached");
		bytes32 userHash = getUserHash(msg.sender, currentPhase);
		require(userTickets[userHash] + amount <= MAX_MINT, "Amount Invalid");
		require(msg.value >= phases[currentPhase].mintFee * amount, "Fee Insufficient");
		tickets += amount;
		userTickets[userHash] = userTickets[userHash] + amount;
	}

	function mint(uint256 amount) external payable onlyState(2) {
		require(totalSupply() + amount <= maxSupply, "Max Supply Reached");
		bytes32 userHash = getUserHash(msg.sender, currentPhase);
		require(userTickets[userHash] + userMints[userHash] + amount <= MAX_MINT, "Amount Invalid");
		require(msg.value >= phases[currentPhase].mintFee * amount, "Fee Insufficient");
		_batchLimit(amount, userHash);
	}

	function claim() external onlyState(2) {
		bytes32 userHash = getUserHash(msg.sender, currentPhase);
		uint256 amount = userTickets[userHash];
		require(tickets >= amount, "Amount Invalid");
		delete userTickets[userHash];
		tickets -= amount;
		_batchLimit(amount, userHash);
	}

	function addPhase(
		string memory name,
		uint256 supply,
		uint256 mintFee,
		uint256 reserve
	) external onlyOwner {
		require(_tokenIds.current() == maxSupply, "Sale Not Finished");
		currentPhase = totalPhases();
		uint256 start = maxSupply + 1;
		maxSupply += supply;
		tickets = 0;
		_tokenIds.increment(reserve);
		phases.push(Phase(name, start, maxSupply, mintFee, reserve, ""));
		emit PhaseAdded(phases[currentPhase]);
	}

	function reserveTokens(uint256 amount) external onlyOwner onlyState(0) {
		if (tickets > 0) {
			tickets = 0;
		}
		require(totalSupply() + amount <= maxSupply, "Max Supply Reached");
		_batch(amount);
	}

	function claimReserves() external onlyOwner {
		uint256 start = phases[currentPhase].start;
		uint256 end = start + phases[currentPhase].reserve;
		_batchFrom(start, end);
	}

	function sendPhaseTokens(uint256 phase, address user, uint256[] memory tokenIds) external onlyOwner {
		bytes32 userHash = getUserHash(user, phase);
		require(userTickets[userHash] >= tokenIds.length, "Tickets Insufficient");
		userTickets[userHash] -= tokenIds.length;
		for (uint8 i = 0; i < tokenIds.length; i++) {
			transferFrom(owner(), user, tokenIds[i]);
		}
	}

	function withdraw() external {
		ITreasuryDAO(treasury).raise{ value: address(this).balance }();
	}
}
