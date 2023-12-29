// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC721AQueryable.sol";

interface IShikkuboERC721 is IERC721AQueryable {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();

  enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
  }

  struct MintRules {
    uint64 totalSupply;
    uint64 maxPerWallet;
    uint64 freePerWallet;
    uint64 whitelistFreePerWallet;
    uint256 price;
  }

  function totalMinted() external view returns (uint256);

  function numberMinted(address _owner) external view returns (uint256);

  function rarityOf(uint256 _tokenId) external view returns (Rarity);

  function rarityDistribution(Rarity _rarity) external view returns (uint256);
}
