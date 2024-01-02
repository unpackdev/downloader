// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./ERC165Storage.sol";
import "./Taxable.sol";

contract Token is ERC20, ERC20Burnable, Taxable, AccessControl {
  /* @dev Variables */
  bool public initialLiquidityProvided = false;
  bool public maxPercentageHoldingEnabled = true;
  uint public maxPercentageHolding = 100; // 1%
  bool public maxTransferPercentageEnabled = true;
  uint public maxTransferPercentage = 50; // 0.5%
  uint public deploymentTimestamp = block.timestamp;
  mapping(address => bool) public uniPairs;
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
  bytes32 public constant EXCLUDED_ROLE = keccak256("EXCLUDED_ROLE");
  mapping(address => bool) public blacklist;

  /* @dev Errors */
  error NoEther();
  error TransferNotAllowed();
  error TransferExceedsHolding();
  error TransferExceedsTransferP();
  error NotEnoughTokenBalance();
  error Blacklisted();
  error BlacklistTimeExpired();
  error SameValue();

  /* @dev Events */
  event MaxPercentageTransferToggle();
  event MaxPercentageHoldingToggle();
  event InitialLiquidityProvided();
  event TaxPercentageUpdated(uint indexed newtax);
  event TaxDestinationUpdated();
  event TaxStateUpdated(bool indexed state);
  event BlacklistUpdated(address indexed _address, bool indexed _state);

  constructor(uint initialSupply) ERC20("Two Lands", "LANDS") {
    _mint(msg.sender, initialSupply);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(GOVERNOR_ROLE, msg.sender);
    _grantRole(EXCLUDED_ROLE, msg.sender);
  }

  /* @dev: Enabled taxation on transfers */
  function toggleTax(bool _state) external onlyRole(GOVERNOR_ROLE) {
    _state == true ? _taxon() : _taxoff();
    emit TaxStateUpdated({state: _state});
  }

  /* @dev: Updates the tax percentage based on points, 1% = 100 */
  function updateTax(uint newtax) external onlyRole(GOVERNOR_ROLE) {
    if (newtax == thetax()) {
      revert SameValue();
    }
    _updatetax(newtax);
    emit TaxPercentageUpdated({newtax: newtax});
  }

  /* @dev: Updates the tax destination, if 0x000...000 then burn */
  function updateTaxDestination(address newDestination) external onlyRole(GOVERNOR_ROLE) {
    if (newDestination == taxdestination()) {
      revert SameValue();
    }
    _updatetaxdestination(newDestination);
    emit TaxDestinationUpdated();
  }

  /* @dev: allows dev to update whether an address is LP or not for max % */
  function updateLPPair(address _address, bool _state) external onlyRole(GOVERNOR_ROLE) {
    uniPairs[_address] = _state;
  }

  /* @dev: Updates whether the initial liquidity has been provided or not */
  function updateInitiaLiquidityProvided() external onlyRole(GOVERNOR_ROLE) {
    initialLiquidityProvided = true;
    emit InitialLiquidityProvided();
  }

  /* @dev: Updates whether max percentage holding enable/disable */
  function toggleMaxPercentageHolding(bool _state) external onlyRole(GOVERNOR_ROLE) {
    maxPercentageHoldingEnabled = _state;
    emit MaxPercentageHoldingToggle();
  }

  /* @dev: Updates whether max percentage transfer enable/disable */
  function toggleMaxTransferEnabled(bool _state) external onlyRole(GOVERNOR_ROLE) {
    maxTransferPercentageEnabled = _state;
    emit MaxPercentageTransferToggle();
  }

  /* @dev: Updates whether an address is blacklisted or not */
  function updateBlacklist(address _address, bool _state) external onlyRole(GOVERNOR_ROLE) {
    /* @dev: Deployer can only blacklist addresses for a duration of 7 days after deployment **/
    if (block.timestamp - deploymentTimestamp > 7 days) {
      revert BlacklistTimeExpired();
    }

    if (blacklist[_address] == _state) {
      revert SameValue();
    }

    blacklist[_address] = _state;
    emit BlacklistUpdated({_address: _address, _state: _state});
  }

  /** Modifier that ensures that given address is not blacklisted */
  modifier isNotBlacklisted(address _address) {
    if (blacklist[_address]) {
      revert Blacklisted();
    }
    _;
  }

  /* @dev: Transfer function override that works with taxation rules and whether liquidity was provided */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20) isNotBlacklisted(from) isNotBlacklisted(to) {
    /* @dev: From user must have enough balance to cover this transfer **/
    if (balanceOf(from) < amount) revert NotEnoughTokenBalance();
    if (initialLiquidityProvided) {
      /* @dev: If from or to user is EXCLUDED, just transfer **/
      if (hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to)) {
        return super._transfer(from, to, amount);
      }
      /* @dev: If taxes is disabled, still maintain maxTransferPercentage and maxHoldingPercentage **/
      else if (!taxed()) {
        /* @dev: Amount of tokens transferred may not exceed 0.5% of totalSupply */
        if (maxTransferPercentageEnabled) {
          if (amount > (totalSupply() * maxTransferPercentage) / 10000) {
            revert TransferExceedsTransferP();
          }
        }

        /* @dev: Users balance may not exceed 1% of the holding after transfer */
        if (maxPercentageHoldingEnabled) {
          if (!uniPairs[to]) {
            if (balanceOf(to) + amount > (totalSupply() * maxPercentageHolding) / 10000) {
              revert TransferExceedsHolding();
            }
          }
        }
        return super._transfer(from, to, amount);
      } else {
        /* @dev: Calculate the taxation **/
        address destination = taxdestination();
        uint taxedAmount = (amount * thetax()) / 10000;
        uint remainingAmount = amount - taxedAmount;

        /* @dev: Amount of tokens transferred may not exceed 0.5% of totalSupply */
        if (maxTransferPercentageEnabled) {
          if (remainingAmount > (totalSupply() * maxTransferPercentage) / 10000) {
            revert TransferExceedsTransferP();
          }
        }

        /* @dev: Users balance may not exceed 1% of the holding after transfer */
        if (maxPercentageHoldingEnabled) {
          if (!uniPairs[to]) {
            if (balanceOf(to) + remainingAmount > (totalSupply() * maxPercentageHolding) / 10000) {
              revert TransferExceedsHolding();
            }
          }
        }
        /* @dev: Send the remaining balance to the to user, and the taxes to its destination **/
        super._transfer(from, destination, taxedAmount);
        return super._transfer(from, to, remainingAmount);
      }
      /* @dev: If no liquidity has been provided and from has the GOVERNOR role, allow transfers **/
    } else if (!initialLiquidityProvided && hasRole(GOVERNOR_ROLE, from)) {
      return super._transfer(from, to, amount);
    } else {
      /* @dev: If no liquidity has been provider, and sender is not GOVERNOR, dont allow transfers **/
      revert TransferNotAllowed();
    }
  }

  /* @dev: Ensure no Ether ends up in contract */
  fallback() external payable {
    revert NoEther();
  }

  /* @dev: Ensure no Ether ends up in contract */
  receive() external payable {
    revert NoEther();
  }
}
