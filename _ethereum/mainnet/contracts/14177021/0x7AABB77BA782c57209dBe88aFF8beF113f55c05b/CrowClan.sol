// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract CrowClan is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    string public baseTokenURI;
    Counters.Counter public totalSuplyCounter;
    uint256 public deadline;
    uint256 public immutable cap;

    event MerkleTreeChanged(string merkleTreeIPFSRef, bytes32 root, uint256 deadline);

    constructor(
        string memory _name, 
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _merkleTreeIPFSRef,
        bytes32 _root,
        uint256 _deadline,
        uint256 _cap
    // solhint-disable-next-line func-visibility
    ) ERC721(_name, _symbol) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < _deadline, "Deadline already passed");
        baseTokenURI = _baseTokenURI;
        cap = _cap;
        root = _root;
        deadline = _deadline;
        emit MerkleTreeChanged(_merkleTreeIPFSRef, _root, deadline);
    }

    /**
     * @dev Update the merkle tree root only after 
     * the deadline for minting has been reached.
     * @param _merkleTreeIPFSRef new merkle tree ipfs reference.
     * @param _root new merkle tree root to use for verifying.
     * @param _deadline number of days to the next minting deadline.
     */
    function updateTree(string memory _merkleTreeIPFSRef, bytes32 _root, uint256 _deadline) external onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > deadline, "Minting deadline was not reached");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < _deadline, "New deadline already passed");
        root = _root;
        deadline = _deadline;
        emit MerkleTreeChanged(_merkleTreeIPFSRef, _root, deadline);
    }

    function redeem(address account, uint256 tokenId, bytes32[] calldata proof) external {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp < deadline, "Minting deadline passed");
        require(_verify(proof, _leaf(account, tokenId)), "Invalid merkle proof");
        _safeMint(account, tokenId);
    }

    function _leaf(address account, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _mint(address to, uint256 tokenId) internal override {
        require(totalSupply() < cap, "Supply cap reached");
        totalSuplyCounter.increment();
        super._mint(to, tokenId);
    }

    /**
        @dev Returns the total tokens minted so far.
     */
    function totalSupply() public view returns (uint256) {
        return totalSuplyCounter.current();
    }
}
