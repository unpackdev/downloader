// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";

contract DigiAvatar is
	Initializable, ContextUpgradeable,
	OwnableUpgradeable,
	ERC721EnumerableUpgradeable,
	ERC721BurnableUpgradeable,
	ERC721PausableUpgradeable
{
	function initialize(
		string memory name,
		string memory symbol,
		string memory baseTokenURI
	) public virtual initializer {
		__Context_init_unchained();
		__ERC165_init_unchained();
		__Ownable_init_unchained();
		__ERC721_init_unchained(name, symbol);
		__ERC721Enumerable_init_unchained();
		__ERC721Burnable_init_unchained();
		__Pausable_init_unchained();
		__ERC721Pausable_init_unchained();

		_publicTokenIdTracker = 74;
		_ambassadorTokenIdTracker = 0;
		_baseTokenURI = baseTokenURI;

		publicMintStartTime = 1637330400;		// 2021-11-19 22:00:00  UTC+8
	}

	using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

	struct attributesStruct {
		uint8 Origin;
		uint8 Gender;
		uint8 Race;
		uint8 Hair;
		uint8 Accessory;
		uint8 Face_Extra;
		uint8 Body_Extra;
		uint8 Back_Extra;
	}

	mapping(uint256 => attributesStruct) private _avatarAttributes;
	mapping(uint8 => mapping(uint8 => mapping(uint8 => uint16))) private _avatarPartAttributes;
	mapping(uint8 => mapping(uint8 => uint8)) private _avatarPartAttributesLength;

	uint8 constant private ORIGIN = 1;						// Ethereum
	uint8 constant private ATTRS_COUNT = 6;					// Attributes Count.
	uint16 constant private MINT_MAX = 1024;
	uint256 constant private PRICE = 8 ether / 100;			// 0.08 ETH

	uint256 public publicMintStartTime;
	uint256 public ambassadorMintStartTime;
	uint256 private constant prePublicMintDuration = 1 days;
	uint256 private constant publicMintDuration = 7 days;
	uint256 private constant ambassadorMintDuration = 14 days;

	string private _baseTokenURI;

	uint256 private _publicTokenIdTracker;
	uint8 private _ambassadorTokenIdTracker;

	bytes32 private _whiteListMerkleRoot;
	bytes32 private _ambassadorMerkleRoot;

	mapping(address => uint8) private _whiteListMintAmount;
	mapping(address => uint8) private _ambassadorMintAmount;

	event WhiteListMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);
	event AmbassadorMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);
	event WhiteListMintedAmount(address indexed account, uint8 indexed amount);
	event AmbassadorMintedAmount(address indexed account, uint8 indexed amount);

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

	function setWhiteListMerkleRoot(bytes32 root) external onlyOwner {
        bytes32 oldRoot = _whiteListMerkleRoot;
		_whiteListMerkleRoot = root;
		emit WhiteListMerkleRootChanged(oldRoot, root);
	}

	function setAmbassadorMerkleRoot(bytes32 root) external onlyOwner {
        bytes32 oldRoot = _ambassadorMerkleRoot;
		_ambassadorMerkleRoot = root;
		emit AmbassadorMerkleRootChanged(oldRoot, root);
	}

	function getWhiteListMintAmount() external view returns (uint8) {
		return _whiteListMintAmount[_msgSender()];
	}

	function getAmbassadorMintAmount() external view returns (uint8) {
		return _ambassadorMintAmount[_msgSender()];
	}

	function fetchSaleFunds() external onlyOwner {
		payable(_msgSender()).transfer(address(this).balance);
	}

	function setAvatarAttributesProbsRange(uint8 attr, uint16[] calldata femaleProbsRange, uint16[] calldata maleProbsRange) external onlyOwner {
		require(attr < ATTRS_COUNT, "Wrong number of attributes");

		_setAttributesProbsRange(attr, 0, femaleProbsRange);
		_setAttributesProbsRange(attr, 1, maleProbsRange);
	}

	function _setAttributesProbsRange(uint8 attr, uint8 gender, uint16[] calldata probsRange) internal {
		require(_avatarPartAttributesLength[attr][gender] == 0, "Attributes already exists");

		require(probsRange.length > 1, "probsRange length needs to be greater than 1");
		require(probsRange[0] > 0, "probsRange first needs to be greater than 0");
		require(probsRange[probsRange.length-1] == 10000, "probsRange needs to be equal to 10000 at the end");

		for (uint8 i = 0; i < probsRange.length; i++){
			if(i > 0){
				require(probsRange[i] > probsRange[i-1], "probsRange must be an orderly increase");
			}

			_avatarPartAttributes[attr][gender][i] = probsRange[i];
		}

		_avatarPartAttributesLength[attr][gender] = uint8(probsRange.length);
	}

	function getAvatarAttributes(uint256 tokenId) external view returns (attributesStruct memory) {
		return _avatarAttributes[tokenId];
	}

	modifier checkMsgValue(uint256 amount) {
		require(msg.value >= PRICE * amount, "Incorrect price");
		_;
	}

	function mintByAmbassador(uint8 gender, bytes32[] memory proof)
		external
		checkMsgValue(1)
		payable
	{
		if (block.timestamp >= publicMintStartTime.add(publicMintDuration) && ambassadorMintStartTime == 0){
			ambassadorMintStartTime = publicMintStartTime.add(publicMintDuration);
		}

		require(gender == 0 || gender == 1, "Gender is 0 or 1");
		require(ambassadorMintStartTime > 0, "Ambassador Mint has not started");
		require(block.timestamp < ambassadorMintStartTime.add(ambassadorMintDuration), "Ambassador Mint is over");
		require(msg.value >= PRICE, "Incorrect price");
		require(_ambassadorTokenIdTracker < 74, "Exceed max supply");
		require(_ambassadorMintAmount[_msgSender()] == 0, "Each ambassador address holds up to 1");
		require(!_isContract(_msgSender()), "Caller cannot be contract");

		bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
		require(MerkleProofUpgradeable.verify(proof, _ambassadorMerkleRoot, leaf), "MerkleProof verify faild");

		_mint(_msgSender(), _ambassadorTokenIdTracker);
		_avatarAttributes[_ambassadorTokenIdTracker] = _createAvatarAttributes(gender, 0);
		_ambassadorTokenIdTracker += 1;

		_ambassadorMintAmount[_msgSender()] = 1;

		emit AmbassadorMintedAmount(_msgSender(), _ambassadorMintAmount[_msgSender()]);
	}

	function mintByWhitelist(uint8[] calldata genders, bytes32[] memory proof)
		external
		checkMsgValue(genders.length)
		payable
	{
		require(block.timestamp >= publicMintStartTime.sub(prePublicMintDuration), "Pre-Public Mint has not started");
		require(block.timestamp < publicMintStartTime, "Pre-Public Mint is over");
		require(_whiteListMintAmount[_msgSender()] + genders.length <= 5, "Each whitelist address holds up to 5");

		bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
		require(MerkleProofUpgradeable.verify(proof, _whiteListMerkleRoot, leaf), "MerkleProof verify faild");

		_mintAvatar(genders);

		_whiteListMintAmount[_msgSender()] += uint8(genders.length);

		emit WhiteListMintedAmount(_msgSender(), _whiteListMintAmount[_msgSender()]);
	}

	function mint(uint8[] calldata genders)
		external
		checkMsgValue(genders.length)
		payable
	{
		require(block.timestamp >= publicMintStartTime, "Public Mint has not started");
		require(block.timestamp < publicMintStartTime.add(publicMintDuration), "Public Mint is over");

		_mintAvatar(genders);

		if (_publicTokenIdTracker == MINT_MAX){
			ambassadorMintStartTime = block.timestamp;
		}
	}

	function _mintAvatar(uint8[] calldata genders) internal {
		require(_publicTokenIdTracker + genders.length <= MINT_MAX, "Exceed max supply");
		require(genders.length > 0 && genders.length <= 5, "Can only mint 1 to 5 avatar at a time");
		require(!_isContract(_msgSender()), "Caller cannot be contract");

		for (uint8 i = 0; i < genders.length; i++){
			require(genders[i] == 0 || genders[i] == 1, "Gender is 0 or 1");

			_mint(_msgSender(), _publicTokenIdTracker);
			_avatarAttributes[_publicTokenIdTracker] = _createAvatarAttributes(genders[i], i);
			_publicTokenIdTracker += 1;
		}
	}

	function _createAvatarAttributes(uint8 gender, uint8 index) internal view returns (attributesStruct memory) {
		attributesStruct memory avatarAttributes;

		avatarAttributes.Origin = ORIGIN;
		avatarAttributes.Gender = gender;
		avatarAttributes.Race = _randomAvatarAttribute(0, gender, index);
		avatarAttributes.Hair = _randomAvatarAttribute(1, gender, index);
		avatarAttributes.Accessory = _randomAvatarAttribute(2, gender, index);
		avatarAttributes.Face_Extra = _randomAvatarAttribute(3, gender, index);
		avatarAttributes.Body_Extra = _randomAvatarAttribute(4, gender, index);
		avatarAttributes.Back_Extra = _randomAvatarAttribute(5, gender, index);

		return avatarAttributes;
	}

	function _randomAvatarAttribute(uint8 attr, uint8 gender, uint8 index) internal view returns (uint8) {
		uint8 attrCount = uint8(_avatarPartAttributesLength[attr][gender]);

		require(attrCount > 0, "Attributes does not exist");

		uint16 rand = _random(10000, (attr * 1000 + gender * 100 + index) );
		uint8 attrIndex = _binarySearch(attr, gender, rand);

		return attrIndex;
	}

	function _random(uint16 range, uint16 seed) internal view returns (uint16) {
		uint256 randomHash = uint256(keccak256(abi.encodePacked(_msgSender(), block.difficulty, block.timestamp, seed)));

		return uint16(randomHash % range);
	}

	function _binarySearch(uint8 attr, uint8 gender, uint16 value) internal view returns (uint8) {
		uint8 n = _avatarPartAttributesLength[attr][gender];

		uint8 left = 0;
		uint8 right = n - 1;

		while (left <= right)
		{
			uint8 middle = left + ((right - left) / 2);

			if (_avatarPartAttributes[attr][gender][middle] > value){
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
