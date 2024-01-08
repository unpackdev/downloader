// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ISipherNFT.sol";


interface ISipherNFTSale {
  struct SaleConfig {
    uint64 whitelistTime;     // time that the owner & whitelisted addresses can start buying
    uint64 publicTime;        // time that other addresses can start buying
    uint64 endTime;           // end time for the sale, only the owner can buy the rest of the supply
    uint64 maxSupply;         // max supply of the nft tokens for this sale round
  }

  struct SaleRecord {
    uint64 totalSold;         // total amount of tokens have been sold
    uint64 ownerBought;       // total amount of tokens that the owner has bought
    uint64 totalWhitelistSold;// total amount of tokens that whitelisted addresses have bought
    uint64 totalPublicSold;   // total amount of tokens that have sold to public
  }

  struct UserRecord {
    uint64 whitelistBought;   // amount of tokens that have bought as a whitelisted address
    uint64 publicBought;      // amount of tokens that have bought as a public address
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   */
  function buy(uint64 amount) external payable;

  /**
   * @dev Roll the final start index of the NFT
   */
  function rollStartIndex() external;

  /**
   * @dev Return the config, with times (t0, t1, t2) and max supply
   */
  function getSaleConfig() external view returns (SaleConfig memory config);

  /**
   * @dev Return the sale record
   */
  function getSaleRecord() external view returns (SaleRecord memory record);

  /**
   * @dev Return the user record
   */
  function getUserRecord(address user) external view returns (UserRecord memory record);

  function merkleRoot() external view returns (bytes32);
  function nft() external view returns (ISipherNFT);
}
