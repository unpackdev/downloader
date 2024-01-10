// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

import "./IMerkleDistributor.sol";
import "./IBrainsDistributor.sol";

contract BrainsAirdrop is Ownable, Pausable, IMerkleDistributor {
    using SafeERC20 for IERC20;

    IBrainsDistributor public brainsDistributor;
    
    bytes32 public immutable merkleRoot;

    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address _brainsDistributor, bytes32 _merkleRoot) {
        brainsDistributor = IBrainsDistributor(_brainsDistributor);
        merkleRoot = _merkleRoot;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused override {
        require(!isClaimed(index), "airdrop_already_claimed");

        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node),"not_on_airdrop_list");

        _setClaimed(index);

        brainsDistributor.mintBrainsFor(account, amount);

        emit Claimed(index, account, amount);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
