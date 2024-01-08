// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";
import "./ILicensedNFT.sol";

contract AuthToken is ERC20PresetMinterPauserUpgradeable {
  ILicensedNFT internal NFTContract;
  uint256 internal tokenId;

  function initialize(
    string memory _name,
    string memory _symbol,
    uint256 _tokenId
  ) public virtual initializer {
    super.initialize(_name, _symbol);
    NFTContract = ILicensedNFT(msg.sender);
    tokenId = _tokenId;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function getNFTContract() external view returns (address) {
    return address(NFTContract);
  }

  function getLinkedTokenId() external view returns (uint256) {
    return tokenId;
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) public virtual override {
    require(!NFTContract.authTokenDeployementPaused(), "ERR_AUTHTOKEN_PAUSED");
    require(
      hasRole(MINTER_ROLE, _msgSender()) ||
        NFTContract.ownerOf(tokenId) == _msgSender(),
      "ERC20PresetMinterPauser: must have minter role to mint"
    );
    _mint(to, amount);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual override {
    require(
      hasRole(PAUSER_ROLE, _msgSender()) ||
        NFTContract.ownerOf(tokenId) == _msgSender(),
      "ERC20PresetMinterPauser: must have pauser role to pause"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual override {
    require(
      hasRole(PAUSER_ROLE, _msgSender()) ||
        NFTContract.ownerOf(tokenId) == _msgSender(),
      "ERC20PresetMinterPauser: must have pauser role to unpause"
    );
    _unpause();
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for ``accounts``'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) public override {
    if (NFTContract.ownerOf(tokenId) == _msgSender()) {
      _burn(account, amount);
    } else {
      super.burnFrom(account, amount);
    }
  }
}
