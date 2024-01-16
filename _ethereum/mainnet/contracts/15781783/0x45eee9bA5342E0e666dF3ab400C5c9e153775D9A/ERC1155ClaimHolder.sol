// SPDX-License-Identifier: MIT

/**********************************************

              ///                                        
            ///  ///           ////////                  
         ///       ///    ////         ////              
       ///            /// /                //            
     //                 ///                 /|           
  ///                 /|   //                /|          
/|/                   //     |/               ||          
  ///                 /|   //                /|/          
     //                 ///                 /|/          
       ///            /// /                //            
         ///       ///    ////          ///              
            ///  ///          /////////                  
              ///                                        

***********************************************
*************                    **************
*************   strata.gallery   **************
*************                    **************
***********************************************
*/


/**
 * ERC1155ClaimHolder
 * 
 * This contract holds 1155 tokens, and can transfer
 * the tokens to users who can provide a valid note to 
 * claim said token.
 * 
 * Notes are hashed and compared against a merkle tree root
 * and leafs for the specified token number.abi
 * 
 * NOTE: All valid notes currently only allow the user to claim
 * 1 (ONE) ERC1155 token.
 */

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";

contract ERC1155ClaimHolder is ERC1155Receiver, Ownable {
  
  // Merkle Roots for Tokens on Contracts
  mapping(address => mapping(uint256 => bytes32)) rootsForTokens;

  // Mapping to keep track of claimed notes
  mapping(address => mapping(uint256 => mapping(bytes32 => bool))) noteClaimed;

  // Event to track the claimed notes
  event NoteClaimed(address indexed contractAddress, uint256 tokenId, string note);

  constructor() {}

  /**
   * @dev Check if a note has already been used
   */
  function isClaimed(
    uint256 tokenId,
    address tokenContractAddress,
    string calldata note
  ) public view returns (bool) {
    bytes32 noteHash = keccak256(abi.encodePacked(note));
    return noteClaimed[tokenContractAddress][tokenId][noteHash];
  }

  function isValidNote(
    uint256 tokenId,
    address tokenContractAddress,
    string calldata note,
    bytes32[] calldata proof
  ) public view returns (bool) {
    bytes32 noteHash = keccak256(abi.encodePacked(note));
    
    // verify that is not claimed and note hash is valid
    return 
      !noteClaimed[tokenContractAddress][tokenId][noteHash] &&
      MerkleProof.verify(
      proof, rootsForTokens[tokenContractAddress][tokenId], noteHash
    );
  }

  /**
   * @dev Claim a token with a valid note + proof.
   *
   * Each note can only be used for one claim!
   *
   */
  function claimToken(
    uint256 tokenId,
    address tokenContractAddress,
    string calldata note,
    bytes32[] calldata proof
  ) public {
    // hash note on contract to verify that correct note submitted
    bytes32 noteHash = keccak256(abi.encodePacked(note));
    require(!noteClaimed[tokenContractAddress][tokenId][noteHash], 'Note already claimed!');

    // validate merkle proof for note
    require(MerkleProof.verify(
      proof, rootsForTokens[tokenContractAddress][tokenId], noteHash
    ), "Note not valid!");


    // transfer erc1155 token
    IERC1155 tokenContract = IERC1155(tokenContractAddress);

    tokenContract.safeTransferFrom(
      address(this),
      msg.sender,
      tokenId,
      1, // amount is ALWAYS 1
      '' // no data
    );

    // record that note has been successfully used
    noteClaimed[tokenContractAddress][tokenId][noteHash] = true;

    // emit ClaimNote event
    emit NoteClaimed(tokenContractAddress, tokenId, note);
  }

  /**
   * @dev View the merkle root for a specific token
   */
   function merkleRootForToken(
    uint256 tokenId,
    address tokenContractAddress
  ) public view returns (bytes32) {
    // add to roots for specific contract and id
    return rootsForTokens[tokenContractAddress][tokenId];
  }

  /**
   * @dev Assign Merkle Roots for ERC1155s
   *
   * Each 1155 has their own merkle tree, so that
   * can only claim with note for that specific ERC1155.
   *
   * Example: can only claim ERC1155 with ID of 121 with
   * a note.
   */
  function setMerkleRootForToken(
    bytes32 root,
    uint256 tokenId,
    address tokenContractAddress
  ) public onlyOwner {
    // add to roots for specific contract and id
    rootsForTokens[tokenContractAddress][tokenId] = root;
  }

  /**
   * @dev Assign Merkle Roots for ERC1155s
   *
   * Each 1155 has their own merkle tree, so that
   * can only claim with note for that specific ERC1155.
   *
   * Example: can only claim ERC1155 with ID of 121 with
   * a note.
   */
  function setMerkleRootForTokenBatch(
    bytes32[] calldata roots,
    uint256[] calldata tokenIds,
    address tokenContractAddress
  ) public onlyOwner {
    // add to roots for specific contract and id
    for(uint i = 0; i < roots.length; i++) {
      rootsForTokens[tokenContractAddress][tokenIds[i]] = roots[i];
    }
  }

  /**
   * @dev Backup to transfer out tokens in case of no claims or loss of notes.
   */
  function forceTransfer(
    uint256[] calldata tokenIds,
    uint256[] calldata tokenAmounts,
    address tokenContractAddress,
    address tokenReceiver
  ) public onlyOwner {

    IERC1155 tokenContract = IERC1155(tokenContractAddress);

    tokenContract.safeBatchTransferFrom(
      address(this),
      tokenReceiver,
      tokenIds,
      tokenAmounts,
      ""
    );
  }

  /**
   * @dev IERC1155Receiver implementations
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}


