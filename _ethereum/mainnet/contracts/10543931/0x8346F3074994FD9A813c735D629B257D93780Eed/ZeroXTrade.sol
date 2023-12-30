pragma experimental ABIEncoderV2;
pragma solidity 0.5.15;

contract IAugur {
    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function isKnownUniverse(IUniverse _universe) public view returns (bool);
    function trustedCashTransfer(address _from, address _to, uint256 _amount) public returns (bool);
    function isTrustedSender(address _address) public returns (bool);
    function onCategoricalMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, bytes32[] memory _outcomes) public returns (bool);
    function onYesNoMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash) public returns (bool);
    function onScalarMarketCreated(uint256 _endTime, string memory _extraInfo, IMarket _market, address _marketCreator, address _designatedReporter, uint256 _feePerCashInAttoCash, int256[] memory _prices, uint256 _numTicks)  public returns (bool);
    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, address _initialReporter, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] memory _payoutNumerators, string memory _description, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime) public returns (bool);
    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _size, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked, string memory description, uint256[] memory _payoutNumerators, uint256 _currentStake, uint256 _stakeRemaining, uint256 _disputeRound) public returns (bool);
    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] memory _payoutNumerators, uint256 _nextWindowStartTime, uint256 _nextWindowEndTime, bool _pacingOn, uint256 _totalRepStakedInPayout, uint256 _totalRepStakedInMarket, uint256 _disputeRound) public returns (bool);
    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256[] memory _payoutNumerators) public returns (bool);
    function logMarketFinalized(IUniverse _universe, uint256[] memory _winningPayoutNumerators) public returns (bool);
    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool);
    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool);
    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets, uint256 _fees) public returns (bool);
    function logMarketOIChanged(IUniverse _universe, IMarket _market) public returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _sender, address _market, uint256 _outcome, uint256 _numShares, uint256 _numPayoutTokens, uint256 _fees) public returns (bool);
    function logUniverseForked(IMarket _forkingMarket) public returns (bool);
    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logReputationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logReputationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logShareTokensBalanceChanged(address _account, IMarket _market, uint256 _outcome, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logDisputeWindowCreated(IDisputeWindow _disputeWindow, uint256 _id, bool _initial) public returns (bool);
    function logParticipationTokensRedeemed(IUniverse universe, address _sender, uint256 _attoParticipationTokens, uint256 _feePayoutShare) public returns (bool);
    function logTimestampSet(uint256 _newTimestamp) public returns (bool);
    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
    function logParticipationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value, uint256 _fromBalance, uint256 _toBalance) public returns (bool);
    function logParticipationTokensBurned(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logParticipationTokensMinted(IUniverse _universe, address _target, uint256 _amount, uint256 _totalSupply, uint256 _balance) public returns (bool);
    function logMarketRepBondTransferred(address _universe, address _from, address _to) public returns (bool);
    function logWarpSyncDataUpdated(address _universe, uint256 _warpSyncHash, uint256 _marketEndTime) public returns (bool);
    function isKnownFeeSender(address _feeSender) public view returns (bool);
    function lookup(bytes32 _key) public view returns (address);
    function getTimestamp() public view returns (uint256);
    function getMaximumMarketEndDate() public returns (uint256);
    function isKnownMarket(IMarket _market) public view returns (bool);
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators, uint256 _numTicks, uint256 numOutcomes) public view returns (bytes32);
    function logValidityBondChanged(uint256 _validityBond) public returns (bool);
    function logDesignatedReportStakeChanged(uint256 _designatedReportStake) public returns (bool);
    function logNoShowBondChanged(uint256 _noShowBond) public returns (bool);
    function logReportingFeeChanged(uint256 _reportingFee) public returns (bool);
    function getUniverseForkIndex(IUniverse _universe) public view returns (uint256);
}

contract IAugurCreationDataGetter {
    struct MarketCreationData {
        string extraInfo;
        address marketCreator;
        bytes32[] outcomes;
        int256[] displayPrices;
        IMarket.MarketType marketType;
        uint256 recommendedTradeInterval;
    }

    function getMarketCreationData(IMarket _market) public view returns (MarketCreationData memory);
}

contract IAugurMarketDataGetter {
    function getMarketType(IMarket _market) public view returns (IMarket.MarketType _marketType);
    function getMarketOutcomes(IMarket _market) public view returns (bytes32[] memory _outcomes);
    function getMarketRecommendedTradeInterval(IMarket _market) public view returns (uint256);
}

contract IExchange {

    struct FillResults {
        uint256 makerAssetFilledAmount;  // Total amount of makerAsset(s) filled.
        uint256 takerAssetFilledAmount;  // Total amount of takerAsset(s) filled.
        uint256 makerFeePaid;            // Total amount of fees paid by maker(s) to feeRecipient(s).
        uint256 takerFeePaid;            // Total amount of fees paid by taker to feeRecipients(s).
        uint256 protocolFeePaid;         // Total amount of fees paid by taker to the staking contract.
    }

    struct OrderInfo {
        uint8 orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 hash of the order (see LibOrder.getOrderHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }

    // solhint-disable max-line-length
    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee;               // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    function protocolFeeMultiplier() external view returns (uint256);

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return OrderInfo Information about the order and its state.
    ///         See LibOrder.OrderInfo for a complete description.
    function getOrderInfo(Order memory order) public view returns (OrderInfo memory orderInfo);

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param takerAssetFillAmount Desired amount of takerAsset to sell.
    /// @param signature Proof that order has been created by maker.
    /// @return Amounts filled and fees paid by maker and taker.
    function fillOrder(Order memory order, uint256 takerAssetFillAmount, bytes memory signature) public payable returns (FillResults memory fillResults);
}

library ContractExists {
    function exists(address _address) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}

contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address _newOwner) public returns (bool);
}

contract ITyped {
    function getTypeName() public view returns (bytes32);
}

contract Initializable {
    bool private initialized = false;

    modifier beforeInitialized {
        require(!initialized);
        _;
    }

    function endInitialization() internal beforeInitialized {
        initialized = true;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}

library LibBytes {

    using LibBytes for bytes;

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert();
        }
        if (to > b.length) {
            revert();
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert();
        }
        if (to > b.length) {
            revert();
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            revert();
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }
}

library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            uint256 x = (y + 1) / 2;
            z = y;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        // 2 ** 256 - 1
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

