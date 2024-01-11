// SPDX-License-Identifier: AGPL-3.0-or-later


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";
import "./ILight.sol";

contract MergeCollection is Ownable, ERC721Enumerable, ReentrancyGuard {
	
	using ECDSA for bytes32;
	
	IERC721 collectionA;
	IERC721 collectionB;
	ILight item;
	
	address public root;
	bool initialized;
	
	//check every nonce only mint once
	mapping(uint256=>mapping(uint256=>bool)) merged;
	
	event Merge(address sender, uint256 collectionA_id, uint256 collectionB_id, uint256 targetID);
	
	constructor( string memory name_, string memory symbol_ ) ERC721( name_, symbol_) {}

	function mint(uint256 collectionA_id, uint256 collectionB_id, uint256 targetID, bytes memory _signature) external nonReentrant{
		bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, collectionA_id, collectionB_id, targetID, name()));
        require(isValidSignature(msgHash, _signature), "Not authorized to mint");
		require(collectionA.ownerOf(collectionA_id) == msg.sender, "Not owner of this collectionA id.");
		require(collectionB.ownerOf(collectionB_id) == msg.sender, "Not owner of this collectionB id.");
		require(!merged[collectionA_id][collectionB_id], "Pair already used.");
		merged[collectionA_id][collectionB_id] = true;
		item.burn(msg.sender);
		emit Merge(msg.sender, collectionA_id, collectionB_id, targetID);
		_safeMint(msg.sender, targetID);
	}
	
	function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bool isValid) {
        return hash.recover(signature) == root;
    }
	
	function initialize(address root_, IERC721 collectionA_, IERC721 collectionB_, ILight item_) external onlyOwner {
		require(!initialized, "only initialized once");
		initialized = true;
		root = root_;
		collectionA = collectionA_;
		collectionB = collectionB_;
		item = item_;
	}
	
	function isMerged(uint256 collectionA_id, uint256 collectionB_id) view public returns(bool) {
		return merged[collectionA_id][collectionB_id];
	}

	// // metadata URI
	string private _baseTokenURI;

	function _baseURI() internal view virtual override returns (string memory) {
		return _baseTokenURI;
	}

	function setBaseURI(string calldata baseURI) external onlyOwner {
		_baseTokenURI = baseURI;
	}
	
	fallback() external payable {}

    receive() external payable {}
	
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
    }
}