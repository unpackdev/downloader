//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./INafta.sol";
import "./IFlashNFTReceiver.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";

contract Nafta is INafta, ERC721, ERC721Holder, Ownable {
  // WETH9 address
  IERC20 immutable WETH9;

  /// @dev mapping from token contract to token id to token details/vault
  mapping(address => mapping(uint256 => PoolNFT)) internal _poolNFTs;

  /// @dev mapping of earnings of each user of the pool (in WETH9)
  mapping(address => uint256) public earnings;

  /// @dev fee taken by pool on each flashloan or flashlong operation
  uint256 public poolFee;
  uint256 public poolFeeChangedAtBlock;
  
  // Newly proposed owner, who will be able to claim the ownership
  address public proposedOwner; 

  // We use a single ERC721 NaftaNFT for both Borrowers and Lenders NFT types.
  // Thus we introduce an ID shift for LenderNFTs type, to distinguish their IDs from BorrowerNFTs
  // So all IDs below 2**32 are BorrowerNFTs, and all above 2**32 are LenderNFTs

  /// @dev keeps track of the next free BorrowerNFT ID (longrent)
  /// @dev is in range 1 to 4 294 967 295 and the ID is used as is in NaftaNFT
  /// @dev 0 is reserved for N/A
  uint256 public borrowerNFTCount = 0;

  /// @dev keeps track of the next free LenderNFT ID (when adding to pool)
  /// @dev is in range 4 294 967 297 to 8 589 934 591 (subtract 2**32 to get actual count)
  /// @dev 4 294 967 296 is reserved for N/A
  uint256 public lenderNFTCount = 2**32;

  constructor(address owner_, IERC20 WETH9_) ERC721("NaftaNFT", "NAFTA") {
    // WETH9 = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    WETH9 = WETH9_;
    Ownable.transferOwnership(owner_);
  }

  /////////////
  // Getters //
  /////////////

  /// @dev poolNFT storage view function
  /// @param nftAddress Address of the NFT contract
  /// @param nftId NFT ID
  function poolNFTs(address nftAddress, uint256 nftId) external view override returns (PoolNFT memory nft) {
    nft = _poolNFTs[nftAddress][nftId];
  }

  ////////////////////
  // Pool functions //
  ////////////////////

  /// @dev Add your NFT to the pool
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to add
  /// @param flashFee - The fee user has to pay for a single rent (in WETH9) [Range: 1gwei-1099.51163 ETH]
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not renting longterm) [Range: 1gwei-1099.51163 ETH, or 0]
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent [Range: 0-16777216]
  function addNFT(address nftAddress, uint256 nftId, uint256 flashFee, uint256 pricePerBlock, uint256 maxLongtermBlocks) external {
    // Verify that NFT isn't already in the pool
    require(_poolNFTs[nftAddress][nftId].lenderNFTId == 0, "NFT is already in the Pool");

    // Pull the NFT from the msg.sender using transferFrom
    IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), nftId);

    uint256 newNFTId = lenderNFTCount + 1;
    lenderNFTCount = newNFTId;

    // Store newly added NFT renting parameters after packing to struct
    _poolNFTs[nftAddress][nftId] = fromBigPoolNFT(
             // (flashFee, pricePerBlock, maxLongtermBlocks, inLongtermTillBlock, borrowerNFTId, lenderNFTId)
      BigPoolNFT(flashFee, pricePerBlock, maxLongtermBlocks, 0,                   0,             newNFTId)
    );

    // Mint a new LenderNFT to msg.sender
    _safeMint(msg.sender, newNFTId);

    // Emit AddNFT event
    emit AddNFT(nftAddress, nftId, flashFee, pricePerBlock, maxLongtermBlocks, newNFTId, msg.sender);
  }

  /// @dev Edit your NFT prices
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you have in the pool
  /// @param flashFee - The fee user has to pay for a single rent (in WETH9) [Range: 1gwei-1099.51163 ETH]
  /// @param pricePerBlock - If renting longterm - this is the price per block (0 if not renting longterm) [Range: 1gwei-1099.51163 ETH, or 0]
  /// @param maxLongtermBlocks - Maximum amount of blocks for longterm rent [Range: 0-16777216]
  function editNFT(address nftAddress, uint256 nftId, uint256 flashFee, uint256 pricePerBlock, uint256 maxLongtermBlocks) external {
    BigPoolNFT memory bigPoolNFT = toBigPoolNFT(_poolNFTs[nftAddress][nftId]);

    // Verify that msg.sender is stored as an owner of this NFT
    require(ownerOf(bigPoolNFT.lenderNFTId) == msg.sender, "Only owner of the corresponding LenderNFT can call this");

    // Update parameters: flashFee, pricePerBlock, maxLongtermBlocks
    bigPoolNFT.flashFee = flashFee;
    bigPoolNFT.pricePerBlock = pricePerBlock;
    bigPoolNFT.maxLongtermBlocks = maxLongtermBlocks;

    // Save the updated NFT back to storage after packing
    _poolNFTs[nftAddress][nftId] = fromBigPoolNFT(bigPoolNFT);

    // Emit EditNFT event
    emit EditNFT(nftAddress, nftId, flashFee, pricePerBlock, maxLongtermBlocks, bigPoolNFT.lenderNFTId, msg.sender);
  }

  /// @dev Remove your NFT from the pool with earnings
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to remove
  function removeNFT(address nftAddress, uint256 nftId) external {
    BigPoolNFT memory bigPoolNFT = toBigPoolNFT(_poolNFTs[nftAddress][nftId]);

    // Verify that msg.sender is stored as an owner of this NFT
    require(ownerOf(bigPoolNFT.lenderNFTId) == msg.sender, "Only owner of the corresponding LenderNFT can call this");
    // Verify that it's not rented in longterm right now
    require(bigPoolNFT.inLongtermTillBlock < block.number, "Can't remove NFT from the pool while in longterm rent");
    // If it's not rented longterm - update longterm rent and burn if needed
    actualizeLongterm(nftAddress, nftId);

    // Zero the storage of this NFT in the pool and burn the NFT
    delete _poolNFTs[nftAddress][nftId];
    _burn(bigPoolNFT.lenderNFTId);

    // Push the NFT to msg.sender
    IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, nftId);

    // Emit RemoveNFT event
    emit RemoveNFT(nftAddress, nftId, bigPoolNFT.lenderNFTId, msg.sender);
  }

  /// @dev Withdraw the earnings of your NFT
  function withdrawEarnings() external override {
    uint256 transferAmount = earnings[msg.sender];

    // Verify that earnings > 0
    require(transferAmount > 0, "No earnings to withdraw");

    // Save and reset earnings before transfer
    earnings[msg.sender] = 0;

    // Push the WETH9 earnings associated with this NFT to msg.sender (we already verified above that msg.sender == owner)
    require(WETH9.transfer(msg.sender, transferAmount), "WETH9 transfer failed");

    // Emit withdraw event
    emit WithdrawEarnings(transferAmount, msg.sender);
  }

  /// @dev Execute a Flashloan of NFT
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to flashloan
  /// @param maxLoanPrice - Price the user is willing to pay for the flashloan
  /// @param receiverAddress - the contract that will receive the NFT (has to implement INFTFlashLoanReceiver interface)
  /// @param data - calldata that will be passed to the receiver contract (optional)
  function flashloan(address nftAddress, uint256 nftId, uint256 maxLoanPrice, address receiverAddress, bytes calldata data) external {
    // Verify that this NFT still exists in the pool
    require(IERC721(nftAddress).ownerOf(nftId) == address(this), "NFT should be in the pool");

    // Update longterm rent parameters
    actualizeLongterm(nftAddress, nftId);

    BigPoolNFT memory bigPoolNFT = toBigPoolNFT(_poolNFTs[nftAddress][nftId]);

    // Is this NFT already in a longterm rent?
    bool longterm = bigPoolNFT.inLongtermTillBlock >= block.number;

    // If this NFT is in a longterm rent right now - check if the msg.sender has the BorrowerNFT
    if (longterm) {
      require(
        ownerOf(bigPoolNFT.borrowerNFTId) == msg.sender,
        "This NFT is in longterm rent - you can't flashloan it unless you have corresponding BorrowerNFT"
      );
    }

    uint256 lenderFees = longterm ? 0 : bigPoolNFT.flashFee;

    require(lenderFees <= maxLoanPrice, "You can't take the flashloan for the indicated price");

    // Initialize the Receiver with IFlashNFTReceiver
    IFlashNFTReceiver receiver = IFlashNFTReceiver(receiverAddress);

    // Push the NFT to Receiver
    IERC721(nftAddress).safeTransferFrom(address(this), receiverAddress, nftId);

    require(
      receiver.executeOperation(nftAddress, nftId, lenderFees, msg.sender, data),
      "Error during FlashNFT Execution"
    );

    // Pull the NFT back from Receiver (will revert if not possible)
    IERC721(nftAddress).safeTransferFrom(receiverAddress, address(this), nftId);

    // Pull the flashFee fee from Receiver (will revert if not possible)
    require(
      longterm ||
      WETH9.transferFrom(msg.sender, address(this), lenderFees),
      "Can't transfer WETH9 lender fees"
    );

    // Calculate the part of fee that goes to the pool (flashFee * poolFee)
    uint256 poolPart = poolFee * lenderFees / 1e18;

    // Add poolPart to the pool Owner balance if it's more than zero
    if (poolPart > 0) earnings[owner()] += poolPart;

    // Add the received (flashFee - poolPart) to NFT owner's earnings
    earnings[ownerOf(bigPoolNFT.lenderNFTId)] += lenderFees - poolPart;

    // This might be an excess check, because we had a successful "safeTransferFrom" above,
    // but for now - better be safe than sorry.
    require(IERC721(nftAddress).ownerOf(nftId) == address(this), "NFT should be in the pool");

    // Emit a Flashloan event
    emit Flashloan(nftAddress, nftId, lenderFees, msg.sender);
  }

  ///////////////////
  // Longterm rent //
  ///////////////////

  /// @dev Utility function to update the status of longterm rent
  /// @dev Is called in some functions as well as can be called by public
  /// @dev will reset the values and burn the BorrowerNFT if the longterm rent is over
  //
  /// @param nftAddress - The address of NFT contract
  /// @param nftId - ID of the NFT token you want to update
  function actualizeLongterm(address nftAddress, uint256 nftId) public {
    BigPoolNFT memory bigPoolNFT = toBigPoolNFT(_poolNFTs[nftAddress][nftId]);

    if (bigPoolNFT.inLongtermTillBlock > 0 && bigPoolNFT.inLongtermTillBlock < block.number) {
      _burn(bigPoolNFT.borrowerNFTId);

      bigPoolNFT.borrowerNFTId = 0;
      bigPoolNFT.inLongtermTillBlock = 0;

      _poolNFTs[nftAddress][nftId] = fromBigPoolNFT(bigPoolNFT);
    }
  }

  /// @dev You can buy a longterm rent for any NFT and don't pay fees for each use.
  /// @dev Nobody else will be able to use it while your rent lasts (even the original owner!)
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
  ) external {
    BigPoolNFT memory bigPoolNFT = toBigPoolNFT(_poolNFTs[nftAddress][nftId]);

    require(bigPoolNFT.pricePerBlock > 0, "This NFT isn't available for longterm rent");

    require(blocks <= bigPoolNFT.maxLongtermBlocks, "NFT can't be rented for that amount of time");
    // We don't check for (blocks > 0) because we check it with (longtermPayment >= bigPoolNFT.flashFee) below

    actualizeLongterm(nftAddress, nftId);

    // Check if it's not in longterm rent already
    require(bigPoolNFT.inLongtermTillBlock < block.number, "Can't rent longterm because it's already rented");

    require(bigPoolNFT.pricePerBlock <= maxPricePerBlock, "Can't rent the NFT with the selected price");

    // Set a new blocknumber for longterm rent
    // This shouldn't overflow because we check (blocks <= maxLongtermBlocks) which is 24bit (16 777 215),
    // and inLongtermTillBlock is 32 bit (4 294 967 295).
    // So theoretically this will be allright until block 4278190080 - which is millenias ahead.
    bigPoolNFT.inLongtermTillBlock = block.number + blocks;

    uint256 longtermPayment = blocks * bigPoolNFT.pricePerBlock;

    // Protecting from cheaters who want to rent longterm for 1 block and pay less than a flash loan fee
    require(longtermPayment >= bigPoolNFT.flashFee, "Longterm rent can't be cheaper than flashloan");

    // Pull the money from lender
    require(WETH9.transferFrom(msg.sender, address(this), longtermPayment), "Can't transfer WETH9 lender fees");

    // Calculate the part of fee that goes to the pool (flashFee * poolFee)
    uint256 poolPart = poolFee * longtermPayment / 1e18;

    // Add poolPart to the pool Owner balance if it's more than zero
    if (poolPart > 0) earnings[owner()] += poolPart;

    // Add the rest (flashFee - calculatedPoolFee) to NFT owner's earnings
    earnings[ownerOf(bigPoolNFT.lenderNFTId)] += longtermPayment - poolPart;

    uint256 newNFTId = borrowerNFTCount + 1;
    borrowerNFTCount = newNFTId;

    bigPoolNFT.borrowerNFTId = newNFTId;
    _poolNFTs[nftAddress][nftId] = fromBigPoolNFT(bigPoolNFT);

    _safeMint(receiverAddress, newNFTId);

    emit LongtermRent(nftAddress, nftId, blocks, longtermPayment, newNFTId, msg.sender);
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  /// @dev Change the pool fee (admin only)
  /// @dev Only admin should be able to do that
  /// @dev Only once per block and for 1 percentage point - to prevent frontrunning
  //
  /// @param newPoolFee - The new pool fee value (percentage, where 100% is 1e18)
  function changePoolFee(uint256 newPoolFee) external onlyOwner {
    uint256 diff = newPoolFee > poolFee ? (newPoolFee - poolFee) : (poolFee - newPoolFee);
    require(diff <= 1e16, "Can't change the pool fee more than one percentage point in one step");
    require(block.number != poolFeeChangedAtBlock, "Can't change the pool fee more than once in a block");
    poolFee = newPoolFee;
    poolFeeChangedAtBlock = block.number;
    emit PoolFeeChanged(newPoolFee);
  }

  /// @dev Propose a new owner, who will be able to claim ownership over this contract
  /// @param newOwner New owner who will be able to claim ownership over this contract
  function proposeNewOwner(address newOwner) external onlyOwner {
    proposedOwner = newOwner;
  }

  /// @dev Claims the ownership of the contract if msg.sender is proposedOwner
  function claimOwnership() external {
    require(msg.sender == proposedOwner, "Only proposed owner can claim the ownership");
    Ownable._transferOwnership(msg.sender);
  }

  ///////////////////////
  // Utility Functions //
  ///////////////////////

  /// @dev Converts packed PoolNFT struct to unpacked BigPoolNFT struct (uint256)
  /// @param poolNFT packed PoolNFT struct
  /// @return unpacked BigPoolNFT struct
  function toBigPoolNFT(PoolNFT memory poolNFT) public pure returns (BigPoolNFT memory) {
    return BigPoolNFT(
      uint256(poolNFT.flashFee),
      uint256(poolNFT.pricePerBlock),
      uint256(poolNFT.maxLongtermBlocks),
      uint256(poolNFT.inLongtermTillBlock),
      uint256(poolNFT.borrowerNFTId),
      uint256(poolNFT.lenderNFTId) + 2**32
    );
  }

  /// @dev Converts unpacked BigPoolNFT struct (uint256) to packed PoolNFT struct
  /// @param bigPoolNFT unpacked BigPoolNFT struct
  /// @return packed PoolNFT struct
  function fromBigPoolNFT(BigPoolNFT memory bigPoolNFT) public pure returns (PoolNFT memory) {
    // Check for overflows before downcasting (yes, Solidity 0.8 still doesn't revert during downcast!)
    require(bigPoolNFT.flashFee <= type(uint72).max, "flashFee doesn't fit in uint72");
    require(bigPoolNFT.pricePerBlock <= type(uint72).max, "pricePerBlock doesn't fit in uint72");
    require(bigPoolNFT.maxLongtermBlocks <= type(uint24).max, "maxLongtermBlocks doesn't fit in uint24");
    require(bigPoolNFT.inLongtermTillBlock <= type(uint32).max, "inLongtermTillBlock doesn't fit in uint32");
    require(bigPoolNFT.borrowerNFTId <= type(uint32).max, "borrowerNFTId doesn't fit in uint32");
    require(bigPoolNFT.lenderNFTId - 2**32 <= type(uint32).max, "lenderNFTId doesn't fit in uint32");

    return PoolNFT(
      uint72(bigPoolNFT.flashFee),
      uint72(bigPoolNFT.pricePerBlock),
      uint24(bigPoolNFT.maxLongtermBlocks),
      uint32(bigPoolNFT.inLongtermTillBlock),
      uint32(bigPoolNFT.borrowerNFTId),
      uint32(bigPoolNFT.lenderNFTId - 2**32)
    );
  }

}
