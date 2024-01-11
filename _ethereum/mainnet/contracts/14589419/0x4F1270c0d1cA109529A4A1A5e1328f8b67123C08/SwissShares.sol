// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./EnumerableSet.sol";
import "./EIP3009.sol";
import "./EIP2612.sol";
import "./EIP712.sol";
import "./Admin.sol";
import "./Whitelist.sol";
import "./console.sol";

contract SwissShares is ERC20Pausable, EIP2612, EIP3009, Admin, Whitelist {
  uint256 private constant MAX_AMOUNT = 30000000;
  uint256 private constant MIN_AMOUNT = 1;

  mapping(address => uint256) private _tokenHolders;
  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet internal _holders;

  constructor(uint256 initialSupply)
    ERC20("SwissShares", "SSI")
    Admin()
    Whitelist()
  {
    _mint(_msgSender(), initialSupply);

    DOMAIN_SEPARATOR = EIP712.makeDomainSeparator("SwissShares", "1");
  }

  /**
   * @dev returns the number of decimals used to get the user representation
   *
   * See {ERC20-decimals}.
   */
  function decimals() public pure override returns (uint8) {
    return 0;
  }

  function addAdmin(address account) public onlyAdmin whenNotPaused {
    _addAdmin(account);
  }

  function removeAdmin(address account) public onlyAdmin whenNotPaused {
    _removeAdmin(account);
  }

  /**
   * @dev Creates `amount` of new tokens and assigns them to the caller.
   *
   * See {ERC20-_mint}.
   */
  function mint(uint256 amount) public virtual onlyAdmin whenNotPaused {
    _mint(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) public virtual onlyAdmin whenNotPaused {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Adds an `account` to Whitlisted account list
   *
   * See {Whitelist-_add}.
   */
  function addWalletToWhitelist(address account) public onlyAdmin whenNotPaused {
    _add(account);
  }

  /**
   * @dev Removes an `account` to Whitlisted account list
   *
   * See {Whitelist-_remove}.
   */
  function removeWalletFromWhitelist(address account) public onlyAdmin whenNotPaused {
    _remove(account);
  }

  function getAllTokenHolders()
    public
    view returns (address[] memory)
  {
    return _holders._inner._values;
  }

  /**
   * @dev Pause all token transfers
   *
   * See {Pause-_pause}.
   */
  function pauseTransfers() public onlyAdmin whenNotPaused {
    _pause();
  }

  /**
   * @dev Unpause all token transfers
   *
   * See {Pause-_unpause}.
   */
  function unPauseTransfers() public onlyAdmin whenPaused {
    _unpause();
  }

  function freezeTransfersFromWallet(address account) public onlyAdmin whenNotPaused {
    // Not checking for allowance as Admin will execute this function
    // when token holder's private key is lost

    // Get the total balance of the given wallet
    uint256 amount = balanceOf(account);
    _burn(account, amount);
    // Remove this wallet from the whitelist
    removeWalletFromWhitelist(account);
  }

  /**
   * @dev Override this method in order to check some conditions before any transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);
    require(amount >= MIN_AMOUNT, "SwissShares: Minimum amount error");
    require(amount <= MAX_AMOUNT, "SwissShares: Maximum amount error");
    require(amount % 1 == 0, "SwissShares: Can't transfer fractional amount");
    if (from == address(0)) {
      // Mint call
      require(
        isWalletWhitelisted(to),
        "SwissShares: Receiver is not whitelisted"
      );
    } else if (to == address(0)) {
      // Burn call
      require(
        isWalletWhitelisted(from),
        "SwissShares: Sender is not whitelisted"
      );
    } else {
      require(
        isWalletWhitelisted(from),
        "SwissShares: Sender is not whitelisted"
      );
      require(
        isWalletWhitelisted(to),
        "SwissShares: Receiver is not whitelisted"
      );
    }
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._afterTokenTransfer(from, to, amount);

    if (to != address(0) && _tokenHolders[to] == 0) {
      // Add the wallet to token holder list
      _holders.add(to);
    }

    if (_tokenHolders[from] != 0 && _tokenHolders[from] - amount == 0) {
      // Remove the wallet from token holder list
      _holders.remove(from);
    }
    // Update the token holdings
    if (to != address(0)) _tokenHolders[to] += amount;
    if (from != address(0)) _tokenHolders[from] -= amount;
  }

  function authTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    _transfer(sender, recipient, amount);
  }

  function permitApprove(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual override {
    _approve(owner, spender, amount);
  }
}
