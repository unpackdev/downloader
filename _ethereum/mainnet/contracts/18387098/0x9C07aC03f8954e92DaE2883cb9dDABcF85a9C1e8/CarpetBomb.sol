/* SPDX-License-Identifier: MIT */
/**
 *
 *
 *
 * "we're gonna make it"? fuck yall, I'M gonna make it
 *
 *
 * https://igmi.tech
 *
 *
 * @title IGMI - good traders may profit, but only one buyer is gonna make it.
 *
 * @notice
 * Increase your balanace above qualifying tiers to earn entries for the prize, decrease your balance below those tiers to lose them.
 * Once the timeframe has elapsed, only one current entrant will win the entire LP.
 *
 * IMPORTANT: THE ABILITY TO TRADE THIS TOKEN WILL END WHEN A WINNER IS REQUESTED.
 *
 * @notice
 * ONE ENTRY - 500 tokens (500 * 10 ** 18) // .05%
 * TWO ENTRIES - 1_000 tokens (1_000 * 10 ** 18) // .1%
 * THREE ENTRIES - 1_500 tokens (1_500 * 10 ** 18) // .15%
 * FOUR ENTRIES - 2_000 tokens (2_000 * 10 ** 18) // .2%
 * FIVE ENTRIES - 2_500 tokens (2_500 * 10 ** 18) // .25%
 * SEVEN ENTRIES - 3_500 tokens (3_500 * 10 ** 18) // .35%
 * TEN ENTRIES - 5_000 tokens (5_000 * 10 ** 18) // .5%
 *
 * @notice
 * DETAILS:
 * After 24 hours, owner will close trading permanently and request a random number off-chain.
 * The random number is automatically used to find a random user by their entry index.
 * When the winner is found, liquidity is completely pulled by the contract, and the winning user gets ALL of the ETH pulled from the liquidity pool.
 * You are free to swap in and out of the pool, earning and losing entries as you wish, until that point.
 * Exit the game and take your profits, or risk it for a chance at the big prize. Are you gonna make it?
 *
 * NOTE: The contract owner is permanently incapable of pulling liquidity for themself.
 */

pragma solidity ^0.8.20;

import "./VRFV2WrapperConsumerBase.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address holder) external returns (uint256);
}

