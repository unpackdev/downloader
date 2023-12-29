// SPDX-License-Identifier: CC-BY-4.0
/*

• ▌ ▄ ·.  ▄▄▄· ▄▄▄▄· ▄▄▌   ▄▄▄· ▄▄▄▄·
·██ ▐███▪▐█ ▀█ ▐█ ▀█▪██•  ▐█ ▀█ ▐█ ▀█▪
▐█ ▌▐▌▐█·▄█▀▀█ ▐█▀▀█▄██▪  ▄█▀▀█ ▐█▀▀█▄
██ ██▌▐█▌▐█ ▪▐▌██▄▪▐█▐█▌▐▌▐█ ▪▐▌██▄▪▐█
▀▀  █▪▀▀▀ ▀  ▀ ·▀▀▀▀ .▀▀▀  ▀  ▀ ·▀▀▀▀

MABLAB. Piranesi. Fields of Chain.

v1.0 - December 2023

written by Ariel Sebastián Becker

NOTICE
======

This is a custom contract, tailored and pruned to fit Spurious Dragon's limit of 24,576 bytes.
Because of that, you will see some modifications made to third-party libraries such as OpenZeppelin's.

THIS SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

THE AUTHOR WILL NOT BE LIABLE, UNDER ANY CIRCUMSTANCE, FOR THE CONTENT STORED BY THE OWNERS.

*/

pragma solidity ^0.8.22;
string constant _strVersion = 'v1.0';
string constant _strTokenTicker = 'MABLAB';
string constant _strTokenName = string(abi.encodePacked('MABLAB. Piranesi. Fields of Chain. ', _strVersion));
string constant _strReverted = 'Unable to send value; recipient may have reverted!';
string constant _strLowCallFailed = 'Low-level call failed.';
string constant _strNonContract = 'Call to non-contract.';
string constant _strDelegateCallFailed = 'Low-level delegate call failed.';
string constant _strDelegateCallNonContract = 'Low-level delegate call to non-contract.';
string constant _strBalanceZeroAddy = 'Balance query for the zero address.';
string constant _strTransferZeroAddy = 'Cannot transfer to the zero address!';
string constant _strNotAuthorized = 'Not authorized!';
string constant _strInvalidMultiproof = 'Invalid multiproof.';
string constant _strTransferFailed = 'Transfer failed.';
string constant _strBlacklisted = "Blacklisted address.";
string constant _strNotBlacklisted = "Not a blacklisted address.";
string constant _strOutOfBounds = 'Out of bounds!';
string constant _strAlreadyMinted = 'Already minted!';
string constant _strPaused = 'Contract is paused.';
string constant _strNotEnoughBalance = 'Insufficient balance!';
string constant _strTransferToNon721 = 'Attempted transfer to non ERC721Receiver implementer!';
string constant _strInvalidParams = 'Invalid params!';

pragma solidity ^0.8.22;
interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

pragma solidity ^0.8.22;
interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);
	function ownerOf(uint256 tokenId) external view returns(address owner);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function transferFrom(address from, address to, uint256 tokenId) external;
	function approve(address to, uint256 tokenId) external;
	function getApproved(uint256 tokenId) external view returns(address operator);
	function setApprovalForAll(address operator, bool _approved) external;
	function isApprovedForAll(address owner, address operator) external view returns(bool);
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.22;
interface BlackListable {
	function blacklist(address addy) external;
	function unblacklist(address addy) external;
	function isBlacklisted(address addy) external view returns(string memory message);
}

pragma solidity ^0.8.22;
interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

