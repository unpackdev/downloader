// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "./ERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Counters.sol";

import "./ToString.sol";
import "./Base64.sol";

contract Team is Initializable, UUPSUpgradeable, ERC1155Upgradeable, OwnableUpgradeable {
	using Counters for Counters.Counter;
	using ToString for address;
	using Base64 for bytes;

	event EditInfo(string name, string description, uint256 tokenId);
	event AddTeam(uint256 tokenId, address creator, address minter, string name, string description);
	event AddMembers(uint256 tokenId, address[] members);
	event RemoveMembers(uint256 tokenId, address[] members);

	mapping(uint256 => address) public creatorOf;
	mapping(uint256 => address) public minterOf;
	mapping(uint256 => string) public nameOf;
	mapping(uint256 => string) public descriptionOf;

	Counters.Counter private _tokenIds;

	modifier onlyTeamMinter(uint256 id, address minter) {
		require(minterOf[id] == minter, "Team: only selected minter");
		_;
	}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
	__Ownable_init();
    __ERC1155_init("");
  }

	function _beforeTokenTransfer(
			address,
			address from,
			address to,
			uint256[] memory ids,
			uint256[] memory,
			bytes memory
	) internal view override {
		if (from == address(0)) { // mint
			for(uint i = 0; i < ids.length; i++) {
				require(balanceOf(to, ids[i]) == 0, "Team: Member/Members already added");
			}
		}

		if (to == address(0)) { // burn
			for(uint i = 0; i < ids.length; i++) {
				require(balanceOf(from, ids[i]) > 0, "Team: Member/Members not exists");
			}
		}

		if (from != address(0) && to != address(0)) {
			revert("Team: Transfer of team ownership is aboundand");
		} 
	}

	function _mintTokens(address[] memory members, uint256 tokenId) private {
		for(uint i = 0; i < members.length ; i++) {
			_mint(
				members[i],
				tokenId,
				1,
				""
			);
		}
	}

	function _burnTokens(address[] memory members, uint256 tokenId) private {
		for(uint i = 0; i < members.length; i++) {
			_burn(members[i], tokenId, balanceOf(members[i], tokenId));
		}
	}

	function addTeam(string memory name, address minter, address[] memory members, string memory description) external returns (uint256) {

		require(minter != address(0), "minter is null");

		_tokenIds.increment();

		uint256 _tokenId = _tokenIds.current();

		creatorOf[_tokenId] = msg.sender;
		minterOf[_tokenId] = minter;
		nameOf[_tokenId] = name;
		descriptionOf[_tokenId] = description;

		_mintTokens(members, _tokenId);

		emit AddTeam(_tokenId, msg.sender, minter, name, description);

		return _tokenId;
	}

	function addMembers(address[] memory members, uint256 tokenId) external onlyTeamMinter(tokenId, msg.sender) {
		_mintTokens(members, tokenId);
		emit AddMembers(tokenId, members);
	}

	function removeMembers(address[] memory members, uint256 tokenId) external onlyTeamMinter(tokenId, msg.sender) {
		_burnTokens(members, tokenId);
		emit RemoveMembers(tokenId, members);
	}

	function setInfo(string memory name, string memory description, uint256 tokenId) external onlyTeamMinter(tokenId, msg.sender){
    	nameOf[tokenId] = name;
		descriptionOf[tokenId] = description;

		emit EditInfo(name, description, tokenId);
	}
 
 	function uri(uint256 _id) public view override returns (string memory) {
		string memory metadata = string(abi.encodePacked(
			"{\"name\": \"",
			nameOf[_id],
			"\", \"creator\": \"",
			creatorOf[_id].toString(),
			"\", \"minter\": \"",
			minterOf[_id].toString(),
			"\", \"description\": \"",
			descriptionOf[_id], "\"",
			"}"
		));

		return string(abi.encodePacked(
			"data:application/json;base64,",
			bytes(metadata).base64()
		));
	}

	function _authorizeUpgrade(address) internal view override onlyOwner {}

  uint256[50] private __gap;
}
