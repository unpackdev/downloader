// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract LuchaNames is Ownable, Pausable {
	uint256 public nameFee = 0;

	struct Name {
		string name;
	}

	mapping(address => mapping(address => bool)) public addressBlacklist;
	mapping(address => mapping(uint256 => Name)) public names;
	mapping(address => mapping(string => bool)) public nameExists;

	event SetName(
		address indexed _originContract,
		address indexed _sender,
		uint256 id,
		string name
	);

	modifier notBlacklisted(address _originContract) {
		require(!addressBlacklist[_originContract][msg.sender], "Address blacklisted");
		_;
	}

	function processName(address _originContract, uint256 _id, string memory _name) internal notBlacklisted(_originContract) whenNotPaused {
		IERC721 erc721 = IERC721(_originContract);
		address tokenOwner = erc721.ownerOf(_id);

		require(tokenOwner == msg.sender, "Caller must be token owner");
		require(bytes(names[_originContract][_id].name).length == 0, "Name is already set");
		require(bytes(_name).length > 0, "Name must not be empty");
		require(bytes(_name).length <= 32, "Name must contain 32 characters or less");
		require(!nameExists[_originContract][toLowerCase(_name)], "Name already exists");
		require(msg.value >= nameFee, "Not enough ETH to cover name fee");

		nameExists[_originContract][toLowerCase(_name)] = true;
		names[_originContract][_id].name = _name;

		emit SetName(_originContract, msg.sender, _id, _name);
	}

	function set1Name(address _originContract, uint256 _id, string memory _name) public payable {
		require(isSafeName(_name), "Name contains invalid characters");
		processName(_originContract, _id, _name);
	}

	function set2Names(address _originContract, uint256 _id, string memory _name1, string memory _name2) public payable {
		require(isSafeName(_name1) && isSafeName(_name2), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2));
		processName(_originContract, _id, name);
	}

	function set3Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3));
		processName(_originContract, _id, name);
	}

	function set4Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3, string memory _name4) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3) && isSafeName(_name4), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3, ' ', _name4));
		processName(_originContract, _id, name);
	}

	function set5Names(address _originContract, uint256 _id, string memory _name1, string memory _name2, string memory _name3, string memory _name4, string memory _name5) public payable {
		require(isSafeName(_name1) && isSafeName(_name2) && isSafeName(_name3) && isSafeName(_name4) && isSafeName(_name5), "setName: Name contains invalid characters");
		string memory name = string(abi.encodePacked(_name1, ' ', _name2, ' ', _name3, ' ', _name4, ' ', _name5));
		processName(_originContract, _id, name);
	}

	function toLowerCase(string memory _name) internal pure returns (string memory) {
		bytes memory bytesName = bytes(_name);
		bytes memory lowerCase = new bytes(bytesName.length);

		for (uint i = 0; i < bytesName.length; i++) {
				if ((uint8(bytesName[i]) >= 65) && (uint8(bytesName[i]) <= 90)) {
					lowerCase[i] = bytes1(uint8(bytesName[i]) + 32);
				} else {
					lowerCase[i] = bytesName[i];
				}
		}
		return string(abi.encodePacked(lowerCase));
	}

	function isSafeName(string memory _name) public pure returns (bool) {
		bytes memory b = bytes(_name);

		for (uint i; i < b.length; i++) {
			bytes1 char = b[i];

			if (!(char >= 0x41 && char <= 0x5A) && // A-Z
					!(char >= 0x61 && char <= 0x7A)		 // a-z
			) { 
				return false; 
			}
		}
		return true;
	}

	function getName(address _originContract, uint256 _id) public view returns (string memory) {
		return names[_originContract][_id].name;
	}

	function blacklistName(address _originContract, uint256 _id) public onlyOwner {
		names[_originContract][_id].name = '';
	}

	function blacklistAddress (address _originContract, address _address, bool _bool) public onlyOwner {
		addressBlacklist[_originContract][_address] = _bool;
	}

	function setNameFee(uint256 _nameFee) public onlyOwner {
		nameFee = _nameFee;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function withdraw() public onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}('');
		require(success, "Withdrawal failed");
	}

	receive() external payable {}
}
