// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import "./IERC721.sol";
import "./Ownable.sol";
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
 * @dev Features a contract owner that can change the merge cost 
 */
contract Merge is Ownable {
  /**
   * @notice Stores the ERC-20 token that will be
   *         used to pay the fees for the merge
   */
  IBurnableERC20 immutable public erc20;

  /**
   * @notice Stores the address of the ERC-721 tokens
   *         that will be merged
   */
  IERC721 immutable public erc721;

  /**
   * @notice Cost in erc20 tokens to perform a merge
   *
   * @dev Can be changed by contract owner via setMergeCost()
   */
  uint256 public mergeCost;

  /**
   * @notice Where destroyed NFTs go to
   */
  address immutable public burnAddress = 0x000000000000000000000000000000000000dEaD;

  /**
   * @dev Sets initialization variables which cannot be
   *      changed in the future
   *
   * @param _erc20Address address of erc20 fees are to be paid with
   * @param _erc721Address address of erc721 tokens to be used
   * @param _mergeCost cost of merge in erc20 tokens
   */
  constructor(address _erc20Address, address _erc721Address, uint256 _mergeCost) {
    erc20 = IBurnableERC20(_erc20Address);
    erc721 = IERC721(_erc721Address);
    mergeCost = _mergeCost;
  }

  /**
   * @dev Emitted when a the merge cost changes
   *
   * Emitted in setMergeCost()
   *
   * @param by address changing the merge cost
   * @param oldMergeCost previous merge cost
   * @param newMergeCost new merge cost in effect
   */
  event MergeCostChanged(
    address indexed by,
    uint256 oldMergeCost,
    uint256 newMergeCost
  );

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
   * @notice Changes the cost for merging two Moon boyz
   *
   * @dev Restricted to contract owner
   *
   * @param _newMergeCost the new cost to merge in erc20 tokens
   */
  function setMergeCost(uint256 _newMergeCost) public onlyOwner {
    // Emit event
    emit MergeCostChanged(
      msg.sender,
      mergeCost,
      _newMergeCost
    );

    // Change merge cost
    mergeCost = _newMergeCost;
  }

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

    // Burn tokens from user to perform merge
    // Will throw if user does not have enough tokens
    erc20.burn(msg.sender, mergeCost);

    // Emit event
    emit Merge(
      msg.sender,
      _from,
      _to,
      _attribute
    );
  }
}