interface IERC1155 {

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string value,
        uint256 indexed id
    );

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the total supply of a Token.
    /// @param id     ID of the Token
    /// @return        The total supply of the Token type requested
    function totalSupply(uint256 id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICash is IERC20 {
}

contract IAffiliateValidator {
    function validateReference(address _account, address _referrer) external view returns (bool);
}

contract IDisputeWindow is ITyped, IERC20 {
    function invalidMarketsTotal() external view returns (uint256);
    function validityBondTotal() external view returns (uint256);

    function incorrectDesignatedReportTotal() external view returns (uint256);
    function initialReportBondTotal() external view returns (uint256);

    function designatedReportNoShowsTotal() external view returns (uint256);
    function designatedReporterNoShowBondTotal() external view returns (uint256);

    function initialize(IAugur _augur, IUniverse _universe, uint256 _disputeWindowId, bool _participationTokensEnabled, uint256 _duration, uint256 _startTime) public;
    function trustedBuy(address _buyer, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getStartTime() public view returns (uint256);
    function getEndTime() public view returns (uint256);
    function getWindowId() public view returns (uint256);
    function isActive() public view returns (bool);
    function isOver() public view returns (bool);
    function onMarketFinalized() public;
    function redeem(address _account) public returns (bool);
}

contract IMarket is IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IAugur _augur, IUniverse _universe, uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public;
    function derivePayoutDistributionHash(uint256[] memory _payoutNumerators) public view returns (bytes32);
    function doInitialReport(uint256[] memory _payoutNumerators, string memory _description, uint256 _additionalStake) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getDisputeWindow() public view returns (IDisputeWindow);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
    function getForkingMarket() public view returns (IMarket _market);
    function getEndTime() public view returns (uint256);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningReportingParticipant() public view returns (IReportingParticipant);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporter() public view returns (IInitialReporter);
    function getDesignatedReportingEndTime() public view returns (uint256);
    function getValidityBondAttoCash() public view returns (uint256);
    function affiliateFeeDivisor() external view returns (uint256);
    function getNumParticipants() public view returns (uint256);
    function getDisputePacingOn() public view returns (bool);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function recordMarketCreatorFees(uint256 _marketCreatorFees, address _sourceAccount, bytes32 _fingerprint) public returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isFinalizedAsInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function isFinalized() public view returns (bool);
    function getOpenInterest() public view returns (uint256);
}

contract IReportingParticipant {
    function getStake() public view returns (uint256);
    function getPayoutDistributionHash() public view returns (bytes32);
    function liquidateLosing() public;
    function redeem(address _redeemer) public returns (bool);
    function isDisavowed() public view returns (bool);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getMarket() public view returns (IMarket);
    function getSize() public view returns (uint256);
}

contract IInitialReporter is IReportingParticipant, IOwnable {
    function initialize(IAugur _augur, IMarket _market, address _designatedReporter) public;
    function report(address _reporter, bytes32 _payoutDistributionHash, uint256[] memory _payoutNumerators, uint256 _initialReportStake) public;
    function designatedReporterShowed() public view returns (bool);
    function initialReporterWasCorrect() public view returns (bool);
    function getDesignatedReporter() public view returns (address);
    function getReportTimestamp() public view returns (uint256);
    function migrateToNewUniverse(address _designatedReporter) public;
    function returnRepFromDisavow() public;
}

contract IReputationToken is IERC20 {
    function migrateOutByPayout(uint256[] memory _payoutNumerators, uint256 _attotokens) public returns (bool);
    function migrateIn(address _reporter, uint256 _attotokens) public returns (bool);
    function trustedReportingParticipantTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedMarketTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedUniverseTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedDisputeWindowTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getTotalMigrated() public view returns (uint256);
    function getTotalTheoreticalSupply() public view returns (uint256);
    function mintForReportingParticipant(uint256 _amountMigrated) public returns (bool);
}

contract IShareToken is ITyped, IERC1155 {
    function initialize(IAugur _augur) external;
    function initializeMarket(IMarket _market, uint256 _numOutcomes, uint256 _numTicks) public;
    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) public;
    function unsafeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values) public;
    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (uint256[] memory _outcomeFees);
    function getMarket(uint256 _tokenId) external view returns (IMarket);
    function getOutcome(uint256 _tokenId) external view returns (uint256);
    function getTokenId(IMarket _market, uint256 _outcome) public pure returns (uint256 _tokenId);
    function getTokenIds(IMarket _market, uint256[] memory _outcomes) public pure returns (uint256[] memory _tokenIds);
    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool);
    function buyCompleteSetsForTrade(IMarket _market, uint256 _amount, uint256 _longOutcome, address _longRecipient, address _shortRecipient) external returns (bool);
    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function sellCompleteSetsForTrade(IMarket _market, uint256 _outcome, uint256 _amount, address _shortParticipant, address _longParticipant, address _shortRecipient, address _longRecipient, uint256 _price, address _sourceAccount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    function totalSupplyForMarketOutcome(IMarket _market, uint256 _outcome) public view returns (uint256);
    function balanceOfMarketOutcome(IMarket _market, uint256 _outcome, address _account) public view returns (uint256);
    function lowestBalanceOfMarketOutcomes(IMarket _market, uint256[] memory _outcomes, address _account) public view returns (uint256);
}

