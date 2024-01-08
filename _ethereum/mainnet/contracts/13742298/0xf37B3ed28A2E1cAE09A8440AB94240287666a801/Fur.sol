// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ERC20.sol";
import "./Furballs.sol";
import "./IFurballEdition.sol";
import "./FurProxy.sol";

/// @title Fur
/// @author LFG Gaming LLC
/// @notice Utility token for in-game rewards in Furballs
contract Fur is ERC20, FurProxy {
  // n.b., this contract has some unusual tight-coupling between FUR and Furballs
  // Simple reason: this contract had more space, and is the only other allowed to know about ownership
  // Thus it serves as a sort of shop meta-store for Furballs

  constructor(address furballsAddress) FurProxy(furballsAddress) ERC20("Fur", "FUR") {
  }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice FUR is a strict counter, with no decimals
  function decimals() public view virtual override returns (uint8) {
    return 0;
  }

  /// @notice Returns the snacks currently applied to a Furball
  function snacks(uint256 tokenId) external view returns(FurLib.Snack[] memory) {
    return furballs.engine().snacks().snacks(tokenId);
  }

  /// @notice Write-function to cleanup the snacks for a token (remove expired)
  /// @dev Since migrating to SnackShop, this function no longer writes; it matches snackEffects
  function cleanSnacks(uint256 tokenId) external view returns (uint256) {
    return furballs.engine().snacks().snackEffects(tokenId);
  }

  /// @notice The public accessor calculates the snack boosts
  function snackEffects(uint256 tokenId) external view returns(uint256) {
    return furballs.engine().snacks().snackEffects(tokenId);
  }

  // -----------------------------------------------------------------------------------------------
  // GameAdmin
  // -----------------------------------------------------------------------------------------------

  /// @notice FUR can only be minted by furballs doing battle.
  function earn(address addr, uint256 amount) external gameModerators {
    if (amount == 0) return;
    _mint(addr, amount);
  }

  /// @notice FUR can be spent by Furballs, or by the LootEngine (shopping, in the future)
  function spend(address addr, uint256 amount) external gameModerators {
    _burn(addr, amount);
  }

  /// @notice Increases balance in bulk
  function gift(address[] calldata tos, uint256[] calldata amounts) external gameModerators {
    for (uint i=0; i<tos.length; i++) {
      _mint(tos[i], amounts[i]);
    }
  }

  /// @notice Pay any necessary fees to mint a furball
  /// @dev Delegated logic from Furballs;
  function purchaseMint(
    address from, uint8 permissions, address to, IFurballEdition edition
  ) external gameAdmin returns (bool) {
    require(edition.maxMintable(to) > 0, "LIVE");
    uint32 cnt = edition.count();

    uint32 adoptable = edition.maxAdoptable();
    bool requiresPurchase = cnt >= adoptable;

    if (requiresPurchase) {
      // _gift will throw if cannot gift or cannot afford cost
      _gift(from, permissions, to, edition.purchaseFur());
    }
    return requiresPurchase;
  }

  /// @notice Attempts to purchase an upgrade for a loot item
  /// @dev Delegated logic from Furballs
  function purchaseUpgrade(
    FurLib.RewardModifiers memory modifiers,
    address from, uint8 permissions, uint256 tokenId, uint128 lootId, uint8 chances
  ) external gameAdmin returns(uint128) {
    address owner = furballs.ownerOf(tokenId);

    // _gift will throw if cannot gift or cannot afford cost
    _gift(from, permissions, owner, 500 * uint256(chances));

    return furballs.engine().upgradeLoot(modifiers, owner, lootId, chances);
  }

  /// @notice Attempts to purchase a snack using templates found in the engine
  /// @dev Delegated logic from Furballs
  function purchaseSnack(
    address from, uint8 permissions, uint256 tokenId, uint32 snackId, uint16 count
  ) external gameAdmin {
    FurLib.Snack memory snack = furballs.engine().getSnack(snackId);
    require(snack.count > 0, "COUNT");
    require(snack.fed == 0, "FED");

    // _gift will throw if cannot gift or cannot afford costQ
    _gift(from, permissions, furballs.ownerOf(tokenId), snack.furCost * count);

    furballs.engine().snacks().giveSnack(tokenId, snackId, count);
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  /// @notice Enforces (requires) only admins/game may give gifts
  /// @param to Whom is this being sent to?
  /// @return If this is a gift or not.
  function _gift(address from, uint8 permissions, address to, uint256 furCost) internal returns(bool) {
    bool isGift = to != from;

    // Only admins or game engine can send gifts (to != self), which are always free.
    require(!isGift || permissions >= FurLib.PERMISSION_ADMIN, "GIFT");

    if (!isGift && furCost > 0) {
      _burn(from, furCost);
    }

    return isGift;
  }
}
