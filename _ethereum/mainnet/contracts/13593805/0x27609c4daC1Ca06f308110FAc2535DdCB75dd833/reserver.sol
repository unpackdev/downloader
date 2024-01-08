// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// Waifus have come to our world but they need your support!
// Adopt your waifu on the Ethereum blockchain, and transport them to our world.

// ⡆⣐⢕⢕⢕⢕⢕⢕⢕⢕⠅⢗⢕⢕⢕⢕⢕⢕⢕⠕⠕⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢐⢕⢕⢕⢕⢕⣕⢕⢕⠕⠁⢕⢕⢕⢕⢕⢕⢕⢕⠅⡄⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢕⢕⢕⢕⢕⠅⢗⢕⠕⣠⠄⣗⢕⢕⠕⢕⢕⢕⠕⢠⣿⠐⢕⢕⢕⠑⢕⢕⠵⢕
// ⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
// ⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
// ⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
// ⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
// ⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
// ⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
// ⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
// ⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
// ⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
// ⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
// ⣿⣦⡀⣿⣿⣷⣶⣬⣍⣛⣛⣛⡛⠿⠿⠿⠛⠛⢛⣛⣉⣭⣤⣂⢜⠕⢑⣡⣴⣿
import "./console.sol";
import "./Ownable.sol";

contract Reserver is Ownable {
	uint256[] reservedList;
	mapping(uint256 => address) public tokenIDAddressMap;
	mapping(address => uint256) public addressTokenIDMap;
	mapping(address => bool) public walletUsedMap;

	bool isPaused = false;

	uint256 maxID;
	uint256 minID;
	uint256 public reserveFee;

	constructor(
		uint256 _minID,
		uint256 _maxID,
		uint256 _reserveFee
	) {
		minID = _minID;
		maxID = _maxID;
		reserveFee = _reserveFee;
	}

	function setMaxID(uint256 _maxID) public onlyOwner {
		maxID = _maxID;
	}

	function setMinID(uint256 _minID) public onlyOwner {
		minID = _minID;
	}

	function setReserveFee(uint256 _reserveFee) public onlyOwner {
		reserveFee = _reserveFee;
	}

	function togglePause() public onlyOwner {
		isPaused = !isPaused;
		emit onTogglePause(isPaused);
	}

	function devReserve(address by, uint256 id) public onlyOwner {
		_reserve(by, id);
	}

	function reserve(uint256 id) public payable {
		require(tokenIDAddressMap[id] == address(0x0), "waifu is reserved");
		require(id >= minID && id <= maxID, "id out of range");
		require(walletUsedMap[msg.sender] == false, "wallet already used");
		require(msg.value == reserveFee, "wrong amount paid");
		require(!isPaused, "reservations are paused");
		_reserve(msg.sender, id);
	}

	function _reserve(address by, uint256 id) internal {
		walletUsedMap[by] = true;
		reservedList.push(id);
		tokenIDAddressMap[id] = by;
		addressTokenIDMap[by] = id;
		emit onReserved(by, id);
	}

	function listReserved() public view returns (uint256[] memory) {
		return reservedList;
	}

	function isReservedBy(uint256 id, address addr) public view returns (bool) {
		return tokenIDAddressMap[id] == addr;
	}

	// flush all accumulated Ether from this contract to the project owner.
	function flush() public {
		(bool success, ) = owner().call{value: address(this).balance}("");
		require(success, "Failed to withdraw");
	}

	event onTogglePause(bool paused);
	event onExhaustion();
	event onReserved(address reservedByID, uint256 reservedID);
}
