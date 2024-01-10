// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Controllable.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @title Ape Runners RUN
/// @author naomsa <https://twitter.com/naomsa666>
contract ApeRunnersRUN is
  Ownable,
  Pausable,
  Controllable,
  ERC20("Ape Runners", "RUN", 18, "1")
{
  /* -------------------------------------------------------------------------- */
  /*                               Airdrop Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Ape Runners contract.
  ERC721 public immutable apeRunners;

  /// @notice Ape Runner id => claimed airdrop.
  mapping(uint256 => bool) public airdroped;

  constructor(address newApeRunners) {
    apeRunners = ERC721(newApeRunners);
  }

  /* -------------------------------------------------------------------------- */
  /*                                Airdrop Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Claim pending airdrop for each Ape Runner.
  /// @param ids Ape Runner token ids to claim airdrop.
  function claim(uint256[] memory ids) external {
    uint256 pending;

    for (uint256 i; i < ids.length; i++) {
      require(apeRunners.ownerOf(ids[i]) == msg.sender, "Not the token owner");
      require(!airdroped[ids[i]], "Airdrop already claimed");
      airdroped[ids[i]] = true;
      pending += 150 ether;
    }

    super._mint(msg.sender, pending);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state)
    external
    onlyOwner
  {
    for (uint256 i; i < addrs.length; i++)
      super._setController(addrs[i], state);
  }

  /// @notice Switch the contract paused state between paused and unpaused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-20 Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint tokens.
  /// @param to Address to get tokens minted to.
  /// @param value Number of tokens to be minted.
  function mint(address to, uint256 value) external onlyController {
    super._mint(to, value);
  }

  /// @notice Burn tokens.
  /// @param from Address to get tokens burned from.
  /// @param value Number of tokens to be burned.
  function burn(address from, uint256 value) external onlyController {
    super._burn(from, value);
  }

  /// @notice See {ERC20-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
