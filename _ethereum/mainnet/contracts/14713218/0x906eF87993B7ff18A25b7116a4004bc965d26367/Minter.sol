// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC1155.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./MerkleProof.sol";

import "./PrysmAccessPass.sol";

/// @custom:security-contact security@prysm.xyz
contract Minter is Ownable, ReentrancyGuard, Pausable {
    PrysmAccessPass _nft;
    constructor(address nft) {
        _nft = PrysmAccessPass(nft);
    }

    mapping(uint256 => bytes32) _tokenTypes;
    mapping(uint256 => mapping(address => bool)) private _mintApprovals;
    mapping(address => mapping(uint256 => bool)) private _hasMinted;

    function modifyType(
        uint256 _id,
        bytes32 _root
    ) public onlyOwner {
        _tokenTypes[_id] = _root;
    }

    function mintOwner(address to, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwner
    {
        _nft.mint(to, id, amount, data);
    }

    function transferOwnershipProxy(address account)
    public
    onlyOwner
    {
        _nft.transferOwnership(account);
    }

    function pauseProxy()
    public
    onlyOwner
    {
        _nft.pause();
    }

    function unpauseProxy()
    public
    onlyOwner
    {
        _nft.unpause();
    }

    function pause()
    public
    onlyOwner
    {
        _pause();
    }

    function unpause()
    public
    onlyOwner
    {
        _unpause();
    }

    function setURIProxy(string memory newuri)
    public
    onlyOwner
    {
        _nft.setURI(newuri);
    }

    function mint(uint256 tokenId, bytes32[] calldata proof)
    external
    nonReentrant
    whenNotPaused
    {
        address to = msg.sender;
        require(
            !_hasMinted[to][tokenId],
            "Already minted"
        );
        require(_mintApprovals[tokenId][to] || _verify(tokenId, to, proof), "Invalid merkle proof");
        _mintApprovals[tokenId][to] = false;
        _hasMinted[to][tokenId] = true;
        _nft.mint(to, tokenId, 1, bytes(""));
    }

    function canMintToken(address to, uint256 tokenId, bytes32[] calldata proof)
    external
    view
    returns (bool)
    {
        return !_hasMinted[to][tokenId] &&
        (_mintApprovals[tokenId][to] ||
        _verify(tokenId, to, proof));
    }

    function setMintApproval(
        address to,
        bool value,
        uint256 id
    ) external onlyOwner {
        _mintApprovals[id][to] = value;
    }

    function _leaf(address to, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, to));
    }

    function _verify(uint256 tokenId, address to, bytes32[] memory proof)
    internal view returns (bool)
    {
        bytes32 root = _tokenTypes[tokenId];
        return MerkleProof.verify(proof, root, _leaf(to, tokenId));
    }
}