contract IGMI is ERC20, Ownable, VRFV2WrapperConsumerBase {
    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev comments on structs denote the bit size of the element
     */

    /**
     * @dev struct assigned to all users
     * @param buy user's buy block
     * @param exemptfee sets user exempt from fees
     * @param exemptlimit sets user exempt from limits
     * @param index the user's entry index (represents the user in the global entries)
     */
    struct USER {
        uint256 buy; // 32
        uint256 exemptfee; // 8
        uint256 exemptlimit; // 8
        uint256 index; // 24
    }

    /**
     * @dev struct which stores values used in transfer checks
     * @param changeblock the block on which trading begins
     * @param limitsblock the block after which limits are no longer checked
     * @param standardmode when enabled, there are no fees, restrictions, or entry logging
     * @param feesenabled when enabled, fees are taken
     * @param cooldown the minimum block count that must pass before a user can perform another transfer
     * @param eoatransfers when enabled, wallet-to-wallet transfers (externally-owned addresses, EOAs) are allowed
     */
    struct CHECKS {
        uint256 changeblock; // 32
        uint256 limitsblock; // 32
        uint256 standardmode; // 8
        uint256 feesenabled; // 8
        uint256 cooldown; // 8
        uint256 eoatransfers; // 8
    }

    /**
     * @dev struct which stores fee values
     * @param feebuy fee on buy
     * @param feesell fee on sell
     * @param feeliq fee for liquidity on both buys and sells
     */
    struct FEES {
        uint256 feebuy; // 8
        uint256 feesell; // 8
        uint256 feeliq; // 8
    }

    /**
     * @dev struct which stores max amounts at the 0th decimal (1 vs. 1 * 1e18)
     * @param maxtx max transaction amount for non-exempt users within the limits window
     * @param maxbal max balance for non-exempt users within the limits window
     */
    struct MAX {
        uint256 maxtx; // 16
        uint256 maxbal; // 24
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // minimum amount of tokens held to qualify for corresponding entry counts
    uint256 private constant ONE_ENTRY = 500 * 1e18;
    uint256 private constant TWO_ENTRIES = 1_000 * 1e18;
    uint256 private constant THREE_ENTRIES = 1_500 * 1e18;
    uint256 private constant FOUR_ENTRIES = 2_000 * 1e18;
    uint256 private constant FIVE_ENTRIES = 2_500 * 1e18;
    uint256 private constant SEVEN_ENTRIES = 3_500 * 1e18;
    uint256 private constant TEN_ENTRIES = 5_000 * 1e18;

    uint256 private constant DECIMAL_MULTIPLIER = 1e18;
    uint256 private constant ROLL_IN_PROGRESS = 9999999;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev
     * this uint256 holds these values in this order: CHECKS, FEES, MAX, currentUserIndex, currentEntryIndex
     * see getAllData()
     */
    uint256 private data_;

    uint128 public _randomResult;
    uint48 public _closeLimitBlock;
    uint48 public _closedAtTimestamp;
    uint32 public _linkFee;
    uint256 public _pureRandomNumber;

    // general user storage
    mapping(address => uint256) private _users;
    // individual user entry tracking
    mapping(address => uint256) private _userEntries;
    // entries 'array'
    mapping(uint256 => uint256) private _allEntries;
    // user index matching
    mapping(uint256 => address) private _indexUser;

    address private immutable WETH;
    IUniswapV2Router02 public immutable ROUTER;

    address private _pair;
    address private _wrapper;
    address public _winner;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event FeesUpdated(uint256 buy, uint256 sell, uint256 liq);
    event MaxUpdated(uint256 maxtx, uint256 maxbal);
    event FeesToggled(bool feesenabled);
    event StandardModeToggled(bool standardmode);
    event EOATransfersToggled(bool eoatransfers);
    event LimitBlockReduced(uint256 newblock);
    event CooldownReduced(uint256 newcooldown);
    event LinkFeeUpdated(uint256 newfee);
    event LiqBoosted(address token, uint256 amount);
    event EntriesGained(address user, uint256 amount);
    event EntriesLost(address user, uint256 amount);
    event DiceRolled(uint256 indexed requestId);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);
    event SentToWinner(address _holder);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error sendToZero();
    error notOpen();
    error alreadyOpen();
    error vrfCallbackNotComplete();
    error closeConditionsUnmet();
    error notAuthorized();
    error exceedMaxBalance();
    error belowMinBalance();
    error exceedMaxTx();
    error valueTooLow();
    error valueTooHigh();
    error txCooldown();
    error noEOAtoEOATransfers();
    error failedToSendETH();
    error castOverflow(uint256 value, uint256 bytecount);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address router_, address linkAddress, address wrapperAddress)
        payable
        ERC20("IGMI", "IGMI")
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
    {
        _wrapper = wrapperAddress;
        _setUserData(address(this), 0, 1, 1, 0);
        _setUserData(msg.sender, 0, 1, 1, 0);
        _mint(address(this), 1_000_000 * DECIMAL_MULTIPLIER);
        ROUTER = IUniswapV2Router02(router_);
        WETH = ROUTER.WETH();
        _linkFee = uint32(1_000_000);
    }

    /*//////////////////////////////////////////////////////////////
                            STANDARD LOGIC
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    // ERC20 override
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 data = data_;
        CHECKS memory checks = _getChecksData(data);
        USER memory senderData = _getUserData(_users[sender]);
        USER memory recipientData = _getUserData(_users[recipient]);
        // common conditions for no fee/limit transfers
        if (
            sender == address(this) // mid-swap
                || checks.standardmode != 0 // no fees, no restrictions for anyone
                || (senderData.exemptfee != 0 && senderData.exemptlimit != 0) // token contract, owner, or, after trading close, the router
                || (recipientData.exemptfee != 0 && recipientData.exemptlimit != 0) // token contract, owner, or, after trading close, the router
        ) {
            super._transfer(sender, recipient, amount);

            // fee/limit logic
        } else {
            // check if trading is open
            if (checks.changeblock == 0) {
                revert notOpen();
            }

            bool buy;
            address pair = _pair;
            MAX memory max = _getMaxData(data);
            FEES memory fees = _getFeesData(data);
            USER memory origData = _getUserData(_users[tx.origin]);

            // ------BUY------ //
            if (pair == sender) {
                // buy restrictions
                if (recipientData.exemptlimit == 0) {
                    // restrictions - launch window
                    if (checks.limitsblock > block.number) {
                        if (block.number < checks.changeblock + 2) {
                            // first two blocks get 20% buy fees
                            fees.feebuy = 10;
                            fees.feeliq = 10;
                        }
                        if (amount > max.maxtx * DECIMAL_MULTIPLIER) {
                            revert exceedMaxTx();
                        }
                        if ((balanceOf(recipient) + amount) > max.maxbal * DECIMAL_MULTIPLIER) {
                            revert exceedMaxBalance();
                        }
                        // cooldown
                        unchecked {
                            if (
                                recipientData.buy + checks.cooldown > block.number
                                    || origData.buy + checks.cooldown > block.number
                            ) {
                                revert txCooldown();
                            }
                        }
                        // 10% buy first 10 minutes
                        fees.feebuy = 7;
                        fees.feeliq = 3;
                    }
                    // set user's buy block
                    recipientData.buy = block.number;

                    // update user buy block if they have previously bought (this is otherwise handled in _checkEligibility)
                    if (recipientData.index != 0) {
                        _setUserData(
                            recipient,
                            recipientData.buy,
                            recipientData.exemptfee,
                            recipientData.exemptlimit,
                            recipientData.index
                        );
                    }

                    _checkEligibility(
                        recipient, recipientData, amount, data, fees, true, checks.feesenabled != 0 ? true : false
                    );

                    // assigning a buy block to tx.origin
                    if (tx.origin != recipient && checks.limitsblock > block.number) {
                        _setUserData(
                            tx.origin,
                            recipientData.buy,
                            recipientData.exemptfee,
                            recipientData.exemptlimit,
                            recipientData.index
                        );
                    }
                }

                buy = true;
            } else {
                // ------SELL------ //
                if (pair == recipient) {
                    // restrictions - permanent
                    if (senderData.exemptlimit == 0 && checks.cooldown != 0) {
                        unchecked {
                            if (
                                senderData.buy + checks.cooldown > block.number
                                    || origData.buy + checks.cooldown > block.number
                            ) {
                                revert txCooldown();
                            }
                        }
                    }

                    _checkEligibility(
                        sender, senderData, amount, data, fees, false, checks.feesenabled != 0 ? true : false
                    );

                    uint256 contractBalance = balanceOf(address(this));
                    // only attempt to sell an amount that uniswap shouldnt complain about (INSUFFICIENT_OUTPUT_AMOUNT)
                    if (contractBalance > ONE_ENTRY) {
                        // perform fee swap for maximum 5% price impact
                        uint256 priceImpactLimiter = (balanceOf(recipient) * 5) / 100;
                        _nestedSwap(contractBalance > priceImpactLimiter ? priceImpactLimiter : (contractBalance - 1));
                    }
                }
            }

            // take fees on swaps to/from pair only, and perform final transfer
            if (
                checks.feesenabled != 0
                    && (
                        ((recipientData.exemptfee == 0) && pair == sender)
                            || ((senderData.exemptfee == 0) && pair == recipient)
                    )
            ) {
                _collectAndTransfer(sender, recipient, amount, buy, fees);

                // EOA to EOA transfer (no fees)
            } else {
                // if recipient is not exempt from limits, assign highest limit between sender and recipient to recipient
                if (pair != sender && pair != recipient) {
                    // if EOA to EOA transfers are disabled, revert
                    if (checks.eoatransfers == 0) revert noEOAtoEOATransfers();
                    if (recipientData.exemptfee == 0 && recipientData.buy < senderData.buy) {
                        recipientData.buy = senderData.buy;
                    }

                    // check if sender loses entries
                    _checkEligibility(sender, senderData, amount, data, fees, false, false);

                    // check if recipient gains entries
                    _checkEligibility(recipient, recipientData, amount, data, fees, true, false);
                }

                super._transfer(sender, recipient, amount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PRIVATE/INTERNAL WRITE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev
     * use this function to take fees and perform the final transfer
     * although this function is only used once, it's separated due to stack-too-deep error
     * @param sender the address of the sender
     * @param recipient the address of the recipient
     * @param amount the amount being sent
     * @param buy whether or not this is a buy
     * @param fees the FEES struct
     */
    function _collectAndTransfer(address sender, address recipient, uint256 amount, bool buy, FEES memory fees)
        private
    {
        (uint256 fee, uint256 liqFee) = buy ? (fees.feebuy, fees.feeliq) : (fees.feesell, fees.feeliq);
        uint256 collection = (amount * fee) / 100;
        uint256 liq = (amount * liqFee) / 100;
        uint256 remainder = amount - collection - liq;
        if (buy) {
            // on buy, keep liq fee amount in the pair
            super._transfer(sender, recipient, remainder);
        } else {
            // ensures liq fee tokens are not counted as part of the amountIn
            if (liq != 0) {
                super._transfer(sender, recipient, liq);
                IUniswapV2Pair(recipient).sync();
            }
            super._transfer(sender, recipient, remainder);
        }
        if (collection != 0) {
            super._transfer(sender, address(this), collection);
        }
    }

    function _nestedSwap(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }

    /**
     * @dev
     * this function determines if user will gain or lose entries for this transaction, and adds/removes them accordingly
     * this function also sets all data for this user and assigns them an index if they are receiving tokens for the first time
     * @param user address of the user being checked
     * @param userData the user's USER struct
     * @param amount the amount being sent
     * @param data the global data_ value, sent through memory
     * @param buy used to determine whether we should check if user is gaining or losing entries
     */
    function _checkEligibility(
        address user,
        USER memory userData,
        uint256 amount,
        uint256 data,
        FEES memory fees,
        bool buy,
        bool checkFees
    ) private {
        uint256 entriesCount = _getUserEntryCount(user);
        uint256 eligibleCount;

        // balance is increasing
        if (buy) {
            if (checkFees) {
                if (fees.feebuy != 0 && fees.feeliq != 0) {
                    eligibleCount = getEligibleCount(
                        balanceOf(user) + (amount - ((amount * fees.feebuy) / 100) - ((amount * fees.feeliq) / 100))
                    );
                } else if (fees.feebuy != 0 && fees.feeliq == 0) {
                    eligibleCount = getEligibleCount(balanceOf(user) + (amount - ((amount * fees.feebuy) / 100)));
                } else if (fees.feebuy == 0 && fees.feeliq != 0) {
                    eligibleCount = getEligibleCount(balanceOf(user) + (amount - ((amount * fees.feeliq) / 100)));
                } else {
                    // feebuy == 0 && feeliq == 0, but feesell != 0
                    eligibleCount = getEligibleCount(balanceOf(user) + amount);
                }
                // EOA to EOA transfer
            } else {
                eligibleCount = getEligibleCount(balanceOf(user) + amount);
            }

            uint256 userIndex = userData.index;
            uint256 newUserIndex = userData.index;

            // store user and assign an index if not yet assigned (first buy)
            if (userIndex == 0) {
                userIndex = _getCurrentUserIndex(data);
                newUserIndex = userIndex;
                _setUserData(user, userData.buy, userData.exemptfee, userData.exemptlimit, userIndex);
                _indexUser[userIndex] = user;
                unchecked {
                    ++newUserIndex;
                }
            }

            // skip remaining logic and only update userIndex if user is new and entry count is unchanged
            if ((eligibleCount == 0 || eligibleCount == entriesCount) && userIndex != newUserIndex) {
                _setCurrentUserIndex(data, newUserIndex);
                return;
            }

            if (eligibleCount > entriesCount) {
                uint256 entryIndex = _getCurrentEntryIndex(data);
                // add user entries to the user's entries 'array'
                (uint256 newEntriesAmount) = _addEntriesToUserEntries(user, eligibleCount - entriesCount, entryIndex);

                // add user entries to the total entries 'array'
                uint256 newEntryIndex = _addEntriesToAllEntries(userIndex, newEntriesAmount, entryIndex);

                if (userIndex != newUserIndex) {
                    // update both current user index and entry index if adding a qualifying user on this buy
                    _setCurrentIndeces(data, newUserIndex, newEntryIndex);
                } else {
                    // only update entry index
                    _setCurrentEntryIndex(data, newEntryIndex);
                }

                emit EntriesGained(user, eligibleCount - entriesCount);
            }
            // balance is decreasing
        } else {
            // avoid underflow
            if (balanceOf(user) < amount) return;

            eligibleCount = getEligibleCount(balanceOf(user) - amount);

            if (eligibleCount < entriesCount) {
                uint256 subAmount = entriesCount - eligibleCount;
                uint24[] memory removedEntries = new uint24[](subAmount);

                // remove user entries from the user's entries 'array'
                removedEntries = _removeEntriesFromUserEntries(user, subAmount);

                // remove user entries from the total entries 'array'
                _removeEntriesFromAllEntries(removedEntries);

                emit EntriesLost(user, subAmount);
            }
        }
    }

    /**
     * @dev
     * this function iteratively adds entries to the _allEntries mapping
     * the _allEntries mapping is treated as an object which contains sequential arrays of 10 numbers each.
     * entries are stored as such: _allEntries[0] = [0,1,2,3,4,5,6,7,8,9], _allEntries[1] = [10,11,12,13,14,15,16,17,18,19], etc.
     * we can use division and modulo on a given entry index to always find the key of the 'array' it's in, and its position in that 'array'
     * note that 24 in the following function represents the maximum bit size of an index.
     * @param indexUser the index of the user being assigned entries
     * @param entryCount the number of entries to assign this user
     * @param currentEntryIndex the next entry index to assign a user
     * @return currentEntryIndex the new value of currentEntryIndex, after adding entries
     */
    function _addEntriesToAllEntries(uint256 indexUser, uint256 entryCount, uint256 currentEntryIndex)
        private
        returns (uint256)
    {
        uint256 currentKey;
        unchecked {
            currentKey = currentEntryIndex / 10;
        }
        uint256 currentBitObject = _allEntries[currentKey];

        for (uint256 i; i < entryCount;) {
            // retrieve key of current bit object
            uint256 key;
            unchecked {
                key = currentEntryIndex / 10;
            }

            // determine position within that bit object
            // ex. currentPosition = 35
            // key = 35 / 10 = 3
            // position within bit object = 35 % (3 * 10) = 5
            // cannot modulo by 0, so just use currentPosition if key is 0
            uint256 position;
            unchecked {
                position = currentEntryIndex > 9 ? currentEntryIndex % (key * 10) : currentEntryIndex;
            }

            // determine starting position
            // ex. position within bit object is 2
            // startingPosition = 24 (length) * 2 = 48
            uint256 startingPosition;
            unchecked {
                startingPosition = 24 * position;
            }

            if (startingPosition != 0) {
                currentBitObject |= indexUser << startingPosition;
            } else {
                currentBitObject = indexUser << startingPosition;
            }

            // update storage if at the end of the uint, or the loop is complete
            unchecked {
                if (position == 9 || i + 1 == entryCount) {
                    _allEntries[key] = currentBitObject;
                }

                ++currentEntryIndex;
                ++i;
            }
        }
        // return new entry index, to be stored in calling function
        return currentEntryIndex;
    }

    /**
     * @dev adds entries to a user's entries 'array'
     * @param user the address of the user
     * @param addAmount the amount of entries to add
     * @param currentEntryIndex the global current entry index, which was not affected by this function
     * @return addAmount the amount of entries added
     */
    function _addEntriesToUserEntries(address user, uint256 addAmount, uint256 currentEntryIndex)
        private
        returns (uint256)
    {
        uint256 currentBitObject = _userEntries[user];
        // get the next entry position
        (, uint256 nextEntryPosition) = _getCurrentEntryCountAndNextEntryPosition(currentBitObject);

        // although a 10th entry means the next entry bit position is 240 (24 * 10),
        // nextEntryPosition doesn't get a final 24 added to it in _getCurrentEntryCountAndNextEntryPosition() before the loop ends.
        // this would matter if we had a tier that qualifies for 9 entries, but we don't, so it doesn't.
        // it's cheaper not to perform that check and addition.
        if (nextEntryPosition == 216) return (addAmount);

        for (uint256 i; i < addAmount;) {
            currentBitObject |= currentEntryIndex << nextEntryPosition;
            unchecked {
                ++currentEntryIndex;
                ++i;
            }
            if (nextEntryPosition == 216) {
                // ensure we don't attempt to add more entries than will fit (216 means user is in the 10-entry tier already)
                break;
            }
            unchecked {
                nextEntryPosition += 24;
            }
        }
        _userEntries[user] = currentBitObject;
        return (addAmount);
    }

    /**
     * @dev this function accepts an array of entries to find and remove from the global entries 'array'
     * @param entries an array of entries to remove
     */
    function _removeEntriesFromAllEntries(uint24[] memory entries) private {
        uint256 entriesLength = entries.length;
        uint256 previousKey;
        uint256 currentBitObject;
        for (uint256 i; i < entriesLength;) {
            uint256 entry = entries[i];
            uint256 currentKey;

            // get the key for the current entry
            unchecked {
                currentKey = entry / 10;
            }
            if (i == 0) {
                currentBitObject = _allEntries[currentKey];
            }
            if (i != 0 && previousKey != currentKey) {
                // store previous changes
                _allEntries[previousKey] = currentBitObject;
                // get current key's 'bit object' and store it to memory
                currentBitObject = _allEntries[currentKey];
            }

            // determine position within that bit object
            // cannot modulo by 0, so just use currentPosition if key is 0
            uint256 position;
            unchecked {
                position = entry > 9 ? entry % (currentKey * 10) : entry;
            }
            uint256 startingPosition;
            unchecked {
                startingPosition = 24 * position;
            }
            // update the bit object by removing this entry
            currentBitObject = _clearBits(currentBitObject, startingPosition, 24);

            // retain the updated bit object in memory, unless this is the last iteration of the loop
            unchecked {
                if (i + 1 == entriesLength) {
                    _allEntries[currentKey] = currentBitObject;
                }
                previousKey = currentKey;
                ++i;
            }
        }
    }

    /**
     * @dev this function removes entries from a user's entries 'array', starting at the most recently-added entry
     * @param user the address of the user to remove entries from
     * @param subAmount the amount of entries to remove
     * @return removedEntries the entries that were removed, which now must be removed from the global entries 'array'
     */
    function _removeEntriesFromUserEntries(address user, uint256 subAmount) private returns (uint24[] memory) {
        // get existing entry count
        uint256 entryCount = _getUserEntryCount(user);
        // get the user's bit object
        uint256 entriesBits = _userEntries[user];
        // initialize array of entries being removed
        uint24[] memory removedEntries = new uint24[](subAmount);
        // start bitPosition at the user's last entry
        uint256 bitPosition = (entryCount * 24);
        // add entries being removed to memory array and find starting point for mask
        for (uint256 i; i < subAmount;) {
            // move to the beginning of entry's bit space
            unchecked {
                bitPosition -= 24;
            }
            removedEntries[i] = uint24(entriesBits >> bitPosition);
            unchecked {
                ++i;
            }
        }
        // update the bit object by removing this entry
        _userEntries[user] = _clearBits(entriesBits, bitPosition, (24 * subAmount));

        // return an array of the user's removed entries to remove from the total entries
        return removedEntries;
    }

    /**
     * @dev
     * sets the entire global data_ value at once
     * the bitSize array holds the size of each sequential element to ensure they are put in the right position
     * @param tempData an array of all of the values in the global data_ value. they are as follows, with corresponding bit size:
     * @dev uint256 changeblock, // 32
     * @dev uint256 limitsblock, // 32
     * @dev uint256 standardmode, // 8
     * @dev uint256 feesenabled, // 8
     * @dev uint256 cooldown, // 8
     * @dev uint256 feebuy, // 8
     * @dev uint256 feesell, // 8
     * @dev uint256 feeliq, // 8
     * @dev uint256 maxtx, // 16
     * @dev uint256 maxbal, // 24
     * @dev uint256 userIndex, // 24
     * @dev uint256 entryIndex, // 24
     */
    function _setData(uint256[13] memory tempData) private {
        uint256 length = tempData.length;
        uint256 shift;
        uint256 data;
        uint8[13] memory bitSize = [32, 32, 8, 8, 8, 8, 8, 8, 8, 16, 24, 24, 24]; // bit size for each element
        require(length == 13);
        for (uint256 i; i < length;) {
            _overflowCheck(tempData[i], bitSize[i]);
            data |= tempData[i] << shift;
            unchecked {
                shift += bitSize[i];
                ++i;
            }
        }
        data_ = data;
    }

    /**
     * @dev sets data assigned to a user
     * @param user the address of the user
     * @param buy the user's buy block
     * @param exemptfee whether or not the user is exempt from fees (0 is false, 1 is true)
     * @param exemptlimit whether or not the user is exempt from limits (0 is false, 1 is true)
     * @param index the user's index, used when giving them entries
     */
    function _setUserData(
        address user,
        uint256 buy, // 32
        uint256 exemptfee, // 8
        uint256 exemptlimit, // 8
        uint256 index // 24
    ) private {
        _overflowCheck(buy, 32);
        uint256 data = buy;
        _overflowCheck(exemptfee, 8);
        data |= exemptfee << 32;
        _overflowCheck(exemptlimit, 8);
        data |= exemptlimit << 40;
        _overflowCheck(index, 24);
        data |= index << 48;
        _users[user] = data;
    }

    /**
     * @dev sets just the CHECKS struct in the global data_ value
     * @param changeblock the block on which trading begins
     * @param limitsblock the block after which limits are no longer checked
     * @param standardmode when enabled, there are no fees, restrictions, or entry logging
     * @param feesenabled when enabled, fees are taken
     * @param cooldown the minimum block count that must pass before a user can perform another transfer
     * @param eoatransfers when enabled, allow transfers from one EOA to another (wallet to wallet)
     */
    function _setChecksData(
        uint256 changeblock, // 32
        uint256 limitsblock, // 32
        uint256 standardmode, // 8
        uint256 feesenabled, // 8
        uint256 cooldown, // 8
        uint256 eoatransfers // 8
    ) private {
        uint256 data = _clearBits(data_, 0, 96);
        _overflowCheck(changeblock, 32);
        data |= changeblock << 0;
        _overflowCheck(limitsblock, 32);
        data |= limitsblock << 32;
        _overflowCheck(standardmode, 8);
        data |= standardmode << 64;
        _overflowCheck(feesenabled, 8);
        data |= feesenabled << 72;
        _overflowCheck(cooldown, 8);
        data |= cooldown << 80;
        _overflowCheck(eoatransfers, 8);
        data |= eoatransfers << 88;
        data_ = data;
    }

    /**
     * @dev sets the changeblock to 0 to halt trading
     */
    function _setChecksDataCloseTrading() private {
        data_ = _clearBits(data_, 0, 32);
    }

    /**
     * @dev sets just the FEES struct in the global data_ value
     * @param feebuy fee on buy
     * @param feesell fee on sell
     * @param feeliq fee for liquidity on both buys and sells
     */
    function _setFeesData(
        uint256 feebuy, // 8
        uint256 feesell, // 8
        uint256 feeliq // 8
    ) private {
        uint256 data = _clearBits(data_, 96, 24);
        _overflowCheck(feebuy, 8);
        data |= feebuy << 96;
        _overflowCheck(feesell, 8);
        data |= feesell << 104;
        _overflowCheck(feeliq, 8);
        data |= feeliq << 112;
        data_ = data;
    }

    /**
     * @dev sets just the MAX struct in the global data_ value
     * @param maxtx max transaction amount for non-exempt users within the limits window
     * @param maxbal max balance for non-exempt users within the limits window
     */
    function _setMaxData(
        uint256 maxtx, // 16
        uint256 maxbal // 24
    ) private {
        uint256 data = _clearBits(data_, 120, 40);
        _overflowCheck(maxtx, 16);
        data |= maxtx << 120;
        _overflowCheck(maxbal, 24);
        data |= maxbal << 136;
        data_ = data;
    }

    /**
     * @dev sets the next user index
     * @param data the global data_ value
     * @param index the next user index to assign a user
     */
    function _setCurrentUserIndex(uint256 data, uint256 index) private {
        data = _clearBits(data, 160, 24);
        _overflowCheck(index, 24);
        data |= index << 160;
        data_ = data;
    }

    /**
     * @dev sets the next entry index
     * @param data the global data_ value
     * @param index the next entry index to assign a user
     */
    function _setCurrentEntryIndex(uint256 data, uint256 index) private {
        data = _clearBits(data, 184, 24);
        _overflowCheck(index, 24);
        data |= index << 184;
        data_ = data;
    }

    /**
     * @dev sets both the next user index and the next entry index
     * @param data the global data_ value
     * @param userIndex the next index to assign a user
     * @param entryIndex the next entry index to assign a user
     */
    function _setCurrentIndeces(uint256 data, uint256 userIndex, uint256 entryIndex) private {
        data = _clearBits(data, 160, 48);
        _overflowCheck(userIndex, 24);
        data |= userIndex << 160;
        _overflowCheck(entryIndex, 24);
        data |= entryIndex << 184;
        data_ = data;
    }

    /**
     * @dev sets a user exempt from fees, limits, or both
     * @param userAddress the address of the user
     * @param exemptfee whether or not the user is exempt from fees (0 is false, 1 is true)
     * @param exemptlimit whether or not the user is exempt from limits (0 is false, 1 is true)
     */
    function _setUserExempt(address userAddress, bool exemptfee, bool exemptlimit) private {
        USER memory user = _getUserData(_users[userAddress]);
        uint256 fee = exemptfee ? uint256(1) : 0;
        uint256 limit = exemptlimit ? uint256(1) : 0;
        _setUserData(userAddress, user.buy, fee, limit, user.index);
    }

    /**
     * @dev
     * this function is run as the result of a callback from the VRF coordinator
     * we are taking the huge random number we get back, and getting a random entry index <= the total number of entries recorded
     * @param _requestId the id created by the original request
     * @param _randomWords the random number
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 finalIndex = _getCurrentEntryIndex(data_);
        unchecked {
            --finalIndex; // last entry index assigned is one less than current value of currentEntryIndex
        }
        _pureRandomNumber = _randomWords[0];

        uint128 randomResult = uint128(_pureRandomNumber % (finalIndex));
        _randomResult = randomResult;
        emit DiceLanded(_requestId, uint256(randomResult));

        // perform an encodeCall so that the values above can get set successfully even if this function call fails
        // it is possible for this function to fail if it consumes more gas than the coordinator expects it to
        // in that case, dev will run the external sendToWinner function and pay the gas themself
        (bool success,) = address(this).call(abi.encodeCall(this.sendToWinner, (uint256(randomResult), finalIndex)));
        success;
    }

    /**
     * @dev
     * first, we attempt to get a winner at the previously-defined winner entry index
     * if there is no user index at this position (because the user that was here sold and lost this entry),
     * we iterate up through the entries looking for a user index that is not 0
     * if there are none above this point, we go back to the original winner entry index and iterate down
     * we do not accept any circumstance in which the user index is 0, as this index is not assigned to anyone.
     * when we find a winner, we pull all liquidity and send the winner all of the ETH.
     * @param randomResult the currently-selected random entry index
     * @param finalIndex the very last recorded entry index (used for finding a new entry if the selected index has no entrant)
     */
    function _sendToWinner(uint256 randomResult, uint256 finalIndex) private {
        uint256 winnerIndex = randomResult;
        address winner;
        (, winner) = _getEntrantIdAndAddressAtIndex(winnerIndex);
        // if address at this index is unassigned (sold their entry), find the next entry index assigned to a user
        if (winner == address(0)) {
            // if not at the end of the entry list, increment through entries
            if (winnerIndex < finalIndex) {
                uint256 diff = finalIndex - winnerIndex;
                for (uint256 i; i < diff;) {
                    unchecked {
                        ++winnerIndex;
                    }
                    (, winner) = _getEntrantIdAndAddressAtIndex(winnerIndex);
                    if (winner != address(0)) {
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
            // contingency for reaching the end of the list - decrement from originally-selected entry index
            if (winner == address(0) && winnerIndex == finalIndex) {
                winnerIndex = randomResult;
                for (uint256 i; i < randomResult;) {
                    unchecked {
                        --winnerIndex;
                    }
                    (, winner) = _getEntrantIdAndAddressAtIndex(winnerIndex);
                    if (winner != address(0)) {
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
            require(winner != address(0));
            _randomResult = uint128(winnerIndex);
        }

        _winner = winner;
        IERC20(_pair).approve(address(ROUTER), type(uint256).max);
        (, uint256 lpEth) = ROUTER.removeLiquidityETH(
            address(this), IERC20(_pair).balanceOf(address(this)), 0, 0, address(this), block.timestamp
        );
        (bool sent,) = winner.call{value: lpEth}("");
        require(sent, "Failed to send!");
        emit SentToWinner(winner);
    }

    /*//////////////////////////////////////////////////////////////
                        PRIVATE/INTERNAL VIEW/PURE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev checks amount qualifies for entries
     * @param amount amount being transferred
     * @return entryCount the amount of entries this amount qualifies for
     */
    function getEligibleCount(uint256 amount) private pure returns (uint256) {
        if (amount < ONE_ENTRY) {
            return 0;
        } else if (amount < TWO_ENTRIES) {
            return 1;
        } else if (amount < THREE_ENTRIES) {
            return 2;
        } else if (amount < FOUR_ENTRIES) {
            return 3;
        } else if (amount < FIVE_ENTRIES) {
            return 4;
        } else if (amount < SEVEN_ENTRIES) {
            return 5;
        } else if (amount < TEN_ENTRIES) {
            return 7;
        } else {
            return 10;
        }
    }

    /**
     * @param user address of the user being checked
     * @param position the position of the entry being retrieved in the user's entries 'array' (0 through 9, 10 total possible positions)
     * @return entryId the entry id at that position
     */
    function _getUserEntries(address user, uint256 position) private view returns (uint24) {
        require(position < 10, "Out of range");
        uint256 bitPosition = position * 24;
        uint256 bitObj = _userEntries[user];

        uint24 entryId = uint24(bitObj >> bitPosition);
        return (entryId);
    }

    /**
     * @param user address of the user being checked
     * @return count the amount of entries user has
     */
    function _getUserEntryCount(address user) private view returns (uint256) {
        uint256 currentBitObject = _userEntries[user];
        // get the current entry count
        (uint256 count,) = _getCurrentEntryCountAndNextEntryPosition(currentBitObject);
        return count;
    }

    /**
     * @dev performs bit masking. see comments in function for step-by-step description of behavior
     * @param bitObject the bits to be manipulated
     * @param startingPosition the position within the bits to start the mask
     * @param bitSize the total bit size to mask from the starting position
     * @return clearedBits the original bit 'object' with the targeted bit space cleared
     */
    function _clearBits(uint256 bitObject, uint256 startingPosition, uint256 bitSize)
        private
        pure
        returns (uint256 clearedBits)
    {
        uint256 mask = ~(uint256(2 ** bitSize - 1) << startingPosition); // set all 1s for the length of the bit space (as in a uint24), shift it left x bits to make it the appropriate entry, and then invert it to set those bits to zero
        // ex. mask = 11110001111
        clearedBits = bitObject & mask; // takes the existing bits and overwrites with the new 0 value bits
            // ex. currentBits = 10110110110
            // ex. new value = 10110000110
    }

    /**
     * @dev
     * the _allEntries mapping is treated as an object which contains sequential arrays of 10 numbers each.
     * entries are stored as such: _allEntries[0] = [0,1,2,3,4,5,6,7,8,9], _allEntries[1] = [10,11,12,13,14,15,16,17,18,19], etc.
     * we can use division and modulo on a given entry index to always find the key of the 'array' its in, and its position in that 'array'
     * note that 24 in the following function represents the maximum bit size of an index.
     * @param index the entry index
     * @return userIndex the user index at that entry position
     * @return userAddress the address of the user with that userIndex
     */
    function _getEntrantIdAndAddressAtIndex(uint256 index) private view returns (uint24, address) {
        uint256 key = index / 10;
        uint256 position = index > 9 ? index % (key * 10) : index;
        uint256 bitPosition = position * 24;
        uint256 bitObj = _allEntries[key];

        uint24 userIndex = uint24(bitObj >> bitPosition);
        return (userIndex, _indexUser[userIndex]);
    }

    /**
     * @dev this function finds the existing entry count of a user, and the bit space after their most recently recorded entry
     * @param bitObject the entries bit 'object' of the user
     * @return count the amount of entries the user already has
     * @return nextEntryPosition the bit position where the next entry can be inserted
     */
    function _getCurrentEntryCountAndNextEntryPosition(uint256 bitObject)
        private
        pure
        returns (uint256 count, uint256 nextEntryPosition)
    {
        for (; count < 10;) {
            uint24 entry;
            nextEntryPosition = count * 24;
            entry = uint24(bitObject >> nextEntryPosition);
            if (entry == 0) {
                break;
            }
            unchecked {
                ++count;
            }
        }
    }

    /**
     * @dev returns all of the values in the global data_ value
     * @param data the global data_ value
     * @return checks the CHECKS struct
     * @return fees the FEES struct
     * @return max the MAX struct
     * @return currentUserIndex the next user index to be assigned to a user
     * @return currentEntryIndex the next entry index to be assigned to a user
     */
    function _getAllData(uint256 data)
        private
        pure
        returns (
            CHECKS memory checks,
            FEES memory fees,
            MAX memory max,
            uint256 currentUserIndex,
            uint256 currentEntryIndex
        )
    {
        checks.changeblock = uint256(uint32(data));
        checks.limitsblock = uint256(uint32(data >> 32));
        checks.standardmode = uint256(uint8(data >> 64));
        checks.feesenabled = uint256(uint8(data >> 72));
        checks.cooldown = uint256(uint8(data >> 80));
        checks.eoatransfers = uint256(uint8(data >> 88));
        fees.feebuy = uint256(uint8(data >> 96));
        fees.feesell = uint256(uint8(data >> 104));
        fees.feeliq = uint256(uint8(data >> 112));
        max.maxtx = uint256(uint16(data >> 120));
        max.maxbal = uint256(uint24(data >> 136));
        currentUserIndex = uint256(uint24(data >> 160));
        currentEntryIndex = uint256(uint24(data >> 184));
    }

    function _getUserData(uint256 user) private pure returns (USER memory user_) {
        user_.buy = uint256(uint32(user));
        user_.exemptfee = uint256(uint8(user >> 32));
        user_.exemptlimit = uint256(uint8(user >> 40));
        user_.index = uint256(uint24(user >> 48));
    }

    function _getChecksData(uint256 data) private pure returns (CHECKS memory checks) {
        checks.changeblock = uint256(uint32(data));
        checks.limitsblock = uint256(uint32(data >> 32));
        checks.standardmode = uint256(uint8(data >> 64));
        checks.feesenabled = uint256(uint8(data >> 72));
        checks.cooldown = uint256(uint8(data >> 80));
        checks.eoatransfers = uint256(uint8(data >> 88));
    }

    function _getFeesData(uint256 data) private pure returns (FEES memory fees) {
        fees.feebuy = uint256(uint8(data >> 96));
        fees.feesell = uint256(uint8(data >> 104));
        fees.feeliq = uint256(uint8(data >> 112));
    }

    function _getMaxData(uint256 data) private pure returns (MAX memory max) {
        max.maxtx = uint256(uint16(data >> 120));
        max.maxbal = uint256(uint24(data >> 136));
    }

    function _getCurrentUserIndex(uint256 data) private pure returns (uint256) {
        return uint256(uint24(data >> 160));
    }

    function _getCurrentEntryIndex(uint256 data) private pure returns (uint256) {
        return uint256(uint24(data >> 184));
    }

    function _overflowCheck(uint256 value, uint256 bytecount) private pure {
        //checks if value fits in target uint type

        if (value >= uint256(1 << bytecount)) {
            revert castOverflow(uint256(value), uint256(bytecount));
        }
    }

    function _hasCode(address _address) private view returns (bool) {
        return _address.code.length != 0;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    function getUserData(address user) external view returns (USER memory user_) {
        return _getUserData(_users[user]);
    }

    function getUserEntryCount(address sender) external view returns (uint256) {
        return _getUserEntryCount(sender);
    }

    function getAllUserEntries(address user) external view returns (uint24[] memory) {
        uint256 bitObj = _userEntries[user];
        uint24[] memory entries = new uint24[](10);
        for (uint256 i; i < 10;) {
            uint256 bitPosition = i * 24;
            entries[i] = uint24(bitObj >> bitPosition);
            unchecked {
                ++i;
            }
        }
        return entries;
    }

    function getAllData()
        external
        view
        returns (
            CHECKS memory checks,
            FEES memory fees,
            MAX memory max,
            uint256 currentUserIndex,
            uint256 currentEntryIndex
        )
    {
        return _getAllData(data_);
    }

    function getEntryMinimums() external pure returns (uint256[] memory) {
        uint256[] memory entries = new uint256[](7);
        entries[0] = ONE_ENTRY;
        entries[1] = TWO_ENTRIES;
        entries[2] = THREE_ENTRIES;
        entries[3] = FOUR_ENTRIES;
        entries[4] = FIVE_ENTRIES;
        entries[5] = SEVEN_ENTRIES;
        entries[6] = TEN_ENTRIES;
        return entries;
    }

    function getWETH() external view returns (address) {
        return WETH;
    }

    function getPair() external view returns (address) {
        return _pair;
    }

    function getIndexUser(uint256 index) external view returns (address) {
        return _indexUser[index];
    }

    function getEntrantIdAndAddressAtIndex(uint256 index) external view returns (uint24, address) {
        return _getEntrantIdAndAddressAtIndex(index);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL WRITE
    //////////////////////////////////////////////////////////////*/

    function deploy(uint48 duration) public payable onlyOwner {
        // can only be deployed once
        if (_pair != address(0)) {
            revert alreadyOpen();
        }

        // close limit must exceed one hour
        if (duration <= 300) {
            // (60 minutes * 60 seconds) / 12 seconds per block = 300
            revert valueTooLow();
        }

        _approve(address(this), address(ROUTER), type(uint256).max);
        ROUTER.addLiquidityETH{value: address(this).balance}(
            address(this), balanceOf(address(this)) - 1, 0, 0, address(this), block.timestamp
        );
        address factory = ROUTER.factory();
        address pair = IUniswapV2Factory(factory).getPair(WETH, address(this));
        _setUserData(pair, 0, 1, 0, 0);
        _pair = pair;
        _closeLimitBlock = uint48(block.number + duration);

        // userIndex must start at 1, as 0 needs to mean 'no user'
        // entryIndex must start at 1 for edge case in which first user adds to existing entries with multiple buys
        uint256[13] memory data = [
            block.number, // launch block
            block.number + 50, // limits window ((~12-second block time * 50) / 60 seconds) = ~10 minutes
            0, // standard mode
            1, // fees enabled
            3, // min blocks for cooldown
            1, // allow EOA to EOA transfers
            4, // buy fee
            4, // sell fee
            1, // liq fee
            6_000, // max tx - (fee + liq fee + amount for ten entries) * 1.2 (120%) to try and account for price action
            10_000, // max balance
            1, // userIndex
            1 // entryIndex
        ];
        _setData(data);
    }

    /**
     * @dev
     * closes trading by setting launch block to 0, performs a final price-impact-limited contract swap,
     * and requests a random number from chainlink VRF
     * this can only be done if trading is open, if it has not already been successfully run, and the specified time has passed (24 hours)
     */
    function closeTradingAndRollDice() external onlyOwner returns (uint256 requestId) {
        CHECKS memory checks = _getChecksData(data_);
        uint256 currentEntryIndex = _getCurrentEntryIndex(data_);
        if (
            checks.changeblock == 0 // not launched, or this has been run already
                || _closedAtTimestamp != 0 // this has been run already
                || block.number < uint256(_closeLimitBlock) // timeframe has not elapsed
                || currentEntryIndex == 1 // no entries have been registered yet
        ) {
            revert closeConditionsUnmet();
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        // only attempt to sell an amount that uniswap shouldnt complain about (INSUFFICIENT_OUTPUT_AMOUNT)
        if (contractTokenBalance > ONE_ENTRY) {
            // perform final fee swap
            uint256 impactSell = (balanceOf(_pair) * 20) / 100;
            if (contractTokenBalance > impactSell) {
                contractTokenBalance = impactSell;
            }
            _nestedSwap(contractTokenBalance - 1);
        }

        uint256 contractETHBalance = address(this).balance;

        // don't require the fee transfer to succeed. dev can collect fees on their own later, if necessary
        if (contractETHBalance != 0) {
            (bool success,) = owner().call{value: address(this).balance}("");
            success;
        }

        // for display purposes
        _closedAtTimestamp = uint48(block.timestamp);

        // reset changeblock to zero, halting trading
        _setChecksDataCloseTrading();

        // exempt router from limits for the liquidity removal
        _setUserData(address(ROUTER), 0, 1, 1, 0);
        requestId = requestRandomness(uint32(_linkFee), uint16(3), uint32(1)); // actual gas cost is roughly 300_000
        _randomResult = uint128(ROLL_IN_PROGRESS);
        emit DiceRolled(requestId);
    }

    /**
     * @dev
     * this function is external as a contingency for the possible scenario in which this function fails when executed in the VRF callback.
     * ideally, this is not needed, but better to be safe than sorry.
     * because this function is used internally, and we are using memory values in order to minimize gas, it must accept parameters.
     * if this function is called externally by owner,
     * whatever parameters they provided are ignored, and correct ones are pulled from existing contract logic
     * this eliminates unnecessary work to retrieve correct values, and prevents exploitation by the owner
     * @param randomResult the random index set in fulfillRandomWords (pass 0 when calling as owner)
     * @param currentEntryIndex the final entry index assigned to a user before trading closed (pass 0 when calling as owner)
     */
    function sendToWinner(uint256 randomResult, uint256 currentEntryIndex) external {
        if (msg.sender != address(this) && msg.sender != address(_wrapper) && msg.sender != owner()) {
            revert notAuthorized();
        }

        if (msg.sender == owner()) {
            // cannot be run if random result was not already requested and received
            if (_closedAtTimestamp == 0 || _randomResult == ROLL_IN_PROGRESS || _randomResult == 0) {
                revert vrfCallbackNotComplete();
            }

            // when owner is the caller, ignore the values they passed and get the correct ones
            // this prevents exploitation by owner to assign winner to whomever they want

            // if owner can successfully call this function, we have already received a random number and set the random winner index
            randomResult = _randomResult;
            currentEntryIndex = _getCurrentEntryIndex(data_);
            unchecked {
                --currentEntryIndex; // last entry index assigned is one less than current value of currentEntryIndex
            }
        }

        // run the actual winner selection and payout logic
        _sendToWinner(randomResult, currentEntryIndex);
    }

    function setUserExempt(address userAddress, bool exemptfee, bool exemptlimit) external onlyOwner {
        // cannot alter significant contracts externally
        if (userAddress == _pair || userAddress == address(ROUTER) || userAddress == address(this)) {
            revert notAuthorized();
        }
        _setUserExempt(userAddress, exemptfee, exemptlimit);
    }

    function updateMax(uint256 maxTx, uint256 maxBalance) external onlyOwner {
        MAX memory currentMax = _getMaxData(data_);
        CHECKS memory currentChecks = _getChecksData(data_);

        if (currentChecks.changeblock != 0) {
            // neither value can be reduced
            if (maxTx < currentMax.maxtx || maxBalance < currentMax.maxbal) {
                revert valueTooLow();
            }
        }

        _setMaxData(maxTx, maxBalance);
        emit MaxUpdated(maxTx, maxBalance);
    }

    function updateFees(uint256 buy, uint256 sell, uint256 liq) external onlyOwner {
        if (((buy + liq) > 10) || ((sell + liq) > 10)) {
            revert valueTooHigh();
        }
        _setFeesData(buy, sell, liq);
        emit FeesUpdated(buy, sell, liq);
    }

    function reduceLimitBlock(uint256 newBlock) external onlyOwner {
        // once this block has passed, max tx, max balance, and buy cooldown are ignored
        CHECKS memory checks = _getChecksData(data_);
        uint256 oldBlock = checks.limitsblock;

        if (newBlock > oldBlock) {
            revert valueTooHigh();
        }
        _setChecksData(
            checks.changeblock, newBlock, checks.standardmode, checks.feesenabled, checks.cooldown, checks.eoatransfers
        );
        emit LimitBlockReduced(newBlock);
    }

    function reduceCooldown(uint256 newCooldown) external onlyOwner {
        // the number of blocks that must pass before user can perform another tx
        CHECKS memory checks = _getChecksData(data_);
        uint256 oldCooldown = checks.cooldown;

        if (newCooldown > oldCooldown) {
            revert valueTooHigh();
        }
        _setChecksData(
            checks.changeblock,
            checks.limitsblock,
            checks.standardmode,
            checks.feesenabled,
            newCooldown,
            checks.eoatransfers
        );
        emit CooldownReduced(newCooldown);
    }

    function toggleStandardMode() external onlyOwner {
        // standard mode eliminates all custom transfer logic
        CHECKS memory checks = _getChecksData(data_);

        uint256 standardmode = checks.standardmode != 0 ? 0 : uint256(1);
        require(standardmode != uint256(checks.standardmode), "same value");
        _setChecksData(
            checks.changeblock,
            checks.limitsblock,
            standardmode,
            checks.feesenabled,
            checks.cooldown,
            checks.eoatransfers
        );

        if (standardmode != 0) {
            emit StandardModeToggled(true);
        } else {
            emit StandardModeToggled(false);
        }
    }

    function toggleFees() external onlyOwner {
        CHECKS memory checks = _getChecksData(data_);

        uint256 feesenabled = checks.feesenabled != 0 ? 0 : uint256(1);
        require(feesenabled != uint256(checks.feesenabled), "same value");
        _setChecksData(
            checks.changeblock,
            checks.limitsblock,
            checks.standardmode,
            feesenabled,
            checks.cooldown,
            checks.eoatransfers
        );

        if (feesenabled != 0) {
            emit FeesToggled(true);
        } else {
            emit FeesToggled(false);
        }
    }

    function toggleEOATransfers() external onlyOwner {
        // enable or disable transferring tokens between user-owned wallets
        // NOTE: this has no effect on buying or selling
        CHECKS memory checks = _getChecksData(data_);

        uint256 eoatransfers = checks.eoatransfers != 0 ? 0 : uint256(1);
        require(eoatransfers != uint256(checks.eoatransfers), "same value");
        _setChecksData(
            checks.changeblock,
            checks.limitsblock,
            checks.standardmode,
            checks.feesenabled,
            checks.cooldown,
            eoatransfers
        );

        if (eoatransfers != 0) {
            emit EOATransfersToggled(true);
        } else {
            emit EOATransfersToggled(false);
        }
    }

    function manualDistribute(address recipient, uint256 amount) external onlyOwner {
        if (recipient == address(0)) {
            revert sendToZero();
        }
        bool sent;
        // send entire ETH balance
        if (amount == 0) {
            (sent,) = recipient.call{value: address(this).balance}("");
            if (!sent) {
                revert failedToSendETH();
            }
        }
        require(_pair != recipient, "Use addToPair instead.");
        uint256 amountInFinney = amount * 1e15;
        (sent,) = recipient.call{value: (amountInFinney)}(""); // sending 1 ETH = '1000', .1 ETH = '100', .01 ETH = '10'
        if (!sent) {
            revert failedToSendETH();
        }
    }

    function addToPair(uint256 amount) external onlyOwner {
        if (_pair == address(0)) {
            revert notOpen();
        }
        uint256 amountInFinney = amount * 1e15;
        IWETH(WETH).deposit{value: amountInFinney}(); // sending 1 ETH = '1000', .1 ETH = '100', .01 ETH = '10'
        bool sent = IWETH(WETH).transfer(_pair, IWETH(WETH).balanceOf(address(this)));
        if (!sent) {
            revert failedToSendETH();
        }
        IUniswapV2Pair(_pair).sync();
        emit LiqBoosted(WETH, amountInFinney);
    }

    /**
     * @dev
     * This value is used by Chainlink to determine how much gas the callback function is allowed to consume.
     * it has no effect on users or swaps.
     */
    function updateLinkFee(uint256 newValue) external onlyOwner {
        // this function is only needed in case the dev needs to increase the gas cost of the callback function
        if (newValue < _linkFee) {
            revert valueTooLow();
        }
        _linkFee = uint32(newValue);
        emit LinkFeeUpdated(newValue);
    }

    function recoverLink() external onlyOwner {
        // can only reclaim unused LINK after winner has received payout
        require(_winner != address(0));
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}