pragma solidity ^0.8.22;
library Address {

	function isContract(address account) internal view returns(bool) {
		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, _strNotEnoughBalance);
		(bool success, ) = recipient.call{value: amount}('');
		require(success, _strReverted);
	}

	function functionCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionCall(target, data, _strLowCallFailed);
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns(bytes memory) {
		return functionCallWithValue(target, data, value, _strLowCallFailed);
	}

	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns(bytes memory) {
		require(address(this).balance >= value, _strNotEnoughBalance);
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.call{value: value}(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns(bytes memory) {
		return functionStaticCall(target, data, _strLowCallFailed);
	}

	function functionStaticCall( address target, bytes memory data, string memory errorMessage) internal view returns(bytes memory) {
		require(isContract(target), _strNonContract);
		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns(bytes memory) {
		return functionDelegateCall(target, data, _strDelegateCallFailed);
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns(bytes memory) {
		require(isContract(target), _strDelegateCallNonContract);
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns(bytes memory) {
		if(success) {
			return returndata;
		}
		else {
			if(returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			}
			else {
				revert(errorMessage);
			}
		}
	}
}

pragma solidity ^0.8.22;
abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

pragma solidity ^0.8.22;
library Strings {
	bytes16 private constant _SYMBOLS = '0123456789abcdef';
	uint8 private constant _ADDRESS_LENGTH = 20;

	function toString(uint256 value) internal pure returns(string memory) {
		if(value == 0) {
			return '0';
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}

	function toHexString(uint256 value, uint256 length) internal pure returns(string memory) {
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for(uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _SYMBOLS[value & 0xf];
			value >>= 4;
		}

		return string(buffer);
	}

	function toHexString(address addr) internal pure returns(string memory) {
		return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
	}

	function stringLength(string memory s) internal pure returns(uint256) {
		return bytes(s).length;
	}
}

pragma solidity ^0.8.22;
abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

pragma solidity ^0.8.22;
contract ERC721 is Context, ERC165, IERC721, BlackListable {
	using Address for address;
	using Strings for uint256;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;
	mapping(address => bool) private _blackListedAddresses;

	modifier checkBlacklistOperator(address addy) {
		require(!_blackListedAddresses[addy], _strBlacklisted);
		_;
	}

	modifier checkBlacklistTransfer(address from, address to) {
		require(!_blackListedAddresses[from] && !_blackListedAddresses[to], _strBlacklisted);
		_;
	}

	/// @notice Blacklists an address, preventing it from transfer
	/// @param addy Address to blacklist.
	function blacklist(address addy) public {
		if(!_blackListedAddresses[addy]) {
			_blackListedAddresses[addy] = true;
		}
	}

	/// @notice Unblacklists an address, allowing it to transfer again.
	/// @param addy Address to unblacklist.
	function unblacklist(address addy) public {
		if(_blackListedAddresses[addy]) {
			_blackListedAddresses[addy] = false;
		}
	}

	/// @notice Returns whether or not an address is blacklisted.
	/// @param addy Address to check.
	function isBlacklisted(address addy) public view returns(string memory) {
		if(_blackListedAddresses[addy]) {
			return _strBlacklisted;
		}
		else {
			return _strNotBlacklisted;
		}
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return
		interfaceId == type(IERC721).interfaceId ||
		super.supportsInterface(interfaceId);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), _strBalanceZeroAddy);
		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];
		require(owner != address(0), _strOutOfBounds);
		return owner;
	}

	function approve(address to, uint256 tokenId) public checkBlacklistOperator(to) virtual override {
		address owner = ERC721.ownerOf(tokenId);
		require(to != owner, _strNotAuthorized);
		require(
			_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
				_strNotAuthorized
		);
		_approve(to, tokenId);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), _strOutOfBounds);
		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public checkBlacklistOperator(operator) virtual override {
		require(operator != _msgSender(), _strNotAuthorized);
		_operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenId) public checkBlacklistTransfer(from, to) virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public checkBlacklistTransfer(from, to) virtual override {
		safeTransferFrom(from, to, tokenId, '');
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public checkBlacklistTransfer(from, to) virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenId), _strNotAuthorized);
		_safeTransfer(from, to, tokenId, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal checkBlacklistTransfer(from, to) virtual {
		_transfer(from, to, tokenId);
		require(_checkOnERC721Received(from, to, tokenId, _data), _strTransferToNon721);
	}

	function _exists(uint256 tokenId) internal view virtual returns(bool) {
		return _owners[tokenId] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
		require(_exists(tokenId), _strOutOfBounds);
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, '');
	}

	function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
		_mint(to, tokenId);
		require(
			_checkOnERC721Received(address(0), to, tokenId, _data),
				_strTransferToNon721
		);
	}

	function _mint(address to, uint256 tokenId) internal virtual {
		require(!_exists(tokenId), _strOutOfBounds);
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}

	function _transfer(address from, address to, uint256 tokenId) internal checkBlacklistTransfer(from, to) virtual {
		require(ERC721.ownerOf(tokenId) == from, _strNotAuthorized);
		require(to != address(0), _strTransferZeroAddy);
		require(_exists(tokenId), _strOutOfBounds);
		_approve(address(0), tokenId);
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(from, to, tokenId);
	}

	function _approve(address to, uint256 tokenId) internal checkBlacklistOperator(to) virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns(bool) {
		if(to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if(reason.length == 0) {
					revert(_strTransferToNon721);
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		else {
			return true;
		}
	}
}

pragma solidity ^0.8.22;
interface IERC4906 is IERC165, IERC721 {
	/// @notice This event emits when the metadata of a token is changed.
	/// So that the third-party platforms such as NFT market could
	/// timely update the images and related attributes of the NFT.
	event MetadataUpdate(uint256 _tokenId);

	/// @notice This event emits when the metadata of a range of tokens is changed.
	/// So that the third-party platforms such as NFT market could
	/// timely update the images and related attributes of the NFTs.
	event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

pragma solidity ^0.8.22;
contract Ownable {
	string public constant NOT_CURRENT_OWNER = '018001';
	string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = '018002';
	address public owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, NOT_CURRENT_OWNER);
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
		emit OwnershipTransferred(owner, _newOwner);
		owner = _newOwner;
	}
}

