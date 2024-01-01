//SPDX-License-Identifier: UNLICENSED

//https://twitter.com/meme_printer69
// https://t.me/thememeprinter
// https://www.memeprinter.xyz/
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./Context.sol";
import "./MerkleProof.sol";
import "./MemeP.sol";

contract MEMEPAirdrop is Context, Ownable {
    
    IERC20 private _memep;
    bool isOpen = false;

    //Mapping of the addresses that already claimed the airdrop

    mapping(address => bool) public hasClaimed;
    
    constructor(address memep) {
        _memep = IERC20(memep);        
    }

    /**
     * @notice Add to whitelist
     */
     /**
     * @notice Merkle root hash for whitelist addresses
     */
    bytes32 public merkleRoot = 0x77d63ab50c1528e1397e66bfa8b8c8928ecb4e9a49d4534735ad41dd6757a190;

    /**
     * @notice Change merkle root hash
     */
    function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner
    {
        merkleRoot = merkleRootHash;
    }

    /**
     * @notice Verify merkle proof of the address
     */
    function verifyAddress(bytes32[] calldata _merkleProof) private 
    view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Function with whitelist
     */
  function claimAirdrop(bytes32[] calldata _merkleProof) public
    {
        require (isOpen == true, "Not opened yet");
        uint256 amount = 2500000000000;
        require(verifyAddress(_merkleProof), "Address is not eligible");
        require(!hasClaimed[msg.sender], "Address has already claimed the airdrop");
        _memep.transfer(msg.sender,amount);
        hasClaimed[msg.sender] = true;
    }

  function setOpen(bool _isOpen) public onlyOwner {
    isOpen = _isOpen;
  }   
}