contract IUniverse {
    function creationTime() external view returns (uint256);
    function marketBalance(address) external view returns (uint256);

    function fork() public returns (bool);
    function updateForkValues() public returns (bool);
    function getParentUniverse() public view returns (IUniverse);
    function createChildUniverse(uint256[] memory _parentPayoutNumerators) public returns (IUniverse);
    function getChildUniverse(bytes32 _parentPayoutDistributionHash) public view returns (IUniverse);
    function getReputationToken() public view returns (IV2ReputationToken);
    function getForkingMarket() public view returns (IMarket);
    function getForkEndTime() public view returns (uint256);
    function getForkReputationGoal() public view returns (uint256);
    function getParentPayoutDistributionHash() public view returns (bytes32);
    function getDisputeRoundDurationInSeconds(bool _initial) public view returns (uint256);
    function getOrCreateDisputeWindowByTimestamp(uint256 _timestamp, bool _initial) public returns (IDisputeWindow);
    function getOrCreateCurrentDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreateNextDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOrCreatePreviousDisputeWindow(bool _initial) public returns (IDisputeWindow);
    function getOpenInterestInAttoCash() public view returns (uint256);
    function getTargetRepMarketCapInAttoCash() public view returns (uint256);
    function getOrCacheValidityBond() public returns (uint256);
    function getOrCacheDesignatedReportStake() public returns (uint256);
    function getOrCacheDesignatedReportNoShowBond() public returns (uint256);
    function getOrCacheMarketRepBond() public returns (uint256);
    function getOrCacheReportingFeeDivisor() public returns (uint256);
    function getDisputeThresholdForFork() public view returns (uint256);
    function getDisputeThresholdForDisputePacing() public view returns (uint256);
    function getInitialReportMinValue() public view returns (uint256);
    function getPayoutNumerators() public view returns (uint256[] memory);
    function getReportingFeeDivisor() public view returns (uint256);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getWinningChildPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function isOpenInterestCash(address) public view returns (bool);
    function isForkingMarket() public view returns (bool);
    function getCurrentDisputeWindow(bool _initial) public view returns (IDisputeWindow);
    function getDisputeWindowStartTimeAndDuration(uint256 _timestamp, bool _initial) public view returns (uint256, uint256);
    function isParentOf(IUniverse _shadyChild) public view returns (bool);
    function updateTentativeWinningChildUniverse(bytes32 _parentPayoutDistributionHash) public returns (bool);
    function isContainerForDisputeWindow(IDisputeWindow _shadyTarget) public view returns (bool);
    function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function migrateMarketOut(IUniverse _destinationUniverse) public returns (bool);
    function migrateMarketIn(IMarket _market, uint256 _cashBalance, uint256 _marketOI) public returns (bool);
    function decrementOpenInterest(uint256 _amount) public returns (bool);
    function decrementOpenInterestFromMarket(IMarket _market) public returns (bool);
    function incrementOpenInterest(uint256 _amount) public returns (bool);
    function getWinningChildUniverse() public view returns (IUniverse);
    function isForking() public view returns (bool);
    function deposit(address _sender, uint256 _amount, address _market) public returns (bool);
    function withdraw(address _recipient, uint256 _amount, address _market) public returns (bool);
    function createScalarMarket(uint256 _endTime, uint256 _feePerCashInAttoCash, IAffiliateValidator _affiliateValidator, uint256 _affiliateFeeDivisor, address _designatedReporterAddress, int256[] memory _prices, uint256 _numTicks, string memory _extraInfo) public returns (IMarket _newMarket);
}

contract IV2ReputationToken is IReputationToken {
    function parentUniverse() external returns (IUniverse);
    function burnForMarket(uint256 _amountToBurn) public returns (bool);
    function mintForWarpSync(uint256 _amountToMint, address _target) public returns (bool);
}

contract IAugurTrading {
    function lookup(bytes32 _key) public view returns (address);
    function logProfitLossChanged(IMarket _market, address _account, uint256 _outcome, int256 _netPosition, uint256 _avgPrice, int256 _realizedProfit, int256 _frozenFunds, int256 _realizedCost) public returns (bool);
    function logOrderCreated(IUniverse _universe, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool);
    function logOrderCanceled(IUniverse _universe, IMarket _market, address _creator, uint256 _tokenRefund, uint256 _sharesRefund, bytes32 _orderId) public returns (bool);
    function logOrderFilled(IUniverse _universe, address _creator, address _filler, uint256 _price, uint256 _fees, uint256 _amountFilled, bytes32 _orderId, bytes32 _tradeGroupId) public returns (bool);
    function logMarketVolumeChanged(IUniverse _universe, address _market, uint256 _volume, uint256[] memory _outcomeVolumes, uint256 _totalTrades) public returns (bool);
    function logZeroXOrderFilled(IUniverse _universe, IMarket _market, bytes32 _orderHash, bytes32 _tradeGroupId, uint8 _orderType, address[] memory _addressData, uint256[] memory _uint256Data) public returns (bool);
    function logZeroXOrderCanceled(address _universe, address _market, address _account, uint256 _outcome, uint256 _price, uint256 _amount, uint8 _type, bytes32 _orderHash) public;
}

contract IFillOrder {
    function publicFillOrder(bytes32 _orderId, uint256 _amountFillerWants, bytes32 _tradeGroupId, bytes32 _fingerprint) external returns (uint256);
    function fillOrder(address _filler, bytes32 _orderId, uint256 _amountFillerWants, bytes32 tradeGroupId, bytes32 _fingerprint) external returns (uint256);
    function fillZeroXOrder(IMarket _market, uint256 _outcome, uint256 _price, Order.Types _orderType, address _creator, uint256 _amount, bytes32 _fingerprint, bytes32 _tradeGroupId, address _filler) external returns (uint256, uint256);
    function getMarketOutcomeValues(IMarket _market) public view returns (uint256[] memory);
    function getMarketVolume(IMarket _market) public view returns (uint256);
}

contract IOrders {
    function saveOrder(uint256[] calldata _uints, bytes32[] calldata _bytes32s, Order.Types _type, IMarket _market, address _sender) external returns (bytes32 _orderId);
    function removeOrder(bytes32 _orderId) external returns (bool);
    function getMarket(bytes32 _orderId) public view returns (IMarket);
    function getOrderType(bytes32 _orderId) public view returns (Order.Types);
    function getOutcome(bytes32 _orderId) public view returns (uint256);
    function getAmount(bytes32 _orderId) public view returns (uint256);
    function getPrice(bytes32 _orderId) public view returns (uint256);
    function getOrderCreator(bytes32 _orderId) public view returns (address);
    function getOrderSharesEscrowed(bytes32 _orderId) public view returns (uint256);
    function getOrderMoneyEscrowed(bytes32 _orderId) public view returns (uint256);
    function getOrderDataForCancel(bytes32 _orderId) public view returns (uint256, uint256, Order.Types, IMarket, uint256, address);
    function getOrderDataForLogs(bytes32 _orderId) public view returns (Order.Types, address[] memory _addressData, uint256[] memory _uint256Data);
    function getBetterOrderId(bytes32 _orderId) public view returns (bytes32);
    function getWorseOrderId(bytes32 _orderId) public view returns (bytes32);
    function getBestOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getWorstOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getLastOutcomePrice(IMarket _market, uint256 _outcome) public view returns (uint256);
    function getOrderId(Order.Types _type, IMarket _market, uint256 _amount, uint256 _price, address _sender, uint256 _blockNumber, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed) public pure returns (bytes32);
    function getTotalEscrowed(IMarket _market) public view returns (uint256);
    function isBetterPrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function isWorsePrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function assertIsNotBetterPrice(Order.Types _type, uint256 _price, bytes32 _betterOrderId) public view returns (bool);
    function assertIsNotWorsePrice(Order.Types _type, uint256 _price, bytes32 _worseOrderId) public returns (bool);
    function recordFillOrder(bytes32 _orderId, uint256 _sharesFilled, uint256 _tokensFilled, uint256 _fill) external returns (bool);
    function setPrice(IMarket _market, uint256 _outcome, uint256 _price) external returns (bool);
}

