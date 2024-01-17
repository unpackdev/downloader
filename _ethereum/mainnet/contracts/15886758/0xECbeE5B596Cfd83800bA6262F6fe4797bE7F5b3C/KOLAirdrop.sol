// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./MerkleProof.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./PlayerOne.sol";

contract KOLAirdrop is ReentrancyGuard,Context{

    PlayerOne public playerOneContract;

    uint256 public endTime;

    bytes32 public whitelistRoot;

    // address->claimed
    mapping(address => bool) public claimed;

     constructor(PlayerOne playerOneContract_,bytes32 whitelistRoot_,uint256 endTime_){
        playerOneContract = playerOneContract_;
        endTime = endTime_;
        whitelistRoot = whitelistRoot_;
    }

    function checkInWhitelist(bytes32[] calldata proof,address addr) view public returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        bool verified = MerkleProof.verify(proof, whitelistRoot, leaf);
        return verified;
    }

    function claim(bytes32[] calldata proof) external nonReentrant returns (uint256) {
        require(block.timestamp < endTime, "KOLAirdrop: ended");
        address sender = _msgSender();
        require(checkInWhitelist(proof,sender), "KOLAirdrop: address not whitelisted");
        require(!claimed[sender], "KOLAirdrop: claimed");
        claimed[sender] = true;

       return playerOneContract.mint(sender);
    }




}