pragma solidity ^0.8.22;

/**
 * @dev Tailored and pruned.
 */
library MerkleProof {
	function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
		return processProof(proof, leaf) == root;
	}

	function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
		bytes32 computedHash = leaf;
		for(uint256 i = 0; i < proof.length; i++) {
			computedHash = _hashPair(computedHash, proof[i]);
		}
		return computedHash;
	}

	function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
		bytes32 computedHash = leaf;
		for(uint256 i = 0; i < proof.length; i++) {
			computedHash = _hashPair(computedHash, proof[i]);
		}
		return computedHash;
	}

	function processMultiProof(bytes32[] memory proof, bool[] memory proofFlags, bytes32[] memory leaves) internal pure returns (bytes32 merkleRoot) {
		uint256 leavesLen = leaves.length;
		uint256 totalHashes = proofFlags.length;

		require(leavesLen + proof.length - 1 == totalHashes, _strInvalidMultiproof);

		bytes32[] memory hashes = new bytes32[](totalHashes);
		uint256 leafPos = 0;
		uint256 hashPos = 0;
		uint256 proofPos = 0;

		for(uint256 i = 0; i < totalHashes; i++) {
			bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
			bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
			hashes[i] = _hashPair(a, b);
		}

		if(totalHashes > 0) {
			return hashes[totalHashes - 1];
		}
		else if(leavesLen > 0) {
			return leaves[0];
		}
		else {
			return proof[0];
		}
	}

	function processMultiProofCalldata(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] memory leaves) internal pure returns (bytes32 merkleRoot) {
		uint256 leavesLen = leaves.length;
		uint256 totalHashes = proofFlags.length;

		require(leavesLen + proof.length - 1 == totalHashes, _strInvalidMultiproof);

		bytes32[] memory hashes = new bytes32[](totalHashes);
		uint256 leafPos = 0;
		uint256 hashPos = 0;
		uint256 proofPos = 0;

		for(uint256 i = 0; i < totalHashes; i++) {
			bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
			bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
			hashes[i] = _hashPair(a, b);
		}

		if(totalHashes > 0) {
			return hashes[totalHashes - 1];
		}
		else if(leavesLen > 0) {
			return leaves[0];
		}
		else {
			return proof[0];
		}
	}

	function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
		return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
	}

	function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
		/// @solidity memory-safe-assembly
		assembly {
			mstore(0x00, a)
			mstore(0x20, b)
			value := keccak256(0x00, 0x40)
		}
	}
}

