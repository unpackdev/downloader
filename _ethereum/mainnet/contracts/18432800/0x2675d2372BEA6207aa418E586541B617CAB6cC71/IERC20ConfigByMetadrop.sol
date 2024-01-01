// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

/**
 *
 * @title IERC20ByMetadrop.sol. Interface for metadrop ERC20 standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.21;

interface IERC20ConfigByMetadrop {
  struct ERC20Config {
    bytes baseParameters;
    bytes supplyParameters;
    bytes taxParameters;
    bytes poolParameters;
  }

  struct ERC20BaseParameters {
    string name;
    string symbol;
    bool addLiquidityOnCreate;
    bool usesDRIPool;
  }

  struct ERC20SupplyParameters {
    uint256 maxSupply;
    uint256 lpSupply;
    uint256 projectSupply;
    uint256 maxTokensPerWallet;
    uint256 maxTokensPerTxn;
    uint256 lpLockupInDays;
    uint256 botProtectionDurationInSeconds;
    address projectSupplyRecipient;
    address projectLPOwner;
    bool burnLPTokens;
  }

  struct ERC20TaxParameters {
    uint256 projectBuyTaxBasisPoints;
    uint256 projectSellTaxBasisPoints;
    uint256 taxSwapThresholdBasisPoints;
    uint256 metadropBuyTaxBasisPoints;
    uint256 metadropSellTaxBasisPoints;
    uint256 metadropTaxPeriodInDays;
    address projectTaxRecipient;
    address metadropTaxRecipient;
  }

  struct ERC20PoolParameters {
    uint256 poolSupply;
    uint256 poolStartDate;
    uint256 poolEndDate;
    uint256 poolVestingInDays;
    uint256 poolMaxETH;
    uint256 poolPerAddressMaxETH;
    uint256 poolMinETH;
    uint256 poolPerTransactionMinETH;
  }
}
