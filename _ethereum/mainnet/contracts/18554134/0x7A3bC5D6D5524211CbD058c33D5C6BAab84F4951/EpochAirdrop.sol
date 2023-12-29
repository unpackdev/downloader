// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./MerkleProof.sol";
import "./EpochToken.sol";

contract EpochAirdrop is Ownable {

    uint32 public startDate;
    uint32 public endDate;
    EpochToken public epochToken;
    bytes32 public merkleRoot;

    mapping(uint256 => bool) public isClaimed;

    // @notice This is a single use airdrop contract using merkle trees
    constructor(address _newOwner) {
        _transferOwnership(_newOwner);
    }

    function initialiseAirdrop(uint32 _startDate, uint32 _endDate, address _tokenAddress, bytes32 _merkleRoot) public onlyOwner {
        require(address(epochToken) == address(0), "ALREADY INIT");
        startDate = _startDate;
        endDate = _endDate;
        epochToken = EpochToken(_tokenAddress);
        merkleRoot = _merkleRoot;
    }

    // @notice Allows users to claim their own airdrop
    function claim(uint256 _index, uint256 _tokenAmount, bytes32[] calldata _merkleProof) external {
        require(block.timestamp >= startDate && block.timestamp < endDate, "DROP INACTIVE");
        require(!isClaimed[_index], "CLAIMED");

        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _tokenAmount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "INVALID PROOF");
        isClaimed[_index] = true;

        epochToken.transfer(msg.sender, _tokenAmount);
    }

    // @notice Allows anyone to call (after the end date) which will burn all remaining airdrop tokens
    function burnAirdrop() external {
        require(block.timestamp > endDate, "DROP STILL ACTIVE");

        epochToken.burn(epochToken.balanceOf(address(this)));
    }
}
