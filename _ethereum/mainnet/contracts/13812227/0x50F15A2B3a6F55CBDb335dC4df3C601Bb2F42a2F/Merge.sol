//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import "./IERC721.sol";
import "./IBurnableERC20.sol";

import "./console.sol";

/**
 * @title Moon Boyz merge contract
 *
 * @notice Allows to merge two Moon Boyz and move one
 *         attribute from one to the other. Once two Moon
 *         boyz have been merged, the first one whose attribute
 *         was put on the second one, is destroyed.
 *
 */
contract Merge {
  /**
   * @notice Stores the address of the ERC-721 tokens
   *         that will be merged
   */
  IERC721 immutable public erc721;

  /**
   * @notice Where destroyed NFTs go to
   */
  address immutable public burnAddress = 0x000000000000000000000000000000000000dEaD;

  /**
   * @dev Sets initialization variables which cannot be
   *      changed in the future
   *
   * @param _erc721Address address of erc721 tokens to be used
   */
  constructor(address _erc721Address) {
    erc721 = IERC721(_erc721Address);
  }

  /**
   * @dev Emitted when a merge happens
   *
   * Emitted in merge()
   *
   * @param by address doing the merge
   * @param from ID of token being sacrificed
   * @param to ID of token whose attribute will change
   * @param attribute attribute that will transfer from `from` to `to`
   */
  event Merge(
    address indexed by,
    uint256 indexed from,
    uint256 indexed to,
    string attribute
  );

  /**
   * @notice Merges two NFTs by moving one attribute from one NFT
   *         to the other. After the merge, the `_from` NFT is destroyed
   *         and its metadata is replaced with an image denoting that. We
   *         cannot burn the NFTs since the creator of the Moon boyz NFT
   *         contract did not add such functionality
   *
   * @dev We do not perform any checks on the `_attribute` parameter
   *      as that is checked on the back-end
   *
   * @param _from ID of token being sacrificed
   * @param _to ID of token whose attribute will change
   * @param _attribute attribute that will transfer from `from` to `to`
   */
  function merge(uint256 _from, uint256 _to, string memory _attribute) public {
    // Ensure user owns both tokens
    require(erc721.ownerOf(_from) == msg.sender, "not owner of _from token");
    require(erc721.ownerOf(_to) == msg.sender, "not owner of _to token");

    // Destroy token by sending it to the burn address
    // Will throw if user has not approved Merge contract
    // for moving his tokens
    erc721.transferFrom(msg.sender, burnAddress, _from);

    // Emit event
    emit Merge(
      msg.sender,
      _from,
      _to,
      _attribute
    );
  }
}
