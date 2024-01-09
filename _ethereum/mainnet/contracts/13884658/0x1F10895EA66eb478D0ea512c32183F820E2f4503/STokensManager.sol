// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./ISTokensManager.sol";
import "./ISTokenManagerStruct.sol";
import "./ISTokenManagerDescriptor.sol";
import "./IAddressConfig.sol";
import "./ILockup.sol";
import "./IProperty.sol";

contract STokensManager is
	ISTokenManagerStruct,
	ISTokensManager,
	ERC721Upgradeable
{
	Counters.Counter private tokenIdCounter;
	address public config;
	mapping(bytes32 => bytes) private bytesStorage;
	mapping(address => uint256[]) private tokenIdsMap;
	mapping(address => EnumerableSet.UintSet) private tokenIdsMapOfOwner;
	mapping(uint256 => string) private tokenUriImage;
	mapping(uint256 => bool) public override isFreezed;
	address public descriptor;

	using Counters for Counters.Counter;
	using EnumerableSet for EnumerableSet.UintSet;

	modifier onlyAuthor(uint256 _tokenId) {
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		address author = IProperty(currentPosition.property).author();
		require(author == _msgSender(), "illegal access");
		_;
	}

	modifier onlyLockup() {
		require(
			IAddressConfig(config).lockup() == _msgSender(),
			"illegal access"
		);
		_;
	}

	function initialize(address _config) external initializer {
		__ERC721_init("Dev Protocol sTokens V1", "DEV-STOKENS-V1");
		config = _config;
	}

	function setDescriptor(address _descriptor) external {
		require(descriptor == address(0), "already set");
		descriptor = _descriptor;
	}

	function tokenURI(uint256 _tokenId)
		public
		view
		override
		returns (string memory)
	{
		string memory _tokeUriImage = tokenUriImage[_tokenId];
		StakingPositionV1 memory positons = getStoragePositionsV1(_tokenId);
		return
			ISTokenManagerDescriptor(descriptor).getTokenURI(
				positons.property,
				positons.amount,
				positons.cumulativeReward,
				_tokeUriImage
			);
	}

	function mint(
		address _owner,
		address _property,
		uint256 _amount,
		uint256 _price
	) external override onlyLockup returns (uint256 tokenId_) {
		tokenIdCounter.increment();
		_safeMint(_owner, tokenIdCounter.current());
		emit Minted(
			tokenIdCounter.current(),
			_owner,
			_property,
			_amount,
			_price
		);
		StakingPositionV1 memory newPosition = StakingPositionV1(
			_property,
			_amount,
			_price,
			0,
			0
		);
		setStoragePositionsV1(tokenIdCounter.current(), newPosition);
		tokenIdsMap[_property].push(tokenIdCounter.current());
		return tokenIdCounter.current();
	}

	function update(
		uint256 _tokenId,
		uint256 _amount,
		uint256 _price,
		uint256 _cumulativeReward,
		uint256 _pendingReward
	) external override onlyLockup returns (bool) {
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		currentPosition.amount = _amount;
		currentPosition.price = _price;
		currentPosition.cumulativeReward = _cumulativeReward;
		currentPosition.pendingReward = _pendingReward;
		setStoragePositionsV1(_tokenId, currentPosition);
		emit Updated(
			_tokenId,
			_amount,
			_price,
			_cumulativeReward,
			_pendingReward
		);
		return true;
	}

	function setTokenURIImage(uint256 _tokenId, string memory _data)
		external
		override
		onlyAuthor(_tokenId)
	{
		require(isFreezed[_tokenId] == false, "freezed");
		tokenUriImage[_tokenId] = _data;
	}

	function freezeTokenURI(uint256 _tokenId)
		external
		override
		onlyAuthor(_tokenId)
	{
		require(isFreezed[_tokenId] == false, "already freezed");
		string memory tokeUri = tokenUriImage[_tokenId];
		require(bytes(tokeUri).length != 0, "no data");
		isFreezed[_tokenId] = true;
		emit Freezed(_tokenId, _msgSender());
	}

	function positions(uint256 _tokenId)
		external
		view
		override
		returns (
			address property_,
			uint256 amount_,
			uint256 price_,
			uint256 cumulativeReward_,
			uint256 pendingReward_
		)
	{
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		return (
			currentPosition.property,
			currentPosition.amount,
			currentPosition.price,
			currentPosition.cumulativeReward,
			currentPosition.pendingReward
		);
	}

	function rewards(uint256 _tokenId)
		external
		view
		override
		returns (
			uint256 entireReward_,
			uint256 cumulativeReward_,
			uint256 withdrawableReward_
		)
	{
		address lockupAddress = IAddressConfig(config).lockup();
		uint256 withdrawableReward = ILockup(lockupAddress)
			.calculateWithdrawableInterestAmountByPosition(_tokenId);
		StakingPositionV1 memory currentPosition = getStoragePositionsV1(
			_tokenId
		);
		uint256 cumulativeReward = currentPosition.cumulativeReward;
		uint256 entireReward = cumulativeReward + withdrawableReward;

		return (entireReward, cumulativeReward, withdrawableReward);
	}

	function positionsOfProperty(address _property)
		external
		view
		override
		returns (uint256[] memory)
	{
		return tokenIdsMap[_property];
	}

	function positionsOfOwner(address _owner)
		external
		view
		override
		returns (uint256[] memory)
	{
		return tokenIdsMapOfOwner[_owner].values();
	}

	function getStoragePositionsV1(uint256 _tokenId)
		private
		view
		returns (StakingPositionV1 memory)
	{
		bytes32 key = getStoragePositionsV1Key(_tokenId);
		bytes memory tmp = bytesStorage[key];
		return abi.decode(tmp, (StakingPositionV1));
	}

	function setStoragePositionsV1(
		uint256 _tokenId,
		StakingPositionV1 memory _position
	) private {
		bytes32 key = getStoragePositionsV1Key(_tokenId);
		bytes memory tmp = abi.encode(_position);
		bytesStorage[key] = tmp;
	}

	function getStoragePositionsV1Key(uint256 _tokenId)
		private
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("_positionsV1", _tokenId));
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) {
			// mint
			tokenIdsMapOfOwner[to].add(tokenId);
		} else if (to == address(0)) {
			// burn
			revert("s tokens is not burned");
		} else if (to != from) {
			tokenIdsMapOfOwner[from].remove(tokenId);
			tokenIdsMapOfOwner[to].add(tokenId);
		}
	}
}
