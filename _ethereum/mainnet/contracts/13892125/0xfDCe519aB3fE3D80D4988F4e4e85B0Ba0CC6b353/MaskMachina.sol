// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC20Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";

contract MaskMachina is
	Initializable, ContextUpgradeable,
	OwnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721PausableUpgradeable
{
	function initialize(
		string memory name,
		string memory symbol,
		string memory baseTokenURI,
		address MASKTokenContract
	) public virtual initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__Ownable_init_unchained();
		__ERC721_init_unchained(name, symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721Burnable_init_unchained();
		__Pausable_init_unchained();
		__ERC721Pausable_init_unchained();

		_baseTokenURI = baseTokenURI;
		_MASKTokenContract = ERC20Upgradeable(MASKTokenContract);

		publicMintStartTime = 1640700000;		// 2021-12-28 22:00:00  UTC+8
	}

	ERC20Upgradeable private _MASKTokenContract;

	using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

	struct attributesStruct {
		uint8 EyeMask;
		uint8 Emotion;
		uint8 Hair;
		uint8 Earrings;
		uint8 Outfit;
		uint8 Model;
	}

	mapping(uint256 => attributesStruct) private _avatarAttributes;
	mapping(uint8 => mapping(uint8 => uint16)) private _avatarPartAttributes;
	mapping(uint8 => uint8) private _avatarPartAttributesLength;

	uint8 constant private ATTRS_COUNT = 6;						// Attributes Count.
	uint16 constant private MINT_MAX = 512;
	uint256 constant private PRICE = 15 ether / 100;			// 0.15 ETH
	uint256 constant private MASK_LIMIT = 100 * 1e18;			// 100 MASK Token

	uint256 public publicMintStartTime;

	string private _baseTokenURI;

	uint256 private _publicTokenIdTracker;

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string memory baseTokenURI) external virtual onlyOwner {
		_baseTokenURI = baseTokenURI;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
		string memory extName = ".json";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extName)) : "";
    }

	function pause() public virtual onlyOwner {
		_pause();
	}

	function unpause() public virtual onlyOwner {
		_unpause();
	}

	function fetchSaleFunds() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	function setAvatarAttributesProbsRange(uint8 attr, uint16[] calldata probsRange) external onlyOwner {
		require(attr < ATTRS_COUNT, "Wrong number of attributes");

		_setAttributesProbsRange(attr, probsRange);
	}

	function _setAttributesProbsRange(uint8 attr, uint16[] calldata probsRange) internal {
		require(_avatarPartAttributesLength[attr] == 0, "Attributes already exists");

		require(probsRange.length > 1, "probsRange length needs to be greater than 1");
		require(probsRange[0] > 0, "probsRange first needs to be greater than 0");
		require(probsRange[probsRange.length-1] == 10000, "probsRange needs to be equal to 10000 at the end");

		for (uint8 i = 0; i < probsRange.length; i++){
			if(i > 0){
				require(probsRange[i] > probsRange[i-1], "probsRange must be an orderly increase");
			}

			_avatarPartAttributes[attr][i] = probsRange[i];
		}

		_avatarPartAttributesLength[attr] = uint8(probsRange.length);
	}

	function getAvatarAttributes(uint256 tokenId) external view returns (attributesStruct memory) {
		return _avatarAttributes[tokenId];
	}

	function mint(uint256 amount) external payable {
		require(block.timestamp >= publicMintStartTime, "Public Mint has not started");
		require(msg.value >= PRICE * amount, "Incorrect price");
		require(amount > 0 && amount <= 3, "Can only mint 1 to 3 at a time");
		require(_publicTokenIdTracker + amount <= MINT_MAX, "Exceed max supply");
		require(!_isContract(_msgSender()), "Caller cannot be contract");
		require(_MASKTokenContract.balanceOf(_msgSender()) >= MASK_LIMIT, "You need to hold at least 100 MASK tokens");

		for (uint8 i = 0; i < amount; i++){
			_mint(_msgSender(), _publicTokenIdTracker);
			_avatarAttributes[_publicTokenIdTracker] = _createAvatarAttributes(i);
			_publicTokenIdTracker += 1;
		}
	}

	function _createAvatarAttributes(uint8 index) internal view returns (attributesStruct memory) {
		attributesStruct memory avatarAttributes;

		avatarAttributes.EyeMask = _randomAvatarAttribute(0, index);
		avatarAttributes.Emotion = _randomAvatarAttribute(1, index);
		avatarAttributes.Hair = _randomAvatarAttribute(2, index);
		avatarAttributes.Earrings = _randomAvatarAttribute(3, index);
		avatarAttributes.Outfit = _randomAvatarAttribute(4, index);
		avatarAttributes.Model = _randomAvatarAttribute(5, index);

		return avatarAttributes;
	}

	function _randomAvatarAttribute(uint8 attr, uint8 index) internal view returns (uint8) {
		uint8 attrCount = uint8(_avatarPartAttributesLength[attr]);

		require(attrCount > 0, "Attributes does not exist");

		uint16 rand = _random(10000, (attr * 1000 + index) );
		uint8 attrIndex = _binarySearch(attr, rand);

		return attrIndex;
	}

	function _random(uint16 range, uint16 seed) internal view returns (uint16) {
		uint256 randomHash = uint256(keccak256(abi.encodePacked(_msgSender(), totalSupply(), block.difficulty, block.timestamp, seed)));

		return uint16(randomHash % range);
	}

	function _binarySearch(uint8 attr, uint16 value) internal view returns (uint8) {
		uint8 n = _avatarPartAttributesLength[attr];

		uint8 left = 0;
		uint8 right = n - 1;

		while (left <= right)
		{
			uint8 middle = left + ((right - left) / 2);

			if (_avatarPartAttributes[attr][middle] > value){
				if (middle == 0) { return 0; }

				right = middle - 1;
			}else{
				left = middle + 1;
			}
		}
		
		require(left < n, "BinarySearch: Out of search range");

		return left;
	}

	function _isContract(address account) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
	uint256[50] private __gap;
}
