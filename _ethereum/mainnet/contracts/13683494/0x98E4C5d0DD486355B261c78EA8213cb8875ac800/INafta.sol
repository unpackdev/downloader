//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface INafta {
  event AddNFT(address nftAddress, uint256 nftId, uint256 flashFee, uint256 pricePerBlock, uint256 maxLongtermBlocks, uint256 lenderNFTId, address msgSender);
  event EditNFT(address nftAddress, uint256 nftId, uint256 flashFee, uint256 pricePerBlock, uint256 maxLongtermBlocks, uint256 lenderNFTId, address msgSender);
  event RemoveNFT(address nftAddress, uint256 nftId, uint256 lenderNFTId, address msgSender);
  event WithdrawEarnings(uint256 earnings, address msgSender);
  event Flashloan(address nftAddress, uint256 nftId, uint256 earnedFees, address msgSender);
  event PoolFeeChanged(uint256 newPoolFee);
  event LongtermRent(address nftAddress, uint256 nftId, uint256 blocks, uint256 earnedFees, uint256 borrowerNFTId, address msgSender);

  // NFT Struct in the Pool (optimized to fit within 256 bits)
  struct PoolNFT {
    uint72 flashFee;            // 72 bit - up to 4722.36648 ETH      // fee for a single rent in WETH,
    uint72 pricePerBlock;       // 72 bit - up to 4722.36648 ETH      // price per block of longterm rent (0 if not available)
    uint24 maxLongtermBlocks;   // 24 bit - up to 16 777 215 blocks   // maximum amount of blocks for longterm rent (0 if not available)
    uint32 inLongtermTillBlock; // 32 bit - up to block 4 294 967 295 // This NFT is in longterm rent till this block
    uint32 borrowerNFTId;       // 32 bit - up to ID 4 294 967 296    // ID of BorrowerNFT
    uint32 lenderNFTId;         // 32 bit - up to ID 4 294 967 296    // ID of LenderNFT (subtracted 2**32 to fit)
  }

  // BIG NFT Struct in the Pool (all values converted to uin256 for the ease of use)
  struct BigPoolNFT {
    uint256 flashFee;            // originally 72 bit - up to 4722.36648 ETH      // fee for a single rent in WETH,
    uint256 pricePerBlock;       // originally 72 bit - up to 4722.36648 ETH      // price per block of longterm rent (0 if not available)
    uint256 maxLongtermBlocks;   // originally 24 bit - up to 16 777 215 blocks   // maximum amount of blocks for longterm rent (0 if not available)
    uint256 inLongtermTillBlock; // originally 32 bit - up to block 4 294 967 295 // This NFT is in longterm rent till this block
    uint256 borrowerNFTId;       // originally 32 bit - up to ID 4 294 967 296    // ID of BorrowerNFT
    uint256 lenderNFTId;         // originally 32 bit - up to ID 4 294 967 296    // ID of LenderNFT (add 2**32 to separate from BorrowerNFT)
  }

  // Getters
  function earnings(address userAddress) external returns (uint256);

  function poolNFTs(address nftAddress, uint256 nftId) external view returns (PoolNFT memory nft);

  function poolFee() external view returns (uint256 poolFee);
  function poolFeeChangedAtBlock() external view returns(uint256 poolFeeChangedAtBlock);

  function proposedOwner() external view returns(address proposedOwner);

  function borrowerNFTCount() external view returns (uint256 borrowerNFTCount);
  function lenderNFTCount() external view returns (uint256 lenderNFTCount);

  ////////////////////
  // Pool functions //
  ////////////////////

  /// @dev Add your NFT to the pool
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to add
  /// @param flashFee - The fee user has to pay for a single rent (in WETH)
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not renting longterm)
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent
  function addNFT(
    address nftAddress,
    uint256 nftId,
    uint256 flashFee,
    uint256 pricePerBlock,
    uint256 maxLongtermBlocks
  ) external;

  /// @dev Edit your NFT prices
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you have in the pool
  /// @param flashFee - The fee user has to pay for a single rent (in WETH)
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not renting longterm)
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent
  function editNFT(
    address nftAddress,
    uint256 nftId,
    uint256 flashFee,
    uint256 pricePerBlock,
    uint256 maxLongtermBlocks
  ) external;

  /// @dev Remove your NFT from the pool with earnings
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to remove
  function removeNFT(address nftAddress, uint256 nftId) external;

  /// @dev Withdraw your earnings
  function withdrawEarnings() external;

  /// @dev Execute a Flashloan of NFT
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to flashloan
  /// @param maxLoanPrice - Price the user is willing to pay for the flashloan
  /// @param receiverAddress - the contract that will receive the NFT (has to implement INFTFlashLoanReceiver interface)
  /// @param data - calldata that will be passed to the receiver contract (optional)
  function flashloan(
    address nftAddress,
    uint256 nftId,
    uint256 maxLoanPrice,
    address receiverAddress,
    bytes calldata data
  ) external;

  ///////////////
  // Flashlong //
  ///////////////

  /// @dev Utility function to update the status of longterm rent
  /// @dev Is called in some functions as well as can be called by public
  /// @dev will burn the BorrowerNFT if the longterm rent is over
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to update
  function actualizeLongterm(address nftAddress, uint256 nftId) external;

  /// @dev You can buy a longterm rent for any NFT and don't pay fees for each use, and nobody else will be able to lend it while your rent lasts
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to rent
  /// @param maxPricePerBlock - Price the user is willing to pay per block for renting the NFT
  /// @param receiverAddress - Who will receive the longterm rent BorrowerNFT
  /// @param blocks - How many blocks you want to rent (price is calculated per-block)
  function lendLong(
    address nftAddress,
    uint256 nftId,
    uint256 maxPricePerBlock,
    address receiverAddress,
    uint256 blocks
  ) external;

  /////////////////////
  // Admin Functions //
  /////////////////////

  /// @dev Change the pool fee (admin only)
  /// @dev Only admin should be able to do that
  //
  /// @param newPoolFee - The new pool fee value (percentage)
  function changePoolFee(uint256 newPoolFee) external;

  /// @dev Propose a new owner, who will be able to claim ownership over this contract
  /// @param newOwner New owner who will be able to claim ownership over this contract
  function proposeNewOwner(address newOwner) external;

  /// @dev Claims the ownership of the contract if msg.sender is proposedOwner
  function claimOwnership() external;
}
