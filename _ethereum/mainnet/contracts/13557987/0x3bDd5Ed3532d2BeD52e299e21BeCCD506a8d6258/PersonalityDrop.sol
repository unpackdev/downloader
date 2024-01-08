// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721Spec.sol";
import "./AletheaERC721Spec.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";

/**
 * @title Personality Pod Airdrop
 *
 * @notice During the release 2.0 distribution event of 10,000 personality pods,
 *      it became clear there is a need to distribute around 10% for free, as an Airdrop.
 *
 * @notice PersonalityDrop contract introduces a scalable mechanism to mint NFTs to an arbitrary
 *      amount of addresses by leveraging the power of Merkle trees to "compress" minting data.
 *
 * @notice The input data is an array of (address, tokenId) pairs; Merkle tree is built out
 *      from this array, and the tree root is stored on the contract by its data manager.
 *      When minting (address, tokenId), executor specifies also the Merkle proof for an
 *      element (address, tokenId) to mint.
 */
contract PersonalityDrop is AccessControl {
	// Use Zeppelin MerkleProof Library to verify Merkle proofs
	using MerkleProof for bytes32[];

	/**
	 * @notice Input data root, Merkle tree root for an array of (address, tokenId) pairs,
	 *      available for minting
	 *
	 * @notice Merkle root effectively "compresses" the (potentially) huge array of data elements
	 *      and allows to store it in a single 256-bits storage slot on-chain
	 */
	bytes32 public root;

	/**
	 * @dev Mintable ERC721 contract address to mint tokens of
	 */
	address public immutable targetContract;

	/**
	 * @notice Enables the airdrop, redeeming the tokens
	 *
	 * @dev Feature FEATURE_REDEEM_ACTIVE must be enabled in order for
	 *      `mint()` function to succeed
	 */
	uint32 public constant FEATURE_REDEEM_ACTIVE = 0x0000_0001;

	/**
	 * @notice Data manager is responsible for supplying the valid input data array
	 *      Merkle root which then can be used to mint tokens, meaning effectively,
	 *      that data manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_DATA_MANAGER allows setting the Merkle tree root via setInputDataRoot()
	 */
	uint32 public constant ROLE_DATA_MANAGER = 0x0001_0000;

	/**
	 * @dev Fired in setInputDataRoot()
	 *
	 * @param _by an address which executed the operation
	 * @param _root new Merkle root value
	 */
	event RootChanged(address indexed _by, bytes32 _root);

	/**
	 * @dev Fired in redeem()
	 *
	 * @param _by an address which executed the operation
	 * @param _to an address the token was minted to
	 * @param _tokenId token ID minted
	 * @param _proof Merkle proof for the (_to, _tokenId) pair
	 */
	event Redeemed(address indexed _by, address indexed _to, uint256 indexed _tokenId, bytes32[] _proof);

	/**
	 * @dev Creates/deploys PersonalityDrop and binds it to AI Personality smart contract on construction
	 *
	 * @param _target deployed Mintable ERC721 smart contract; contract will mint NFTs of that type
	 */
	constructor(address _target) {
		// verify the input is set
		require(_target != address(0), "target contract is not set");

		// verify the input is valid smart contract of the expected interfaces
		require(
			ERC165(_target).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_target).supportsInterface(type(MintableERC721).interfaceId),
			"unexpected target type"
		);

		// assign the address
		targetContract = _target;
	}

	/**
	 * @notice Restricted access function to update input data root (Merkle tree root),
	 *       and to define, effectively, the tokens to be created by this smart contract
	 *
	 * @dev Requires executor to have `ROLE_DATA_MANAGER` permission
	 *
	 * @param _root Merkle tree root for the input data array
	 */
	function setInputDataRoot(bytes32 _root) public {
		// verify the access permission
		require(isSenderInRole(ROLE_DATA_MANAGER), "access denied");

		// update input data Merkle tree root
		root = _root;

		// emit an event
		emit RootChanged(msg.sender, _root);
	}

	/**
	 * @notice Verifies the validity of a `(_to, _tokenId)` pair supplied based on the Merkle root
	 *      of the entire `(_to, _tokenId)` data array (pre-stored in the contract), and the Merkle
	 *      proof `_proof` for the particular `(_to, _tokenId)` pair supplied
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the original array data elements (_to, _tokenId) via `web3.utils.soliditySha3`,
	 *         making sure the packing order and types are exactly as in `mint()` signature
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed array, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given data element (_to, _tokenId) the proof is constructed by hashing it
	 *         (as in step 1) and querying the MerkleTree for a proof, providing the hashed element
	 *         as a leaf
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint
	 * @param _proof Merkle proof for the (_to, _tokenId) pair supplied
	 * @return true if Merkle proof is valid (data belongs to the original array), false otherwise
	 */
	function isTokenValid(address _to, uint256 _tokenId, bytes32[] memory _proof) public view returns(bool) {
		// construct Merkle tree leaf from the inputs supplied
		bytes32 leaf = keccak256(abi.encodePacked(_to, _tokenId));

		// verify the proof supplied, and return the verification result
		return _proof.verify(root, leaf);
	}

	/**
	 * @notice Mints token `_tokenId` to an address `_to`, verifying the validity
	 *      of a `(_to, _tokenId)` pair via the Merkle proof `_proof`
	 *
	 * @dev Merkle tree and proof can be constructed using the `web3-utils`, `merkletreejs`,
	 *      and `keccak256` npm packages:
	 *      1. Hash the original array data elements (_to, _tokenId) via `web3.utils.soliditySha3`,
	 *         making sure the packing order and types are exactly as in `mint()` signature
	 *      2. Create a sorted MerkleTree (`merkletreejs`) from the hashed array, use `keccak256`
	 *         from the `keccak256` npm package as a hashing function, do not hash leaves
	 *         (already hashed in step 1); Ex. MerkleTree options: {hashLeaves: false, sortPairs: true}
	 *      3. For any given data element (_to, _tokenId) the proof is constructed by hashing it
	 *         (as in step 1) and querying the MerkleTree for a proof, providing the hashed element
	 *         as a leaf
	 *
	 * @dev Throws is the data or merkle proof supplied is not valid
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId token ID to mint
	 * @param _proof Merkle proof for the (_to, _tokenId) pair supplied
	 */
	function redeem(address _to, uint256 _tokenId, bytes32[] memory _proof) public {
		// verify airdrop is in active state
		require(isFeatureEnabled(FEATURE_REDEEM_ACTIVE), "redeems are disabled");

		// verify the `(_to, _tokenId)` pair is valid
		require(isTokenValid(_to, _tokenId, _proof), "invalid token");

		// mint the token
		MintableERC721(targetContract).safeMint(_to, _tokenId);

		// emit an event
		emit Redeemed(msg.sender, _to, _tokenId, _proof);
	}
}
