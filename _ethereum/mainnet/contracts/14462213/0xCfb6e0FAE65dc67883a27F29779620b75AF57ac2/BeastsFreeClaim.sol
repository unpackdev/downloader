// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

interface IERC721A {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract DGBFreeClaim is ERC721Holder, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_CLAIM = 50;

    mapping(uint256 => bool) public claimedTokens;
    uint256 public latestIdClaimed;
    bool public isClaiming;
    IERC721A immutable OGContract;
    bytes32 public merkleRoot;

    // _latestId - the latest NFT id issued on the original smart contract
    constructor(
        address _OGContractAddress,
        bytes32 _merkleRoot,
        uint256 _latestId
    ) {
        OGContract = IERC721A(_OGContractAddress);
        latestIdClaimed = _latestId;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256[] memory _ids, bytes32[][] calldata merkleProof) external {
        require(isClaiming, "DGBFreeClaim::claim(): Claim functionality is not enabled.");
        require(_ids.length > 0, "DGBFreeClaim::claim(): There are no tokens to claim.");
        require(_ids.length == merkleProof.length,
            "DGBFreeClaim::claim(): The amount of merkle proofs should be equal to the amount of ids.");
        require(_ids.length <= MAX_CLAIM, "DGBFreeClaim::claim(): You can only claim MAX_CLAIM tokens every time.");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(OGContract.ownerOf(id) == msg.sender, "DGBFreeClaim::claim(): Sender doesn't own the IDs.");
            require(!claimedTokens[id], "DGBFreeClaim::claim(): Token was already claimed.");

            bytes32 node = keccak256(abi.encodePacked(id));
            require(
                MerkleProof.verify(merkleProof[i], merkleRoot, node),
                "DGBFreeClaim::preMint: Invalid merkle proof."
            );

            claimedTokens[id] = true;
            OGContract.transferFrom(address(this), msg.sender, latestIdClaimed);
            latestIdClaimed++;
        }
    }

    function claimableTokens(address _to) external view returns (uint256[] memory) {
        uint256 balance = OGContract.balanceOf(_to);
        uint256[] memory claimableIds = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 id = OGContract.tokenOfOwnerByIndex(_to, i);
            if (!claimedTokens[id]) claimableIds[i] = id;
        }
        return claimableIds;
    }

    function withdrawTo(
        address _receiver,
        uint256[] memory _ids,
        bytes32[][] calldata merkleProof
    ) external onlyOwner {
        require(isClaiming, "DGBFreeClaim::withdrawTo(): Claim functionality is not enabled.");
        require(_ids.length > 0, "DGBFreeClaim::withdrawTo(): There are no tokens to claim.");
        require(_ids.length == merkleProof.length,
            "DGBFreeClaim::withdrawTo(): The amount of merkle proofs should be equal to the amount of ids.");
        require(_ids.length <= MAX_CLAIM, "DGBFreeClaim::withdrawTo(): You can only claim MAX_CLAIM tokens every time.");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            require(OGContract.ownerOf(id) == msg.sender, "DGBFreeClaim::withdrawTo(): Sender doesn't own the IDs.");
            require(!claimedTokens[id], "DGBFreeClaim::withdrawTo(): Token was already claimed.");

            bytes32 node = keccak256(abi.encodePacked(id));
            require(
                MerkleProof.verify(merkleProof[i], merkleRoot, node),
                "DGBFreeClaim::withdrawTo: Invalid merkle proof."
            );

            claimedTokens[id] = true;
            OGContract.transferFrom(address(this), _receiver, latestIdClaimed);
            latestIdClaimed++;
        }
    }

    function withdrawEmergency(address _receiver, uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            OGContract.transferFrom(address(this), _receiver, _ids[i]);
        }
    }

    function switchClaimingStatus() external onlyOwner {
        isClaiming = !isClaiming;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}