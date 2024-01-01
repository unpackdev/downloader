
// File: contracts/libs/SafeTransferLib.sol


pragma solidity >=0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for gas griefing protection.
/// - For ERC20s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    ///
    /// Note: This implementation does NOT protect against gas griefing.
    /// Please use `forceSafeTransferETH` for gas griefing protection.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overridden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // To coerce gas estimation to provide enough gas for the `create` above.
                    if iszero(gt(gas(), 1000000)) { revert(0, 0) }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x60.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/ArtMarketplace.sol


pragma solidity ^0.8.21;



contract ArtMarketplace is Ownable {
  uint256 private constant BPS = 10_000;
  uint256 private constant BID_INCREASE_THRESHOLD = 0.2 ether;
  uint256 private constant DEFAULT_SPLIT = 7_500;
  uint256 private constant EXTENSION_TIME = 10 minutes;
  uint256 private constant INIT_AUCTION_DURATION = 24 hours;
  uint256 private constant MIN_BID = 0.01 ether;
  uint256 private constant MIN_BID_INCREASE_PRE = 2_000;
  uint256 private constant MIN_BID_INCREASE_POST = 1_000;
  uint256 private constant SAFE_GAS_LIMIT = 30_000;

  address public beneficiary;
  bool public paused;

  struct Auction {
    uint24 offsetFromEnd;
    uint72 amount;
    address bidder;
  }

  struct AuctionConfig {
    address artist;
    uint16 split;
    uint80 buyNowStartTime;
    uint80 auctionStartTime;
    uint88 buyNowPrice;
    uint88 reservePrice;
  }

  mapping(uint256 => AuctionConfig) public auctionConfig;
  mapping(uint256 => Auction) public auctionIdToAuction;
  
  event BidMade(
    uint256 indexed auctionId,
    address indexed collectionAddress,
    uint256 indexed tokenId,
    address bidder,
    uint256 amount,
    uint256 timestamp
  );

  event Settled(
    uint256 indexed auctionId,
    address indexed collectionAddress,
    uint256 indexed tokenId,
    uint256 timestamp
  );

  function bid(
    uint256 auctionId
  ) external payable {
    require(!paused, 'Bidding is paused');

    if (auctionConfig[auctionId].auctionStartTime == type(uint80).max) {
      auctionConfig[auctionId].auctionStartTime = uint80(block.timestamp);
    }

    require(
      isAuctionActive(auctionId)
      && block.timestamp >= auctionConfig[auctionId].buyNowStartTime,
      'Auction Inactive'
    );

    Auction memory highestBid = auctionIdToAuction[auctionId];
    uint256 bidIncrease = highestBid.amount >= BID_INCREASE_THRESHOLD
      ? MIN_BID_INCREASE_POST : MIN_BID_INCREASE_PRE;

    require(
      msg.value >= (highestBid.amount * (BPS + bidIncrease) / BPS)
      && msg.value >= reservePrice(auctionId),
      'Bid not high enough'
    );

    uint256 refundAmount;
    address refundBidder;
    uint256 offset = highestBid.offsetFromEnd;
    uint256 endTime = getAuctionEndTime(auctionId);

    if (highestBid.amount > 0) {
      refundAmount = highestBid.amount;
      refundBidder = highestBid.bidder;
    }

    if (endTime - block.timestamp < EXTENSION_TIME) {
      offset += block.timestamp + EXTENSION_TIME - endTime;
    }

    auctionIdToAuction[auctionId] = Auction(uint24(offset), uint72(msg.value), msg.sender);

    emit BidMade(
      auctionId,
      getCollectionFromId(auctionId),
      getArtTokenIdFromId(auctionId),
      msg.sender,
      msg.value,
      block.timestamp
    );

    if (refundAmount > 0) {
      SafeTransferLib.forceSafeTransferETH(refundBidder, refundAmount, SAFE_GAS_LIMIT);
    }
  }

  function bidOnFavs(
    uint256[] calldata favorites,
    uint256[] calldata expectedPrices
  ) external payable {
    require(!paused, 'Bidding is paused');
    require(favorites.length == expectedPrices.length);

    uint256 totalFailed; uint256 expectedTotal;
    for(uint256 i; i < favorites.length; ++i) {
      uint256 auctionId = favorites[i];
      uint256 expectedPrice = expectedPrices[i];
      expectedTotal += expectedPrice;
      AuctionConfig memory config = auctionConfig[auctionId];

      if (config.auctionStartTime == type(uint80).max) {
        auctionConfig[auctionId].auctionStartTime = uint80(block.timestamp);
      }

      if(!isAuctionActive(auctionId) || block.timestamp < config.buyNowStartTime) {
        totalFailed += expectedPrice;
        continue;
      }

      Auction memory highestBid = auctionIdToAuction[auctionId];
      uint256 bidIncrease = highestBid.amount >= BID_INCREASE_THRESHOLD
        ? MIN_BID_INCREASE_POST : MIN_BID_INCREASE_PRE;

      if (
        expectedPrice >= (highestBid.amount * (BPS + bidIncrease) / BPS)
        && expectedPrice >= reservePrice(auctionId)
      ) {
        uint256 refundAmount;
        address refundBidder;
        uint256 offset = highestBid.offsetFromEnd;
        uint256 endTime = getAuctionEndTime(auctionId);

        if (highestBid.amount > 0) {
          refundAmount = highestBid.amount;
          refundBidder = highestBid.bidder;
        }

        if (endTime - block.timestamp < EXTENSION_TIME) {
          offset += block.timestamp + EXTENSION_TIME - endTime;
        }

        auctionIdToAuction[auctionId] = Auction(uint24(offset), uint72(expectedPrice), msg.sender);

        emit BidMade(
          auctionId,
          getCollectionFromId(auctionId),
          getArtTokenIdFromId(auctionId),
          msg.sender,
          expectedPrice,
          block.timestamp
        );

        if (refundAmount > 0) {
          SafeTransferLib.forceSafeTransferETH(refundBidder, refundAmount, SAFE_GAS_LIMIT);
        }
      } else{
        totalFailed += expectedPrice;
      }
    }

    require(msg.value == expectedTotal, 'Incorrect amount of ETH sent');
    if (totalFailed > 0) {
      SafeTransferLib.forceSafeTransferETH(msg.sender, totalFailed, SAFE_GAS_LIMIT);
    }
  }

  function buyNow(
    uint256 auctionId
  ) external payable {
    AuctionConfig memory config = auctionConfig[auctionId];
    uint256 amountToPay = config.buyNowPrice;
    require(!paused, 'Buying is paused');
    require(block.timestamp >= config.buyNowStartTime, 'Can not buy now yet.');
    require(config.auctionStartTime > block.timestamp, 'Auction already started.');
    require(amountToPay != 0 && msg.value == amountToPay, 'Incorrect ETH sent.');

    auctionConfig[auctionId].auctionStartTime = uint80(block.timestamp - INIT_AUCTION_DURATION);
    auctionIdToAuction[auctionId] = Auction(0, uint72(msg.value), msg.sender);
    _mint(msg.sender, auctionId);

    emit Settled(
      auctionId,
      getCollectionFromId(auctionId),
      getArtTokenIdFromId(auctionId),
      block.timestamp
    );

    uint256 split = config.split;
    if (split == 0) {
      split = DEFAULT_SPLIT;
    }
    uint256 amountForArtist = amountToPay * split / 10_000;
    SafeTransferLib.forceSafeTransferETH(config.artist, amountForArtist, SAFE_GAS_LIMIT);
    SafeTransferLib.forceSafeTransferETH(beneficiary, amountToPay - amountForArtist, SAFE_GAS_LIMIT);
  }

  function buyNowMultiple(
    uint256[] calldata auctionIds
  ) external payable {
    require(!paused, 'Buying is paused');

    uint256 totalFailed; uint256 totalPrice;
    for(uint256 i; i < auctionIds.length; ++i) {
      uint256 auctionId = auctionIds[i];
      AuctionConfig memory config = auctionConfig[auctionId];
      uint256 amountToPay = config.buyNowPrice;

      if (
        (block.timestamp < config.buyNowStartTime)
        ||(config.auctionStartTime <= block.timestamp)
        || amountToPay == 0
      ) {
        totalFailed += amountToPay;
        continue;
      }

      auctionConfig[auctionId].auctionStartTime = uint80(block.timestamp - INIT_AUCTION_DURATION);
      auctionIdToAuction[auctionId] = Auction(0, uint72(amountToPay), msg.sender);
      totalPrice += amountToPay;
      _mint(msg.sender, auctionId);

      emit Settled(
        auctionId,
        getCollectionFromId(auctionId),
        getArtTokenIdFromId(auctionId),
        block.timestamp
      );

      uint256 split = config.split;
      if (split == 0) {
        split = DEFAULT_SPLIT;
      }
      uint256 amountForArtist = amountToPay * split / 10_000;
      SafeTransferLib.forceSafeTransferETH(config.artist, amountForArtist, SAFE_GAS_LIMIT);
      SafeTransferLib.forceSafeTransferETH(beneficiary, amountToPay - amountForArtist, SAFE_GAS_LIMIT);
    }

    require(totalPrice == msg.value, 'Incorrect ETH amount sent.');
    if (totalFailed > 0) {
      SafeTransferLib.forceSafeTransferETH(msg.sender, totalFailed, SAFE_GAS_LIMIT);
    }
  }

  function settleAuction(
    uint256 auctionId
  ) external payable {
    Auction memory highestBid = auctionIdToAuction[auctionId];
    AuctionConfig memory config = auctionConfig[auctionId];
    require(isAuctionOver(auctionId), 'Auction is still active');

    uint256 amountToPay = highestBid.amount;
    if (amountToPay > 0) {
      _mint(highestBid.bidder, auctionId);
    } else {
      require(msg.value == reservePrice(auctionId), 'Incorrect funds sent for unclaimed');
      amountToPay = msg.value;

      _mint(owner(), auctionId);
    }

    emit Settled(
      auctionId,
      getCollectionFromId(auctionId),
      getArtTokenIdFromId(auctionId),
      block.timestamp
    );

    uint256 split = config.split;
    if (split == 0) {
      split = DEFAULT_SPLIT;
    }
    uint256 amountForArtist = amountToPay * split / 10_000;
    SafeTransferLib.forceSafeTransferETH(config.artist, amountForArtist, SAFE_GAS_LIMIT);
    SafeTransferLib.forceSafeTransferETH(beneficiary, amountToPay - amountForArtist, SAFE_GAS_LIMIT);
  }

  function settleMultipleAuctions(
    uint256[] calldata auctionIds
  ) external payable {
    uint256 unclaimedCost; uint256 amountForBene;
    for (uint256 i; i < auctionIds.length; ++i) {
      uint256 auctionId = auctionIds[i];
      Auction memory highestBid = auctionIdToAuction[auctionId];
      require(isAuctionOver(auctionId), 'Auction is still active');

      uint256 amountToPay = highestBid.amount;
      if (amountToPay > 0) {
        _mint(highestBid.bidder, auctionId);
      } else {
        amountToPay = reservePrice(auctionId);
        unclaimedCost += amountToPay;
        _mint(owner(), auctionId);
      }

      emit Settled(
        auctionId,
        getCollectionFromId(auctionId),
        getArtTokenIdFromId(auctionId),
        block.timestamp
      );

      AuctionConfig memory config = auctionConfig[auctionId];
      uint256 split = config.split;
      if (split == 0) {
        split = DEFAULT_SPLIT;
      }
      uint256 amountForArtist = amountToPay * split / 10_000;
      SafeTransferLib.forceSafeTransferETH(config.artist, amountForArtist, SAFE_GAS_LIMIT);

      amountForBene += amountToPay - amountForArtist;
    }

    require(msg.value == unclaimedCost, 'Incorrect funds sent for unclaimed');
    SafeTransferLib.forceSafeTransferETH(beneficiary, amountForBene, SAFE_GAS_LIMIT);
  }

  function _mint(
    address to,
    uint256 auctionId
  ) internal {
    address collection = getCollectionFromId(auctionId);
    uint256 tokenId = getArtTokenIdFromId(auctionId);
    try INFT(collection).ownerOf(tokenId) returns (address _owner) {
      if (_owner == address(0)) {
        INFT(collection).mint(to, tokenId);
      } else {
        INFT(collection).transferFrom(_owner, to, tokenId);
      }
    } catch {
      INFT(collection).mint(to, tokenId);
    }
  }

  function _changePrices(
    address collectionAddress,
    uint256 tokenId,
    uint256 newBuyNowPrice,
    uint256 newReservePrice
  ) internal {
    uint256 auctionId = artTokentoAuctionId(collectionAddress, tokenId);
    require(auctionConfig[auctionId].auctionStartTime > block.timestamp);

    auctionConfig[auctionId].buyNowPrice = uint88(newBuyNowPrice);
    auctionConfig[auctionId].reservePrice = uint88(newReservePrice);
  }

  function _changeSplit(
    address collectionAddress,
    uint256 tokenId,
    address artist,
    uint256 newSplit
  ) internal {
    uint256 auctionId = artTokentoAuctionId(collectionAddress, tokenId);
    if (artist != address(0)) {
      auctionConfig[auctionId].artist = artist;
    }
    auctionConfig[auctionId].split = uint16(newSplit);
  }

  function _reschedule(
    address collectionAddress,
    uint256 tokenId,
    uint256 newBuyNowStartTime,
    uint256 newAuctionStartTime
  ) internal {
    uint256 auctionId = artTokentoAuctionId(collectionAddress, tokenId);
    require(auctionConfig[auctionId].auctionStartTime > block.timestamp);
    require(newBuyNowStartTime <= newAuctionStartTime);

    auctionConfig[auctionId].buyNowStartTime = uint80(newBuyNowStartTime);
    auctionConfig[auctionId].auctionStartTime = uint80(newAuctionStartTime);
  }

  function _schedule(
    address collectionAddress,
    uint256 tokenId,
    uint256 buyNowStartTime,
    uint256 auctionStartTime,
    address artist,
    uint256 split,
    uint256 buyNowPrice,
    uint256 reserve
  ) internal {
    uint256 auctionId = artTokentoAuctionId(collectionAddress, tokenId);
    require(auctionConfig[auctionId].auctionStartTime == 0);

    uint256 adjAucStartTime = auctionStartTime;
    if (adjAucStartTime == 0) {
      adjAucStartTime = type(uint80).max;
    }
    auctionConfig[auctionId] = AuctionConfig(
      artist,
      uint16(split),
      uint80(buyNowStartTime),
      uint80(adjAucStartTime),
      uint88(buyNowPrice),
      uint88(reserve)
    );
  }

  // ONLY OWNER

  function changePrices(
    address collectionAddress,
    uint256 tokenId,
    uint256 newBuyNowPrice,
    uint256 newReservePrice
  ) external onlyOwner {
    _changePrices(collectionAddress, tokenId, newBuyNowPrice, newReservePrice);
  }

  function changePricesMultiple(
    address[] calldata collections,
    uint256[] calldata tokenIds,
    uint256[] calldata newBuyNowPrices,
    uint256[] calldata newReservePrices
  ) external onlyOwner {
    require(
      collections.length == tokenIds.length && tokenIds.length == newBuyNowPrices.length
      && newBuyNowPrices.length == newReservePrices.length,
      'Array length mismatch'
    );
    for(uint256 i; i < collections.length; ++i) {
      _changePrices(collections[i], tokenIds[i], newBuyNowPrices[i], newReservePrices[i]);
    }
  }

  function changeSplit(
    address collectionAddress,
    uint256 tokenId,
    address artist,
    uint256 split
  ) external onlyOwner {
    _changeSplit(collectionAddress, tokenId, artist, split);
  }

  function changeSplitMultiple(
    address[] calldata collections,
    uint256[] calldata tokenIds,
    address[] calldata artists,
    uint256[] calldata splits
  ) external onlyOwner {
    require(
      collections.length == tokenIds.length && tokenIds.length == artists.length
      && artists.length == splits.length,
      'Array length mismatch'
    );
    for(uint256 i; i < collections.length; ++i) {
      _changeSplit(collections[i], tokenIds[i], artists[i], splits[i]);
    }
  }

  function reschedule(
    address collectionAddress,
    uint256 tokenId,
    uint256 newBuyNowStartTime,
    uint256 newAuctionStartTime
  ) external onlyOwner {
    _reschedule(collectionAddress, tokenId, newBuyNowStartTime, newAuctionStartTime);
  }

  function rescheduleMultiple(
    address[] calldata collections,
    uint256[] calldata tokenIds,
    uint256[] calldata newBuyNowStartTimes,
    uint256[] calldata newAuctionStartTimes
  ) external onlyOwner {
    require(
      collections.length == tokenIds.length && tokenIds.length == newBuyNowStartTimes.length
      && newBuyNowStartTimes.length == newAuctionStartTimes.length,
      'Array length mismatch'
    );
    for(uint256 i; i < collections.length; ++i) {
      _reschedule(collections[i], tokenIds[i], newBuyNowStartTimes[i], newAuctionStartTimes[i]);
    }
  }

  function schedule(
    address collectionAddress,
    uint256 tokenId,
    uint256 buyNowStartTime,
    uint256 auctionStartTime,
    address artist,
    uint256 split,
    uint256 buyNowPrice,
    uint256 reserve
  ) external onlyOwner {
    _schedule(
      collectionAddress,
      tokenId,
      buyNowStartTime,
      auctionStartTime,
      artist,
      split,
      buyNowPrice,
      reserve
    );
  }

  function scheduleMultiple(
    address[] calldata collections,
    uint256[] calldata tokenIds,
    uint256[] calldata buyNowStartTimes,
    uint256[] calldata auctionStartTimes,
    address[] calldata artists,
    uint256[] calldata splits,
    uint256[] calldata buyNowPrices,
    uint256[] calldata reservePrices
  ) external onlyOwner {
    require(
      collections.length == tokenIds.length && tokenIds.length == buyNowStartTimes.length &&
      buyNowStartTimes.length == auctionStartTimes.length && auctionStartTimes.length == artists.length
      && artists.length == splits.length && splits.length == buyNowPrices.length &&
      buyNowPrices.length == reservePrices.length,
      'Array length mismatch'
    );
    for(uint256 i; i < collections.length; ++i) {
      _schedule(
        collections[i],
        tokenIds[i],
        buyNowStartTimes[i],
        auctionStartTimes[i],
        artists[i],
        splits[i],
        buyNowPrices[i],
        reservePrices[i]
      );
    }
  }

  function setBeneficiary(
    address _beneficiary
  ) external onlyOwner {
    beneficiary = _beneficiary;
  }

  function setPaused(
    bool _paused
  ) external onlyOwner {
    paused = _paused;
  }

  // GETTERS

  function artTokentoAuctionId(
    address collection,
    uint256 tokenId
  ) public pure returns (uint256) {
    return (uint256(uint160(collection)) << 96) | uint96(tokenId);
  }

  function isAuctionActive(
    uint256 auctionId
  ) public view returns (bool) {
    uint256 startTime = auctionConfig[auctionId].auctionStartTime;
    uint256 endTime = getAuctionEndTime(auctionId);
    return (startTime > 0 && block.timestamp >= startTime && block.timestamp < endTime);
  }

  function isAuctionOver(
    uint256 auctionId
  ) public view returns (bool) {
    uint256 startTime = auctionConfig[auctionId].auctionStartTime;
    uint256 endTime = getAuctionEndTime(auctionId);
    return (startTime > 0 && block.timestamp >= endTime);
  }

  function getAuctionEndTime(
    uint256 auctionId
  ) public view returns (uint256) {
    return auctionConfig[auctionId].auctionStartTime + INIT_AUCTION_DURATION + auctionIdToAuction[auctionId].offsetFromEnd;
  }

  function getAuctionStartTime(
    uint256 auctionId
  ) external view returns (uint256) {
    return auctionConfig[auctionId].auctionStartTime;
  }

  function getCollectionFromId(
    uint256 id
  ) public pure returns (address) {
    return address(uint160(id >> 96));
  }

  function getArtTokenIdFromId(
    uint256 id
  ) public pure returns (uint256) {
    return uint256(uint96(id));
  }

  function reservePrice(
    uint256 auctionId
  ) public view returns (uint256) {
    uint256 reserve = auctionConfig[auctionId].reservePrice;
    return reserve != 0 ? reserve : MIN_BID;
  }
}


interface INFT {
  function mint(address to, uint256 tokenId) external;
  function ownerOf(uint256 tokenId) external view returns (address);
  function transferFrom(address from, address to, uint256 tokenId) external;
}