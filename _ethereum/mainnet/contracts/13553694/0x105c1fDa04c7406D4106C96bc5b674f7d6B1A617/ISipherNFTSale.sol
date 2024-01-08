// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ISipherNFT.sol";


interface ISipherNFTSale {
  struct SaleConfig {
    uint64 publicTime;                // time that public sale start
    uint64 publicEndTime;             // time that public sale end
    uint64 privateTime;               // time that private sale start
    uint64 freeMintTime;              // time that free mint for Guildmaster whitelisted addresses start.
    uint64 endTime;                   // end time for the sale, only the owner can buy the rest of the supply
    uint32 maxSupply;                 // max supply of the nft tokens for this sale round
  }

  struct SaleRecord {
    uint32 totalSold;             // total amount of tokens have been sold
    uint32 ownerBought;           // total amount of tokens that the owner has bought
    uint32 totalPublicSold;       // total amount of tokens that have sold to public
    uint32 totalWhitelistSold;    // total amount of tokens that whitelisted addresses have bought
    uint32 totalFreeMintSold;     // total amount of tokens that free minted by whitelisted address
  }

  struct UserRecord {
    uint32 publicBought;      // amount of tokens that have bought as a public address
    uint32 whitelistBought;   // amount of tokens that have bought as a whitelisted address
    uint32 freeMintBought;    // amount of tokens that have bought as free mint by whitelisted address
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   */
  function buy(uint32 amount,uint32 privateCap, uint32 freeMintCap, bytes32[] memory proofs) external payable;

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