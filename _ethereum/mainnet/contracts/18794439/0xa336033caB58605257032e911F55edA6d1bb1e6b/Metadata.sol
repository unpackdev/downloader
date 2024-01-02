// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

contract Metadata {

	string public name = "Descendants of Smurfcat";
	string public symbol = "DoS";

	string public baseURI = "https://arweave.net/-mckyPjOnwlkTN19bGRRkqhl6Y-OqLDy3mBjv9ssV_c/";

	address public owner;

	constructor() {
		owner = tx.origin;
	}

	function setBaseURI(string memory _baseURI) external {
		require(msg.sender == owner);
		baseURI = _baseURI;
	}


	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return string(abi.encodePacked(baseURI, _uint2str(_tokenId), ".json"));
	}

	function _uint2str(uint256 _value) internal pure returns (string memory) {
		uint256 _digits = 1;
		uint256 _n = _value;
		while (_n > 9) {
			_n /= 10;
			_digits++;
		}
		bytes memory _out = new bytes(_digits);
		for (uint256 i = 0; i < _out.length; i++) {
			uint256 _dec = (_value / (10**(_out.length - i - 1))) % 10;
			_out[i] = bytes1(uint8(_dec) + 48);
		}
		return string(_out);
	}
}

contract smurfcatNFT {

	uint256 constant public MAX_SUPPLY = 3333;
	uint256 constant public MINT_COST = 0.01 ether;

	uint256 constant private PAID_SUPPLY = 300;
	uint256 constant private DEV_TOKENS = 33;
	uint256 constant private OPEN_MINT_DELAY = 12 hours;
	bytes32 constant private FREE_MERKLE_ROOT = 0x97065a5c49b1664430261a060b4d4e90253022606b49142c350dc95a2cf86958;
	bytes32 constant private PAID_MERKLE_ROOT = 0x943cd45d71c324d5ade31d70c06a95a2c6d32447b01934157edd060721453f4c;

	struct User {
		bool freeMinted;
		bool paidMinted;
		uint240 balance;
		mapping(address => bool) approved;
	}

	struct Token {
		address owner;
		address approved;
	}

	struct Info {
		uint128 totalSupply;
		uint128 paidSupply;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		Metadata metadata;
		address owner;
		uint256 startTime;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	event Mint(address indexed owner, uint256 indexed tokenId);
	event FreeClaim(address indexed account, uint256 tokens);
	event PaidClaim(address indexed account);
	event BatchMetadataUpdate(uint256 from, uint256 to);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.metadata = new Metadata();
		info.owner = msg.sender;
		info.startTime = block.timestamp;
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata

		for (uint256 i = 0; i < DEV_TOKENS; i++) {
			_mint(owner());
		}
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}

	function ownerWithdraw() external _onlyOwner {
		uint256 _balance = address(this).balance;
		require(_balance > 0);
		payable(msg.sender).transfer(_balance);
	}

	function forceUpdateAllMetadata() external _onlyOwner {
		emit BatchMetadataUpdate(0, type(uint256).max);
	}

	
	receive() external payable {
		mintMany(msg.value / MINT_COST);
	}
	
	function mint() external payable {
		mintMany(1);
	}

	function mintMany(uint256 _tokens) public payable {
		require(openMintEnabled());
		require(_tokens > 0);
		uint256 _cost = _tokens * MINT_COST;
		require(msg.value >= _cost);
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(msg.sender);
		}
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}
	
	function mint(address _account, bytes32[] calldata _proof) external payable {
		require(msg.value == MINT_COST);
		require(!hasPaidMinted(_account));
		require(_verify(_proof, keccak256(abi.encodePacked(_account)), PAID_MERKLE_ROOT));
		info.paidSupply++;
		require(paidSupply() <= PAID_SUPPLY);
		info.users[_account].paidMinted = true;
		_mint(_account);
		emit PaidClaim(_account);
	}

	function claim(address _account, uint256 _tokens, bytes32[] calldata _proof) external {
		require(!hasFreeMinted(_account));
		require(_verify(_proof, keccak256(abi.encodePacked(_account, _tokens)), FREE_MERKLE_ROOT));
		info.users[_account].freeMinted = true;
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(_account);
		}
		emit FreeClaim(_account, _tokens);
	}
	
	function approve(address _approved, uint256 _tokenId) external {
		require(msg.sender == ownerOf(_tokenId));
		info.list[_tokenId].approved = _approved;
		emit Approval(msg.sender, _approved, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		info.users[msg.sender].approved[_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) external {
		_transfer(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
		_transfer(_from, _to, _tokenId);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == 0x150b7a02);
		}
	}


	function metadata() external view returns (address) {
		return address(info.metadata);
	}
	
	function name() external view returns (string memory) {
		return info.metadata.name();
	}

	function symbol() external view returns (string memory) {
		return info.metadata.symbol();
	}

	function baseURI() external view returns (string memory) {
		return info.metadata.baseURI();
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function openMintEnabled() public view returns (bool) {
		return block.timestamp > info.startTime + OPEN_MINT_DELAY;
	}
	
	function paidSupply() public view returns (uint256) {
		return info.paidSupply;
	}

	function hasFreeMinted(address _user) public view returns (bool) {
		return info.users[_user].freeMinted;
	}

	function hasPaidMinted(address _user) public view returns (bool) {
		return info.users[_user].paidMinted;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].balance;
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].owner;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].approved;
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}


	function _mint(address _receiver) internal {
		require(totalSupply() < MAX_SUPPLY);
		uint256 _tokenId = info.totalSupply++;
		Token storage _newToken = info.list[_tokenId];
		_newToken.owner = _receiver;
		info.users[_receiver].balance++;
		emit Transfer(address(0x0), _receiver, _tokenId);
		emit Mint(_receiver, _tokenId);
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		address _owner = ownerOf(_tokenId);
		address _approved = getApproved(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(address(0x0), address(0x0), _tokenId);
		}
		info.users[_from].balance--;
		info.users[_to].balance++;
		emit Transfer(_from, _to, _tokenId);
	}


	function _verify(bytes32[] memory _proof, bytes32 _leaf, bytes32 _merkleRoot) internal pure returns (bool) {
		bytes32 _computedHash = _leaf;
		for (uint256 i = 0; i < _proof.length; i++) {
			bytes32 _proofElement = _proof[i];
			if (_computedHash <= _proofElement) {
				_computedHash = keccak256(abi.encodePacked(_computedHash, _proofElement));
			} else {
				_computedHash = keccak256(abi.encodePacked(_proofElement, _computedHash));
			}
		}
		return _computedHash == _merkleRoot;
	}
}