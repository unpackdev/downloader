//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//



// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "./ERC20.sol";
import "./IMintableERC20.sol";
import "./IBurnableERC20.sol";
import "./draft-ERC20Permit.sol";
import "./AccessControl.sol";

/**
 * @notice This token contract is minted as a reward by staking
 *         NFTs based on TokenRewardStaking contract
 *         and is burned when merging TokenRewardStaking
 *         or adding accessories to them
 *
 * @dev Supports minting new tokens to an address
 *      from authorized addresses restricted by
 *      the `MINTER_ROLE` role
 *
 * @dev Supports burning tokens from an address from
 *      authorized addresses restricted by the
 *      `BURNER_ROLE` role
 *
 * @dev Supports EIP-2612 permits for gas-less approvals
 */
contract MintableBurnableERC20 is ERC20, ERC20Permit, IMintableERC20, IBurnableERC20, AccessControl {
  /**
   * @notice AccessControl role that allows other EOAs or contracts
   *         to mint tokens
   *
   * @dev Checked in mint()
   */
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @notice AccessControl role that allows other EOAs or contracts
   *         to burn tokens
   *
   * @dev Checked in burn()
   */
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `BURNER_ROLE` to the
   *      account that deploys the contract.
   *
   * @param _name Full name of the NFT
   * @param _symbol Symbol of the NFT
   *
   * See {ERC20-constructor}.
   */
  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) ERC20Permit(_name) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
  }

  /**
   * @dev Mints new tokens to an address
   *
   * @dev Restricted by `MINTER_ROLE` role
   *
   * @param _to the address the new tokens will be minted to
   * @param _amount how many new tokens will be minted
   */
  function mint(address _to, uint256 _amount) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");

    _mint(_to, _amount);
  }

  /**
   * @dev Burns some tokens from an address
   *
   * @dev Restricted by `BURNER_ROLE` role
   *
   * @param _from the address the tokens will be burned from
   * @param _amount how many tokens will be burned
   */
  function burn(address _from, uint256 _amount) public {
    require(hasRole(BURNER_ROLE, _msgSender()), "must have burner role to burn");

    _burn(_from, _amount);
  }
}