contract IZeroXTrade {

    struct AugurOrderData {
        address marketAddress;                  // Market Address
        uint256 price;                          // Price
        uint8 outcome;                          // Outcome
        uint8 orderType;                        // Order Type
    }

    function parseOrderData(IExchange.Order memory _order) public view returns (AugurOrderData memory _data);
    function unpackTokenId(uint256 _tokenId) public pure returns (address _market, uint256 _price, uint8 _outcome, uint8 _type);
}

library Order {
    using SafeMathUint256 for uint256;

    enum Types {
        Bid, Ask
    }

    enum TradeDirections {
        Long, Short
    }

    struct Data {
        // Contracts
        IMarket market;
        IAugur augur;
        IAugurTrading augurTrading;
        IShareToken shareToken;
        ICash cash;

        // Order
        bytes32 id;
        address creator;
        uint256 outcome;
        Order.Types orderType;
        uint256 amount;
        uint256 price;
        uint256 sharesEscrowed;
        uint256 moneyEscrowed;
        bytes32 betterOrderId;
        bytes32 worseOrderId;
    }

    function create(IAugur _augur, IAugurTrading _augurTrading, address _creator, uint256 _outcome, Order.Types _type, uint256 _attoshares, uint256 _price, IMarket _market, bytes32 _betterOrderId, bytes32 _worseOrderId) internal view returns (Data memory) {
        require(_outcome < _market.getNumberOfOutcomes(), "Order.create: Outcome is not within market range");
        require(_price != 0, "Order.create: Price may not be 0");
        require(_price < _market.getNumTicks(), "Order.create: Price is outside of market range");
        require(_attoshares > 0, "Order.create: Cannot use amount of 0");
        require(_creator != address(0), "Order.create: Creator is 0x0");

        IShareToken _shareToken = IShareToken(_augur.lookup("ShareToken"));

        return Data({
            market: _market,
            augur: _augur,
            augurTrading: _augurTrading,
            shareToken: _shareToken,
            cash: ICash(_augur.lookup("Cash")),
            id: 0,
            creator: _creator,
            outcome: _outcome,
            orderType: _type,
            amount: _attoshares,
            price: _price,
            sharesEscrowed: 0,
            moneyEscrowed: 0,
            betterOrderId: _betterOrderId,
            worseOrderId: _worseOrderId
        });
    }

    //
    // "public" functions
    //

    function getOrderId(Order.Data memory _orderData, IOrders _orders) internal view returns (bytes32) {
        if (_orderData.id == bytes32(0)) {
            bytes32 _orderId = calculateOrderId(_orderData.orderType, _orderData.market, _orderData.amount, _orderData.price, _orderData.creator, block.number, _orderData.outcome, _orderData.moneyEscrowed, _orderData.sharesEscrowed);
            require(_orders.getAmount(_orderId) == 0, "Order.getOrderId: New order had amount. This should not be possible");
            _orderData.id = _orderId;
        }
        return _orderData.id;
    }

    function calculateOrderId(Order.Types _type, IMarket _market, uint256 _amount, uint256 _price, address _sender, uint256 _blockNumber, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(_type, _market, _amount, _price, _sender, _blockNumber, _outcome, _moneyEscrowed, _sharesEscrowed));
    }

    function getOrderTradingTypeFromMakerDirection(Order.TradeDirections _creatorDirection) internal pure returns (Order.Types) {
        return (_creatorDirection == Order.TradeDirections.Long) ? Order.Types.Bid : Order.Types.Ask;
    }

    function getOrderTradingTypeFromFillerDirection(Order.TradeDirections _fillerDirection) internal pure returns (Order.Types) {
        return (_fillerDirection == Order.TradeDirections.Long) ? Order.Types.Ask : Order.Types.Bid;
    }

    function saveOrder(Order.Data memory _orderData, bytes32 _tradeGroupId, IOrders _orders) internal returns (bytes32) {
        getOrderId(_orderData, _orders);
        uint256[] memory _uints = new uint256[](5);
        _uints[0] = _orderData.amount;
        _uints[1] = _orderData.price;
        _uints[2] = _orderData.outcome;
        _uints[3] = _orderData.moneyEscrowed;
        _uints[4] = _orderData.sharesEscrowed;
        bytes32[] memory _bytes32s = new bytes32[](4);
        _bytes32s[0] = _orderData.betterOrderId;
        _bytes32s[1] = _orderData.worseOrderId;
        _bytes32s[2] = _tradeGroupId;
        _bytes32s[3] = _orderData.id;
        return _orders.saveOrder(_uints, _bytes32s, _orderData.orderType, _orderData.market, _orderData.creator);
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract ZeroXTrade is Initializable, IZeroXTrade, IERC1155 {
    using SafeMathUint256 for uint256;
    using LibBytes for bytes;

    bool transferFromAllowed = false;

    // ERC20Token(address)
    bytes4 constant private ERC20_PROXY_ID = 0xf47261b0;

    // ERC1155Assets(address,uint256[],uint256[],bytes)
    bytes4 constant private MULTI_ASSET_PROXY_ID = 0x94cfcdd7;

    // ERC1155Assets(address,uint256[],uint256[],bytes)
    bytes4 constant private ERC1155_PROXY_ID = 0xa7cb5fb7;

    // EIP191 header for EIP712 prefix
    string constant internal EIP191_HEADER = "\x19\x01";

    // EIP712 Domain Name value
    string constant internal EIP712_DOMAIN_NAME = "0x Protocol";

    // EIP712 Domain Version value
    string constant internal EIP712_DOMAIN_VERSION = "2";

    // EIP1271 Order With Hash Selector
    bytes4 constant public EIP1271_ORDER_WITH_HASH_SELECTOR = 0x3efe50c8;

    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
        abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "address verifyingContract",
        ")"
    ));

    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(
        abi.encodePacked(
        "Order(",
        "address makerAddress,",
        "address takerAddress,",
        "address feeRecipientAddress,",
        "address senderAddress,",
        "uint256 makerAssetAmount,",
        "uint256 takerAssetAmount,",
        "uint256 makerFee,",
        "uint256 takerFee,",
        "uint256 expirationTimeSeconds,",
        "uint256 salt,",
        "bytes makerAssetData,",
        "bytes takerAssetData",
        "bytes makerFeeAssetData,",
        "bytes takerFeeAssetData",
        ")"
    ));

    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    IAugur public augur;
    IAugurTrading public augurTrading;
    IFillOrder public fillOrder;
    ICash public cash;
    IShareToken public shareToken;
    IExchange public exchange;
    IUniswapV2Pair public ethExchange;
    IWETH public WETH;
    bool public token0IsCash;

    function initialize(IAugur _augur, IAugurTrading _augurTrading) public beforeInitialized {
        endInitialization();
        augur = _augur;
        augurTrading = _augurTrading;
        cash = ICash(_augur.lookup("Cash"));
        require(cash != ICash(0));
        shareToken = IShareToken(_augur.lookup("ShareToken"));
        require(shareToken != IShareToken(0));
        exchange = IExchange(_augurTrading.lookup("ZeroXExchange"));
        require(exchange != IExchange(0));
        fillOrder = IFillOrder(_augurTrading.lookup("FillOrder"));
        require(fillOrder != IFillOrder(0));
        WETH = IWETH(_augurTrading.lookup("WETH9"));
        IUniswapV2Factory _uniswapFactory = IUniswapV2Factory(_augur.lookup("UniswapV2Factory"));
        address _ethExchangeAddress = _uniswapFactory.getPair(address(WETH), address(cash));
        if (_ethExchangeAddress == address(0)) {
            _ethExchangeAddress = _uniswapFactory.createPair(address(WETH), address(cash));
        }
        ethExchange = IUniswapV2Pair(_ethExchangeAddress);
        token0IsCash = ethExchange.token0() == address(cash);

        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                uint256(address(this))
            )
        );
    }

    // ERC1155 Implementation
    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external {
        require(transferFromAllowed);
        emit TransferSingle(msg.sender, from, to, id, value);
    }

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external {
        require(transferFromAllowed);
        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return       The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        (address _market, uint256 _price, uint8 _outcome, uint8 _type) = unpackTokenId(id);
        // NOTE: An invalid order type will cause a failure here. That is malformed input so we don't mind reverting in such a case
        Order.Types _orderType = Order.Types(_type);
        if (_orderType == Order.Types.Ask) {
            return askBalance(owner, IMarket(_market), _outcome, _price);
        } else if (_orderType == Order.Types.Bid) {
            return bidBalance(owner, IMarket(_market), _outcome, _price);
        }
    }

    function totalSupply(uint256 id) external view returns (uint256) {
        return 0;
    }

    function bidBalance(address _owner, IMarket _market, uint8 _outcome, uint256 _price) public view returns (uint256) {
        uint256 _numberOfOutcomes = _market.getNumberOfOutcomes();
        // Figure out how many almost-complete-sets (just missing `outcome` share) the creator has
        uint256[] memory _shortOutcomes = new uint256[](_numberOfOutcomes - 1);
        uint256 _indexOutcome = 0;
        for (uint256 _i = 0; _i < _numberOfOutcomes - 1; _i++) {
            if (_i == _outcome) {
                _indexOutcome++;
            }
            _shortOutcomes[_i] = _indexOutcome;
            _indexOutcome++;
        }

        uint256 _attoSharesOwned = shareToken.lowestBalanceOfMarketOutcomes(_market, _shortOutcomes, _owner);

        uint256 _availableCash = cashAvailableForTransferFrom(_owner, address(fillOrder));
        uint256 _attoSharesPurchasable = _availableCash.div(_price);

        return _attoSharesOwned.add(_attoSharesPurchasable);
    }

    function askBalance(address _owner, IMarket _market, uint8 _outcome, uint256 _price) public view returns (uint256) {
        uint256 _attoSharesOwned = shareToken.balanceOfMarketOutcome(_market, _outcome, _owner);
        uint256 _availableCash = cashAvailableForTransferFrom(_owner, address(fillOrder));
        uint256 _attoSharesPurchasable = _availableCash.div(_market.getNumTicks().sub(_price));

        return _attoSharesOwned.add(_attoSharesPurchasable);
    }

    function cashAvailableForTransferFrom(address _owner, address _sender) public view returns (uint256) {
        uint256 _balance = cash.balanceOf(_owner);
        uint256 _allowance = cash.allowance(_owner, _sender);
        return _balance.min(_allowance);
    }

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances_) {
        balances_ = new uint256[](owners.length);
        for (uint256 _i = 0; _i < owners.length; _i++) {
            balances_[_i] = this.balanceOf(owners[_i], ids[_i]);
        }
    }

    function setApprovalForAll(address operator, bool approved) external {
        revert("Not supported");
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return true;
    }

    // Trade functions

    /**
     * Perform Augur Trades using 0x signed orders
     *
     * @param  _requestedFillAmount  Share amount to fill
     * @param  _fingerprint          Fingerprint of the user to restrict affiliate fees
     * @param  _tradeGroupId         Random id to correlate these fills as one trade action
     * @param  _maxProtocolFeeDai    The maximum amount of DAI to spend on covering the 0x protocol fee
     * @param  _maxTrades            The maximum number of trades to actually take from the provided 0x orders
     * @param  _orders               Array of encoded Order struct data
     * @param  _signatures           Array of signature data
     * @return                       The amount the taker still wants
     */
    function trade(
        uint256 _requestedFillAmount,
        bytes32 _fingerprint,
        bytes32 _tradeGroupId,
        uint256 _maxProtocolFeeDai,
        uint256 _maxTrades,
        IExchange.Order[] memory _orders,
        bytes[] memory _signatures
    )
        public
        payable
        returns (uint256)
    {
        require(_orders.length > 0);
        uint256 _fillAmountRemaining = _requestedFillAmount;

        transferFromAllowed = true;

        uint256 _protocolFee = exchange.protocolFeeMultiplier().mul(tx.gasprice);
        coverProtocolFee(_protocolFee.mul(_maxTrades), _maxProtocolFeeDai);

        // Do the actual asset exchanges
        for (uint256 i = 0; i < _orders.length && _fillAmountRemaining != 0; i++) {
            IExchange.Order memory _order = _orders[i];
            validateOrder(_order, _fillAmountRemaining);

            // Update 0x and pay protocol fee. This will also validate signatures and order state for us.
            IExchange.FillResults memory totalFillResults = fillOrderNoThrow(
                _order,
                _fillAmountRemaining,
                _signatures[i],
                _protocolFee
            );

            if (totalFillResults.takerAssetFilledAmount == 0) {
                continue;
            }

            uint256 _amountTraded = doTrade(_order, totalFillResults.takerAssetFilledAmount, _fingerprint, _tradeGroupId, msg.sender);

            _fillAmountRemaining = _fillAmountRemaining.sub(_amountTraded);
            _maxTrades -= 1;
            if (_maxTrades == 0) {
                break;
            }
        }

        transferFromAllowed = false;

        if (address(this).balance > 0) {
            (bool _success,) = msg.sender.call.value(address(this).balance)("");
            require(_success);
        }

        return _fillAmountRemaining;
    }

    function fillOrderNoThrow(IExchange.Order memory _order, uint256 _takerAssetFillAmount, bytes memory _signature, uint256 _protocolFee) internal returns (IExchange.FillResults memory fillResults) {
        bytes memory fillOrderCalldata = abi.encodeWithSelector(
            IExchange(address(0)).fillOrder.selector,
            _order,
            _takerAssetFillAmount,
            _signature
        );

        (bool _didSucceed, bytes memory _returnData) = address(exchange).call.value(_protocolFee)(fillOrderCalldata);
        if (_didSucceed) {
            assert(_returnData.length == 160);
            fillResults = abi.decode(_returnData, (IExchange.FillResults));
        }
        return fillResults;
    }

    function coverProtocolFee(uint256 _amountEthRequired, uint256 _maxProtocolFeeDai) internal {
        if (address(this).balance < _amountEthRequired) {
            uint256 _ethDeficit = _amountEthRequired - address(this).balance;
            uint256 _cost = getTokenPurchaseCost(_ethDeficit);
            require(_cost <= _maxProtocolFeeDai, "Cost of purchasing ETH to cover protocol Fee on the exchange was too high");
            require(cash.transferFrom(msg.sender, address(ethExchange), _cost));
            ethExchange.swap(token0IsCash ? 0 : _ethDeficit, token0IsCash ? _ethDeficit : 0, address(this), "");
            WETH.withdraw(_ethDeficit);
        }
    }

    function estimateProtocolFeeCostInCash(uint256 _numOrders, uint256 _gasPrice) public view returns (uint256) {
        uint256 _protocolFee = exchange.protocolFeeMultiplier().mul(_gasPrice);
        uint256 _amountEthRequired = _protocolFee.mul(_numOrders);
        return getTokenPurchaseCost(_amountEthRequired);
    }

    function getTokenPurchaseCost(uint256 _ethAmount) private view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) = ethExchange.getReserves();
        return getAmountIn(_ethAmount, token0IsCash ? _reserve0 : _reserve1, token0IsCash ? _reserve1 : _reserve0);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0);
        require(reserveIn > 0 && reserveOut > 0);
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function validateOrder(IExchange.Order memory _order, uint256 _fillAmountRemaining) internal view {
        require(_order.takerAssetData.equals(encodeTakerAssetData()));
        require(_order.takerAssetAmount == _order.makerAssetAmount);
        (IERC1155 _zeroXTradeTokenMaker, uint256 _tokenIdMaker) = getZeroXTradeTokenData(_order.makerAssetData);
        (address _market, uint256 _price, uint8 _outcome, uint8 _type) = unpackTokenId(_tokenIdMaker);
        uint256 _numTicks = IMarket(_market).getNumTicks();
        require(isOrderAmountValid(IMarket(_market), _fillAmountRemaining), "Order must be a multiple of the market trade increment");
        require(_zeroXTradeTokenMaker == this);
    }

    function isOrderAmountValid(IMarket _market, uint256 _orderAmount) public view returns (bool) {
        uint256 _tradeInterval = IAugurMarketDataGetter(address(augur)).getMarketRecommendedTradeInterval(_market);
        return _orderAmount.isMultipleOf(_tradeInterval);
    }

    function cancelOrders(IExchange.Order[] memory _orders, bytes[] memory _signatures, uint256 _maxProtocolFeeDai) public returns (bool) {
        require(_orders.length == _signatures.length);
        uint256 _protocolFee = exchange.protocolFeeMultiplier().mul(tx.gasprice);
        coverProtocolFee(_protocolFee.mul(_orders.length), _maxProtocolFeeDai);
        transferFromAllowed = true;
        for (uint256 i = 0; i < _orders.length; i++) {
            IExchange.Order memory _order = _orders[i];
            bytes memory _signature = _signatures[i];
            require(msg.sender == _order.makerAddress);
            IExchange.OrderInfo memory _orderInfo = exchange.getOrderInfo(_order);
            uint256 _amountRemaining = _order.takerAssetAmount.sub(_orderInfo.orderTakerAssetFilledAmount);
            exchange.fillOrder.value(_protocolFee)(_order, _amountRemaining, _signature);
            AugurOrderData memory _orderData = parseOrderData(_order);
            IUniverse _universe = IMarket(_orderData.marketAddress).getUniverse();
            augurTrading.logZeroXOrderCanceled(address(_universe), _orderData.marketAddress, _order.makerAddress, _orderData.outcome, _orderData.price, _amountRemaining, uint8(_orderData.orderType), _orderInfo.orderHash);
        }
        transferFromAllowed = false;
        if (address(this).balance > 0) {
            (bool _success,) = msg.sender.call.value(address(this).balance)("");
            require(_success);
        }
        return true;
    }

    function doTrade(IExchange.Order memory _order, uint256 _amount, bytes32 _fingerprint, bytes32 _tradeGroupId, address _taker) private returns (uint256 _amountFilled) {
        // parseOrderData will validate that the token being traded is the leigitmate one for the market
        AugurOrderData memory _augurOrderData = parseOrderData(_order);
        // If the signed order creator doesnt have enough funds we still want to continue and take their order out of the list
        // If the filler doesn't have funds this will just fail, which is fine
        if (!creatorHasFundsForTrade(_order, _amount)) {
            return 0;
        }
        // If the maker is also the taker we also just skip the trade but treat it as filled for amount remaining purposes
        if (_order.makerAddress == _taker) {
            return _amount;
        }
        (uint256 _amountRemaining, uint256 _fees) = fillOrder.fillZeroXOrder(IMarket(_augurOrderData.marketAddress), _augurOrderData.outcome, _augurOrderData.price, Order.Types(_augurOrderData.orderType), _order.makerAddress, _amount, _fingerprint, _tradeGroupId, _taker);
        _amountFilled = _amount.sub(_amountRemaining);
        logOrderFilled(_order, _augurOrderData, _taker, _tradeGroupId, _amountFilled, _fees);
        return _amountFilled;
    }

    function logOrderFilled(IExchange.Order memory _order, AugurOrderData memory _augurOrderData, address _taker, bytes32 _tradeGroupId, uint256 _amountFilled, uint256 _fees) private {
        bytes32 _orderHash = exchange.getOrderInfo(_order).orderHash;
        address[] memory _addressData = new address[](2);
        uint256[] memory _uint256Data = new uint256[](10);
        Order.Types _orderType = Order.Types(_augurOrderData.orderType);
        _addressData[0] = _order.makerAddress;
        _addressData[1] = _taker;
        _uint256Data[0] = _augurOrderData.price;
        _uint256Data[1] = 0;
        _uint256Data[2] = _augurOrderData.outcome;
        _uint256Data[5] = _fees;
        _uint256Data[6] = _amountFilled;
        _uint256Data[8] = 0;
        _uint256Data[9] = 0;
        augurTrading.logZeroXOrderFilled(IMarket(_augurOrderData.marketAddress).getUniverse(), IMarket(_augurOrderData.marketAddress), _orderHash, _tradeGroupId, uint8(_orderType), _addressData, _uint256Data);
    }

    function creatorHasFundsForTrade(IExchange.Order memory _order, uint256 _amount) public view returns (bool) {
        uint256 _tokenId = getTokenIdFromOrder(_order);
        return _amount <= this.balanceOf(_order.makerAddress, _tokenId);
    }

    function getTransferFromAllowed() public view returns (bool) {
        return transferFromAllowed;
    }

    /// @dev Encode MultiAsset proxy asset data into the format described in the AssetProxy contract specification.
    /// @param _market The address of the market to trade on
    /// @param _price The price used to trade
    /// @param _outcome The outcome to trade on
    /// @param _type Either BID == 0 or ASK == 1
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeAssetData(
        IMarket _market,
        uint256 _price,
        uint8 _outcome,
        uint8 _type
    )
        public
        view
        returns (bytes memory _assetData)
    {
        bytes[] memory _nestedAssetData = new bytes[](3);
        uint256[] memory _multiAssetValues = new uint256[](3);
        _nestedAssetData[0] = encodeTradeAssetData(_market, _price, _outcome, _type);
        _nestedAssetData[1] = encodeCashAssetData();
        _nestedAssetData[2] = encodeShareAssetData();
        _multiAssetValues[0] = 1;
        _multiAssetValues[1] = 0;
        _multiAssetValues[2] = 0;
        bytes memory _data = abi.encodeWithSelector(
            MULTI_ASSET_PROXY_ID,
            _multiAssetValues,
            _nestedAssetData
        );
        return _data;
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @param _market The address of the market to trade on
    /// @param _price The price used to trade
    /// @param _outcome The outcome to trade on
    /// @param _type Either BID == 0 or ASK == 1
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeTradeAssetData(
        IMarket _market,
        uint256 _price,
        uint8 _outcome,
        uint8 _type
    )
        private
        view
        returns (bytes memory _assetData)
    {
        uint256[] memory _tokenIds = new uint256[](1);
        uint256[] memory _tokenValues = new uint256[](1);

        uint256 _tokenId = getTokenId(address(_market), _price, _outcome, _type);
        _tokenIds[0] = _tokenId;
        _tokenValues[0] = 1;
        bytes memory _callbackData = new bytes(0);
        _assetData = abi.encodeWithSelector(
            ERC1155_PROXY_ID,
            address(this),
            _tokenIds,
            _tokenValues,
            _callbackData
        );

        return _assetData;
    }

    /// @dev Encode ERC-20 asset data into the format described in the AssetProxy contract specification.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeCashAssetData()
        private
        view
        returns (bytes memory _assetData)
    {
        _assetData = abi.encodeWithSelector(
            ERC20_PROXY_ID,
            address(cash)
        );

        return _assetData;
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeShareAssetData()
        private
        view
        returns (bytes memory _assetData)
    {
        uint256[] memory _tokenIds = new uint256[](0);
        uint256[] memory _tokenValues = new uint256[](0);
        bytes memory _callbackData = new bytes(0);
        _assetData = abi.encodeWithSelector(
            ERC1155_PROXY_ID,
            address(shareToken),
            _tokenIds,
            _tokenValues,
            _callbackData
        );

        return _assetData;
    }

    /// @dev Encode ERC-1155 asset data into the format described in the AssetProxy contract specification.
    /// @return AssetProxy-compliant asset data describing the set of assets.
    function encodeTakerAssetData()
        private
        view
        returns (bytes memory _assetData)
    {
        uint256[] memory _tokenIds = new uint256[](0);
        uint256[] memory _tokenValues = new uint256[](0);
        bytes memory _callbackData = new bytes(0);
        _assetData = abi.encodeWithSelector(
            ERC1155_PROXY_ID,
            address(this),
            _tokenIds,
            _tokenValues,
            _callbackData
        );

        return _assetData;
    }

    function getTokenId(address _market, uint256 _price, uint8 _outcome, uint8 _type) public pure returns (uint256 _tokenId) {
        // NOTE: we're assuming no one needs a full uint256 for the price value here and cutting to uint80 so we can pack this in a uint256.
        bytes memory _tokenIdBytes = abi.encodePacked(_market, uint80(_price), _outcome, _type);
        assembly {
            _tokenId := mload(add(_tokenIdBytes, add(0x20, 0)))
        }
    }

    function unpackTokenId(uint256 _tokenId) public pure returns (address _market, uint256 _price, uint8 _outcome, uint8 _type) {
        assembly {
            _market := shr(96, and(_tokenId, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000))
            _price := shr(16,  and(_tokenId, 0x0000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFF0000))
            _outcome := shr(8, and(_tokenId, 0x000000000000000000000000000000000000000000000000000000000000FF00))
            _type :=           and(_tokenId, 0x00000000000000000000000000000000000000000000000000000000000000FF)
        }
    }

    /// @dev Decode MultiAsset asset data from the format described in the AssetProxy contract specification.
    /// @param _assetData AssetProxy-compliant asset data describing an ERC-1155 set of assets.
    /// @return The ERC-1155 AssetProxy identifier, the address of this ERC-1155
    /// contract hosting the assets, an array of the identifiers of the
    /// assets to be traded, an array of asset amounts to be traded, and
    /// callback data.  Each element of the arrays corresponds to the
    /// same-indexed element of the other array.  Return values specified as
    /// `memory` are returned as pointers to locations within the memory of
    /// the input parameter `assetData`.
    function decodeAssetData(bytes memory _assetData)
        public
        view
        returns (
            bytes4 _assetProxyId,
            address _tokenAddress,
            uint256[] memory _tokenIds,
            uint256[] memory _tokenValues,
            bytes memory _callbackData
        )
    {
         // Read the bytes4 from array memory
        assembly {
            _assetProxyId := mload(add(_assetData, 32))
            // Solidity does not require us to clean the trailing bytes. We do it anyway
            _assetProxyId := and(_assetProxyId, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }

        require(_assetProxyId == MULTI_ASSET_PROXY_ID, "WRONG_PROXY_ID");

        uint256[] memory _amounts;
        bytes[] memory _nestedAssetData;

        // Slice the selector off the asset data
        bytes memory _noSelectorAssetData = _assetData.slice(4, _assetData.length);

        (_amounts, _nestedAssetData) = abi.decode(_noSelectorAssetData, (uint256[], bytes[]));
        
        // Validate storage refs against the decoded values.
        {
            require(_amounts.length == 3);
            require(_amounts[0] == 1);
            require(_amounts[1] == 0);
            require(_amounts[2] == 0);
            require(_nestedAssetData[1].equals(encodeCashAssetData()));
            require(_nestedAssetData[2].equals(encodeShareAssetData()));
        }

        return decodeTradeAssetData(_nestedAssetData[0]);
    }

    /// @dev Decode ERC-1155 asset data from the format described in the AssetProxy contract specification.
    /// @param _assetData AssetProxy-compliant asset data describing an ERC-1155 set of assets.
    /// @return The ERC-1155 AssetProxy identifier, the address of this ERC-1155
    /// contract hosting the assets, an array of the identifiers of the
    /// assets to be traded, an array of asset amounts to be traded, and
    /// callback data.  Each element of the arrays corresponds to the
    /// same-indexed element of the other array.  Return values specified as
    /// `memory` are returned as pointers to locations within the memory of
    /// the input parameter `assetData`.
    function decodeTradeAssetData(bytes memory _assetData)
        public
        pure
        returns (
            bytes4 _assetProxyId,
            address _tokenAddress,
            uint256[] memory _tokenIds,
            uint256[] memory _tokenValues,
            bytes memory _callbackData
        )
    {
         // Read the bytes4 from array memory
        assembly {
            _assetProxyId := mload(add(_assetData, 32))
            // Solidity does not require us to clean the trailing bytes. We do it anyway
            _assetProxyId := and(_assetProxyId, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }

        require(_assetProxyId == ERC1155_PROXY_ID, "WRONG_PROXY_ID");

        assembly {
            let _length := mload(_assetData)
            // Skip the length (of bytes variable) and the selector to get to the first parameter.
            _assetData := add(_assetData, 36)
            // Read the value of the first parameter:
            _tokenAddress := mload(_assetData)
            _tokenIds := add(_assetData, mload(add(_assetData, 32)))
            _tokenValues := add(_assetData, mload(add(_assetData, 64)))
            _callbackData := add(_assetData, mload(add(_assetData, 96)))
        }

        return (
            _assetProxyId,
            _tokenAddress,
            _tokenIds,
            _tokenValues,
            _callbackData
        );
    }

    function parseOrderData(IExchange.Order memory _order) public view returns (AugurOrderData memory _data) {
        (bytes4 _assetProxyId, address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _tokenValues, bytes memory _callbackData) = decodeAssetData(_order.makerAssetData);
        (address _market, uint256 _price, uint8 _outcome, uint8 _type) = unpackTokenId(_tokenIds[0]);
        _data.marketAddress = _market;
        _data.price = _price;
        _data.orderType = _type;
        _data.outcome = _outcome;
    }

    function getZeroXTradeTokenData(bytes memory _assetData) public view returns (IERC1155 _token, uint256 _tokenId) {
        (bytes4 _assetProxyId, address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _tokenValues, bytes memory _callbackData) = decodeAssetData(_assetData);
        _tokenId = _tokenIds[0];
        _token = IERC1155(_tokenAddress);
    }

    function getTokenIdFromOrder(IExchange.Order memory _order) public view returns (uint256 _tokenId) {
        (bytes4 _assetProxyId, address _tokenAddress, uint256[] memory _tokenIds, uint256[] memory _tokenValues, bytes memory _callbackData) = decodeAssetData(_order.makerAssetData);
        _tokenId = _tokenIds[0];
    }

    function createZeroXOrder(uint8 _type, uint256 _attoshares, uint256 _price, address _market, uint8 _outcome, uint256 _expirationTimeSeconds, uint256 _salt) public view returns (IExchange.Order memory _zeroXOrder, bytes32 _orderHash) {
        return createZeroXOrderFor(msg.sender, _type, _attoshares, _price, _market, _outcome, _expirationTimeSeconds, _salt);
    }

    function createZeroXOrderFor(address _maker, uint8 _type, uint256 _attoshares, uint256 _price, address _market, uint8 _outcome, uint256 _expirationTimeSeconds, uint256 _salt) public view returns (IExchange.Order memory _zeroXOrder, bytes32 _orderHash) {
        bytes memory _assetData = encodeAssetData(IMarket(_market), _price, _outcome, _type);
        require(isOrderAmountValid(IMarket(_market), _attoshares), "Order must be a multiple of the market trade increment");
        _zeroXOrder.makerAddress = _maker;
        _zeroXOrder.makerAssetAmount = _attoshares;
        _zeroXOrder.takerAssetAmount = _attoshares;
        _zeroXOrder.expirationTimeSeconds = _expirationTimeSeconds;
        _zeroXOrder.salt = _salt;
        _zeroXOrder.makerAssetData = _assetData;
        _zeroXOrder.takerAssetData = encodeTakerAssetData();
        _orderHash = exchange.getOrderInfo(_zeroXOrder).orderHash;
    }

    function encodeEIP1271OrderWithHash(
        IExchange.Order memory _zeroXOrder,
        bytes32 _orderHash
    )
        public
        pure
        returns (bytes memory encoded)
    {
        return abi.encodeWithSelector(
            EIP1271_ORDER_WITH_HASH_SELECTOR,
            _zeroXOrder,
            _orderHash
        );
    }

    function () external payable {}
}

