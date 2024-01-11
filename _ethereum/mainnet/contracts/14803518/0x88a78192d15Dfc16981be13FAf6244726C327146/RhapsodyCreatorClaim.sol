// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";
import "./ERC721AOwnersExplicit.sol";

contract RhapsodyCreatorClaim is ERC721A, ERC721AOwnersExplicit, Ownable, ReentrancyGuard {
    /// ============ Libraries ============

    /// @notice safe math for arithmetic operations
    using SafeMath for uint256;

    /// ============ Events ============

    event Created(address indexed to, uint256 invocations);

    /// ============ Immutable storage ============

    /// @notice total number of tokens in the collection
    uint256 internal immutable collectionSize;

    // ============ Mutable storage ============

    /// @notice ERC721-claim inclusion root
    bytes32 public claimMerkleRoot;

    /// @notice time the public starts
    uint256 public claimTime;

    // ============ Private storage ============

    string private _baseTokenURI;

    /// ============= Constructor =============

    /// @notice Creates a new Creator contract
    /// @param _collectionSize the total size of the collection
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _collectionSize
    ) ERC721A(_name, _symbol) {
        require(_collectionSize > 0, "RhapsodyCreatorGenerative/invalid-collection-size");
        collectionSize = _collectionSize;
    }

    /// =========== Sale ===========

    /// @notice Allows claim of tokens if address is part of merkle tree
    /// @param invocations number of tokens to mint
    /// @param proof merkle proof to prove address and token mint count are in tree
    /// @dev user must mint max invocations
    function claimMint(uint256 invocations, bytes32[] calldata proof)
        external
        nonReentrant
        isMintLive(claimTime)
        isMintValid(invocations, invocations)
        isMintProofValid(invocations, msg.sender, proof, claimMerkleRoot)
    {
        _mintMany(msg.sender, invocations);
    }

    /// @notice mint tokens in batches
    /// @param to address to mint to
    /// @param invocations number of tokens to mint
    function _mintMany(address to, uint256 invocations) internal {
        _safeMint(to, invocations);
        emit Created(msg.sender, invocations);
    }

    /// @notice Set the time for the mint
    /// @param _claimTime time the claim starts
    /// @dev this function can serve as an "active" and "non-active" sale status
    /// @dev set the values to uint256(-1) for "non-active" sale status
    /// @dev also, pass contract ownership to address(0) to close sale forever
    function setMintTime(uint256 _claimTime) public onlyOwner {
        claimTime = _claimTime;
    }

    /// @notice ensures that minters need valid invocations + value to mint
    modifier isMintValid(uint256 invocations, uint256 maxInvocation) {
        require(tx.origin == msg.sender, "RhapsodyCreatorGenerative/invalid-mint-caller");
        require(totalSupply().add(invocations) <= collectionSize, "RhapsodyCreatorGenerative/invalid-total-supply");
        require(
            _mintOf(msg.sender).add(invocations) <= maxInvocation,
            "RhapsodyCreatorGenerative/invalid-invocation-upper-boundary"
        );
        require(invocations > 0, "RhapsodyCreatorGenerative/invalid-invocation-lower-boundary");
        _;
    }

    /// @notice used to check the time of mint of presale and public
    /// @dev only publicTime/presaleTime variable is used here; see publicMint/presaleMint function
    /// @dev time > 0 is optimization when the sale is not live; r.e  mint "not-active" mode
    modifier isMintLive(uint256 time) {
        require(time > 0 && block.timestamp > time, "RhapsodyCreatorGenerative/invalid-mint-time");
        _;
    }

    modifier isMintProofValid(
        uint256 invocations,
        address prover,
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) {
        require(
            MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(prover, invocations))),
            "RhapsodyCreatorGenerative/invalid-address-proof"
        );
        _;
    }

    /// @notice force override the merkle root used in presale mint
    /// @param _claimMerkleRoot root of the merklelized claimlist
    function setClaimMerkleRoot(bytes32 _claimMerkleRoot) public onlyOwner {
        claimMerkleRoot = _claimMerkleRoot;
    }

    /// =========== Metadata ===========

    /// @notice set the new baseURI to change the tokens metadata
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @notice core metadata baseURI used for tokens metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice core metadata baseURI used for tokens metadata
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /// =========== Dev ===========

    /// @notice withdraws the ether in the contract to owner
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "RhapsodyCreatorGenerative/invalid-withdraw-money");
    }

    /// @notice returns the current block timestamp
    /// @dev this function is overriden in testing for time-dependent testing
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @notice sets the owners quantity explicity
    /// @dev eliminate loops in future calls of ownerOf()
    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    /// =========== Helpers ===========

    /// @notice internally returns the number of mints of an address
    function _mintOf(address _owner) internal view returns (uint256) {
        return _numberMinted(_owner);
    }

    /// @notice returns the number of mints of an address
    function mintOf(address _owner) public view returns (uint256) {
        return _mintOf(_owner);
    }
}