pragma solidity ^0.8.22;
contract Mablab is Context, ERC721, IERC4906 {
	using MerkleProof for bytes32[];
	event ReceivedRoyalties(address indexed creator, address indexed buyer, uint256 indexed amount);

	bool private _boolPaused = true;

	bytes32 _legitMerkleRoot = 0x9da2d7260bb59a40371b7bfb656798384e73b9b05f2f57c7bab1a451a0db48fd;

	uint256 private _mintFee = 39900000000000000; //39900000000000000, 0.0399 ETH.
	uint256 private _mintedTokens = 0;
	uint256 private _maxCap = 1669;
	uint256 private _sellerFeePoints = 1000; // 10%.

	uint256[] private tokenTracker;

	address private _addrContractOwner = 0x389D43178ad6076521C7F2Ca19bEEc806ef00D2a;
	address private _addrContractCopilot = 0x4DaE7E6c0Ca196643012cDc526bBc6b445A2ca59;

	string private _strMetadataURI = 'https://mablab.mypinata.cloud/ipfs/QmPAvaxvjw5UnfVxgj8vyp938Juh1YBZ6xXBYkNk4BojHm/';
	string private _strContractJSON = 'https://mablab.mypinata.cloud/ipfs/QmYYUuaaBWFGok1bAiZL7QsGnVuiQHZMYXCMduswGY2kGZ';

// ==================================================================
//                              MODIFIERS
// ==================================================================

	modifier isUnpaused() {
		require(!_boolPaused, _strPaused);
		_;
	}

	modifier isWithinExistence(uint256 tokenId) {
		require(tokenId > 0, _strOutOfBounds);
		require(tokenId <= _maxCap, _strOutOfBounds);
		require(_exists(tokenId), _strOutOfBounds);
		_;
	}

	modifier isMintable(uint256 tokenId) {
		require(tokenId > 0, _strOutOfBounds);
		require(tokenId <= _maxCap, _strOutOfBounds);
		require(!_exists(tokenId), _strAlreadyMinted);
		_;
	}

	modifier isAudited(uint256 tokenId, bytes32[] memory proof, string memory hash) {
		bytes32 _leaf = keccak256(bytes.concat(keccak256(abi.encode(tokenId, hash))));
		require(MerkleProof.verify(proof, _legitMerkleRoot, _leaf), _strNotAuthorized);
		_;
	}

	modifier onlyAdmin {
		require(_msgSender() == _addrContractOwner, _strNotAuthorized);
		_;
	}

	modifier onlyPilots {
		require((_msgSender() == _addrContractOwner || _msgSender() == _addrContractCopilot), _strNotAuthorized);
		_;
	}

	constructor() ERC721() {}

// ==================================================================
//                       MAIN PUBLIC FUNCTIONS
// ==================================================================

// ------------------------------------------------------------------
//                               GETTERS
// ------------------------------------------------------------------
	/// @notice Returns a URI to the contract's JSON.
	function contractURI() public view returns(string memory) {
		return _strContractJSON;
	}

	/// @notice Returns 1 if a given tokenId exists, 0 if it does not exist.
	/// @param tokenId Token ID.
	function isMinted(uint256 tokenId) public view returns(bool) {
		return _exists(tokenId);
	}

	/// @notice Returns how many minted tokens are at the moment.
	function mintedTokens() public view returns(uint256) {
		return _mintedTokens;
	}

	/// @notice Returns the mint value expressed in wei.
	function mintFee() public view returns(uint256) {
		return _mintFee;
	}

	/// @notice Returns the current Merkle root.
	function merkleRoot() public view returns(bytes32) {
		return _legitMerkleRoot;
	}

	/// @notice Returns the contract's name.
	function name() public view returns(string memory) {
		return _strTokenName;
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns(bool) {
		return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
	}

	/// @notice Returns the contract's symbol, or ticker.
	function symbol() public view returns(string memory) {
		return _strTokenTicker;
	}

	/// @notice Returns a URI to the external JSON holding the token's metadata.
	/// @param tokenId Token ID.
	function tokenURI(uint256 tokenId) isWithinExistence(tokenId) public view returns(string memory) {
		// Convert this to external JSON, located on the specific path.
		return string(
			abi.encodePacked(
				_strMetadataURI,
				Strings.toString(tokenId),
				'.json'
			)
		);
	}

	/// @notice Returns contract's max supply.
	function totalSupply() public view returns(uint256) {
		return _maxCap;
	}

// ------------------------------------------------------------------
//                               SETTERS
// ------------------------------------------------------------------

	/// @notice Mints a new token without the need of a Merkle proof. Only for admins.
	/// @param tokenId A number between 1 and 1669, that uniquely identifies this token.
	function adminMint(uint256 tokenId) public isMintable(tokenId) onlyPilots payable {
		_mintedTokens++;
		_mint(_msgSender(), tokenId);
	}

	/// @notice Changes the contract's owner.
	///	 Note: Only current contract's owner can change this.
	/// @param _newOwner Address of the new owner.
	function changeContractOwner(address _newOwner) onlyPilots public {
		_addrContractOwner = _newOwner;
	}

	/// @notice Changes mint fee.
	///	 Note: Only contract's owner can change this.
	/// @param _newValue New value in wei.
	function changeMintFee(uint256 _newValue) onlyAdmin public {
		_mintFee = _newValue;
	}

	/// @notice Changes onchain contents.
	///	 Note: Only contract's owner can change this.
	/// @param _string New content, minified.
	/// @param _index 1 for metadata URI, 3 for contract's metadata.
	function changeOnchainData(string memory _string, uint8 _index) onlyAdmin public {
		if(_index == 1) {
			_strMetadataURI = _string;
		}
		else if(_index == 2) {
			_strContractJSON = _string;
		}
		if(_mintedTokens > 0) {
			emit BatchMetadataUpdate(1, 1669);
		}
	}

	/// @notice Mints a new token.
	/// @param tokenId A number between 1 and 1669, that uniquely identifies this token.
	/// @param proof Merkle proof.
	/// @param hash Merkled hash, to avoid tampering.
	function mint(uint256 tokenId, bytes32[] memory proof, string memory hash) public isMintable(tokenId) isAudited(tokenId, proof, hash) payable {
		require(msg.value >= _mintFee, string(abi.encodePacked('Must pay ', Strings.toString(_mintFee), ' wei.')));
		require(!_boolPaused, _strPaused);
		_mintedTokens++;
		_mint(_msgSender(), tokenId);
	}

	/// @notice Sets the merkle root.
	///	 Note: Only contract's owner can use this function.
	/// @param _merkleRoot merkle root.
	function setMerkleRoot(bytes32 _merkleRoot) public onlyAdmin {
		_legitMerkleRoot = _merkleRoot;
	}

	/// @notice Pauses or unpauses the contract
	///	 Note: Only contract's owner can change this.
	/// @param _state boolean, true to pause, false to unpause
	function setPauseStatus(bool _state) onlyPilots public {
		_boolPaused = _state;
	}

	/// @notice Allows to withdraw any ETH available on this contract.
	///	 Note: Only contract's owner can withdraw.
	function withdraw() public onlyPilots isUnpaused payable {
		uint balance = address(this).balance;
		uint myBalance = balance * 30 / 100;
		uint remaining = balance - myBalance;
		require(balance > 0, _strNotEnoughBalance);
		(bool firstTX, ) = (_addrContractCopilot).call{value: myBalance}('');
		(bool secondTX, ) = (_addrContractOwner).call{value: remaining}('');
		require(firstTX && secondTX, _strTransferFailed);
	}

	/// @notice Allows to withdraw any ETH available on this contract.
	///	 Note: This function is set in place to withdraw only if for some reason the normal function isn't working properly, or one of the addresses is no longer available.
	function overrideWithdraw() public onlyPilots isUnpaused payable {
		uint balance = address(this).balance;
		require(balance > 0, _strNotEnoughBalance);
		(bool success, ) = (msg.sender).call{value: balance}("");
		require(success, _strTransferFailed);
	}

	function royaltiesReceived(address _creator, address _buyer, uint256 _amount) external {
		emit ReceivedRoyalties(_creator, _buyer, _amount);
	}
}