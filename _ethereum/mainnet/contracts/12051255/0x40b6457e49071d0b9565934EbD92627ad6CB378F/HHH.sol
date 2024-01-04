// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "./Initializable.sol";
import "./ERC20tokenPresetModified.sol";
import "./IERC1404.sol";
import "./IERC165.sol";

/// @title HHH Himalaya HEX HPay
/**
 * @dev HHH is the main ERC20 compatible token with additional functionality provided by Himalaya Group
 * - 24 hours delays for non whitelisted users
 * - ability for Admin to recover stolen funds from pending deposits locked in 24 hours delay.
 * - connects with HManagementContract to check if users are whitelisted.
 *
 * See HManagementContract to find out more about whitelisting.
 *
 * The contract uses {ERC20PresetMinterPauserUpgradeableModified} (slightly modified version of OpenZeppelin of {ERC20PresetMinterPauserUpgradeable})
 * to manage minting, burning and pausing activities
 */
contract HHH is ERC20PresetMinterPauserUpgradeableModified, IERC1404, IERC165 {
    /// @dev Whitelisting role
    bytes32 private constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    /**
     * @dev Mapping of users to {Deposit}. It stores amount of tokens unavailable for immidiate transfer
     * for not whitelisted users.
     *
     * Tokens locked here are removed after {nonWhitelistedDelay}. Any changes to pendingDeposits do not change
     * user's balance. For example, if user has 100 tokens, but 60 of them are in pendingDeposits, the user's
     * balance is still 100 tokens, but available balance to spend would be 40. If 30 tokens in pendingDeposits
     * exceed the {nonWhitelistedDelay}, they will be removed from the deposits and the user's available balance
     * will become 70, while still have a full balance of 100.
     */
    mapping(address => Deposit[]) public pendingDeposits;

    /// @dev Minimum amount allowed to transfer
    uint256 public nonWhitelistedDustThreshold; // This is to prevent attacker making multiple small deposits and preventing legitimate user from receiving deposits

    /**
     * @dev Emitted when 'amount' is recovered from {pendingDeposits} in 'from' account
     * to 'to' account.
     */
    event RecoverFrozen(address from, address to, uint256 amount);

    /**
     * @dev Object which is stored in {pendingDeposits} mapping. It stored 'amount' deposited at 'time'.
     * It is used when non whitelisted user received funds.
     */
    struct Deposit {
        uint256 time;
        uint256 amount;
    }

    /// @dev Only address which is set to Admin role can call functions with this modifier
    modifier onlyAdmin virtual {
        require(managementContract.hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have ADMIN ROLE");
        _;
    }

    modifier onlyManagementContract virtual {
        require(_msgSender() == address(managementContract), "only management contract can call this function");
        _;
    }

    /**
     * @dev Sets the values for {name}, {symbol} and {HManagementContract}, initializes {nonWhitelistedDustThreshold} with
     * a default value of 0.1 of the coin.
     *
     * To select a different value for {nonWhitelistedDustThreshold}, use {setNonWhitelistedDustThreshold}.
     *
     * This function also initialized {ERC20PresetMinterPauserUpgradeableModified} extension contract.
     *
     * 'name' and 'symbol' values are immutable: they can only be set once during
     *
     * To update {HManagementContract}, use {changeManagementContract}
     * construction.
     */
    function initialize(string memory name, string memory symbol, address managementContractAddress) public virtual override initializer {
        require(managementContractAddress != address(0), "Management contract address cannot be zero.");
        ERC20PresetMinterPauserUpgradeableModified.initialize(name, symbol, managementContractAddress);

        nonWhitelistedDustThreshold = 10**17; // 0.1 of the coin
    }

    /**
     * @dev Updates the {nonWhitelistedDustThreshold}
     *
     * Requirements:
     *
     * - the caller must be admin - {onlyAdmin} modifier is applied.
     */
    function setNonWhitelistedDustThreshold(uint256 _nonWhitelistedDustThreshold) external virtual onlyAdmin {
        nonWhitelistedDustThreshold = _nonWhitelistedDustThreshold;
    }

    /**
     * @dev Atomically recovers stolen funds that are still in pending deposits.
     * In case of law enforcements notifying Himalaya Group about a theft, Himalaya Group
     * is able to freeze the account and recover funds from pendingDeposit.
     *
     * It calls {_transfer} function to move `amount` from theif's `from` address to
     * victim's `to` address
     *
     * If `from` is not whitelisted, it calls {removeAllPendingDeposits}.
     * See more at {HManagementContract.whitelist})
     *
     * Emits {RecoverFrozen}
     *
     * Requirements:
     *
     * - the `from` address must be frozen. See more at {HManagementContract.freeze}
     * - only Admin can call this function
     */
    function recoverFrozenFunds(address from, address to, uint256 amount) external virtual onlyAdmin {
        require(to != address(0), "Address 'to' cannot be zero.");
        require(managementContract.isFrozen(from), "Need to be frozen first");

        managementContract.unFreeze(from); // Make sure this contract has WHITELIST_ROLE on management contract
        if (!managementContract.isWhitelisted(from)) {
            removeAllPendingDeposits(from);
        }
        _transfer(from, to, amount);
        managementContract.freeze(from);

        emit RecoverFrozen(from, to, amount);
    }

    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant ERROR_REASON_GLOBAL_PAUSE = "Global pause is active";
    string public constant ERROR_REASON_TO_FROZEN = "`to` address is frozen";
    string public constant ERROR_REASON_FROM_FROZEN = "`from` address is frozen";
    string public constant ERROR_REASON_NOT_ENOUGH_UNLOCKED = "User's unlocked balance is less than transfer amount";
    string public constant ERROR_REASON_BELOW_THRESHOLD = "Deposit for non-whitelisted user is below threshold";
    string public constant ERROR_REASON_PENDING_DEPOSITS_LENGTH = "Too many pending deposits for non-whitelisted user";
    string public constant ERROR_DEFAULT = "Generic error message";

    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant ERROR_CODE_GLOBAL_PAUSE = 1;
    uint8 public constant ERROR_CODE_TO_FROZEN = 2;
    uint8 public constant ERROR_CODE_FROM_FROZEN = 3;
    uint8 public constant ERROR_CODE_NOT_ENOUGH_UNLOCKED = 4;
    uint8 public constant ERROR_CODE_BELOW_THRESHOLD = 5;
    uint8 public constant ERROR_CODE_PENDING_DEPOSITS_LENGTH = 6;

    
    /**
    * @dev Evaluates whether a transfer should be allowed or not.
    * Inspired by INX Token: https://etherscan.io/address/0xBBC7f7A6AADAc103769C66CBC69AB720f7F9Eae3#code
    */
    modifier notRestricted (address from, address to, uint256 value) virtual {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     * It also calls the extended contract's {ERC20Pausable._beforeTokenTransfer}.
     * The main purpose is to ensure that the 'from' account has enough unlocked balance
     * and to lock 'amount' in {pendingDeposits} if 'to' is not whitelisted.
     * Calling conditions:
     * - if `to` is SuperWhitelisted and the user doesn't have enough unlocked balance,
     * a part of the pendingDeposits will be unlocked to allow for instant transfer
     * - if 'from' is not Whitelisted, the 'from' is required to have at least 'amount' in available balance
     * - if 'to' is not Whitelisted, the 'to' account must have less {pendingDeposits} than {nonWhitelistedDepositLimit} or
     * there must be some pendingDeposits which will be released during the transfer as they are older than {nonWhitelistedDelay}
     * - `amount` must be bigger or equal to {nonWhitelistedDustThreshold}
     * Requirements:
     *
     * - The Global pause is not actived through {HManagementContract.pause}
     * - 'to' and 'from' addresses must not be frozen
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override notRestricted(from, to, amount) {
        super._beforeTokenTransfer(from, to, amount);

        if (managementContract.isSuperWhitelisted(to)) {
            // Unlock part of the locked balance, so user can make transfer to the superwhitelisted.
            // Do not unlock everything - it would be too easy to exploit it to circumvent the delay.
            // We unlock balance only when sending to SuperWhitelisted
            // Otherwise the simple check `unlockedBalance(from) >= amount`
            uint256 ub = unlockedBalance(from);

            if (ub < amount) {
                uint256 amountToUnlock = amount.sub(ub);
                releaseDepositsForSuperWhitelisted(from, amountToUnlock);
            }
        } else {
            if (!managementContract.isWhitelisted(to)) {
                Deposit memory deposit = Deposit({time: now, amount: amount}); // solium-disable-line security/no-block-members
                pendingDeposits[to].push(deposit);
            }
        }
    }

    /**
     * @dev Member of ERC-1404 Simple Restricted Token Standard: https://github.com/ethereum/EIPs/issues/1404
     */
    function detectTransferRestriction (address from, address to, uint256 value) public virtual override view returns (uint8) {
        // There are other typical error conditions that are part of ERC20 standard, not our custom code
        // "ERC20Pausable: token transfer while paused"
        // "ERC20: transfer amount exceeds balance"

        if (managementContract.paused()) {
            return ERROR_CODE_GLOBAL_PAUSE;
        }
        
        if (managementContract.isFrozen(to)) {
            return ERROR_CODE_TO_FROZEN;
        }

        if (managementContract.isFrozen(from)) {
            return ERROR_CODE_FROM_FROZEN;
        }

        if (!managementContract.isSuperWhitelisted(to)) {
            
            if (!managementContract.isWhitelisted(from)) {
                if (! (unlockedBalance(from) >= value)) {
                    return ERROR_CODE_NOT_ENOUGH_UNLOCKED;
                }
            }

            if (!managementContract.isWhitelisted(to)) {
                uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();
                uint256 nonWhitelistedDepositLimit = managementContract.nonWhitelistedDepositLimit();
                uint256 pendingDepositsLength = pendingDeposits[to].length;

                if (! (pendingDepositsLength < nonWhitelistedDepositLimit || (now > pendingDeposits[to][pendingDepositsLength - nonWhitelistedDepositLimit].time + nonWhitelistedDelay))) { // solium-disable-line security/no-block-members
                    return ERROR_CODE_PENDING_DEPOSITS_LENGTH;
                }

                if (! (value >= nonWhitelistedDustThreshold)) {
                    return ERROR_CODE_BELOW_THRESHOLD;
                }
            }
        }
    }

    /**
     * @dev Member of ERC-1404 Simple Restricted Token Standard: https://github.com/ethereum/EIPs/issues/1404
     */
    function messageForTransferRestriction (uint8 restrictionCode) public virtual override view returns (string memory) {
        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        } else if (restrictionCode == ERROR_CODE_GLOBAL_PAUSE) {
            return ERROR_REASON_GLOBAL_PAUSE;
        } else if (restrictionCode == ERROR_CODE_TO_FROZEN) {
            return ERROR_REASON_TO_FROZEN;
        } else if (restrictionCode == ERROR_CODE_FROM_FROZEN) {
            return ERROR_REASON_FROM_FROZEN;
        } else if (restrictionCode == ERROR_CODE_NOT_ENOUGH_UNLOCKED) {
            return ERROR_REASON_NOT_ENOUGH_UNLOCKED;
        } else if (restrictionCode == ERROR_CODE_BELOW_THRESHOLD) {
            return ERROR_REASON_BELOW_THRESHOLD;
        } else if (restrictionCode == ERROR_CODE_PENDING_DEPOSITS_LENGTH) {
            return ERROR_REASON_PENDING_DEPOSITS_LENGTH;
        } else {
            return ERROR_DEFAULT;
        }
    }

    /**
     * @dev Member of ERC-165 Standard Interface Detection: https://eips.ethereum.org/EIPS/eip-165
     * See issue on internal Github to see how it is calculated: https://ec2-18-130-7-129.eu-west-2.compute.amazonaws.com/Himalaya-Exchange/hpay-token/issues/39
     */
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0xab84a5c8;
    }

    /**
     * @dev Releases the `amount` from `from` user's {pendingDeposits}.
     * It is used only in one specific instance: sending to SuperWhitelisted
     * There is no need to remove old pending deposits, that happens only during whitelisting
     */
    function releaseDepositsForSuperWhitelisted(address from, uint256 amount) internal virtual {
        uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();

        uint256 pendingDepositsLength = pendingDeposits[from].length;

        // Iterating starting from the most recent deposits. Cannot check `>= 0`, as the `i--` will cause underflow and a very large integer
        // Second condition in the loop is checking the time. Unlocking from pending deposits makes sense only for the recent deposits that are within timelock
        for (uint256 i = pendingDepositsLength - 1; i != uint256(-1) && pendingDeposits[from][i].time > now - nonWhitelistedDelay; i--) { // solium-disable-line security/no-block-members
            if (amount < pendingDeposits[from][i].amount) {
                pendingDeposits[from][i].amount = pendingDeposits[from][i].amount.sub(amount);
                break;
            } else {
                amount = amount.sub(pendingDeposits[from][i].amount);
                pendingDeposits[from].pop();
            }
        }
    }

    /**
     * @dev Removes all pending deposits. See more at {pendingDeposits}
     */
    function removeAllPendingDeposits(address from) internal virtual {
        delete pendingDeposits[from];
    }

    /**
     * @dev Removes all pending deposits. See more at {pendingDeposits}. Can be called only from management contract.
     *
     * Requirements:
     *
     * - the caller must be `managementContract`.
     */
    function removeAllPendingDepositsExternal(address addr) external virtual onlyManagementContract {
        delete pendingDeposits[addr];
    }

    /**
     * @dev Adds total balance of `addr` to {pendingDeposits} with timestamp of the block.. Can be called only from management contract.
     *
     * Requirements:
     *
     * - the caller must be `managementContract`.
     */
    function putTotalBalanceToLock(address addr) external virtual onlyManagementContract {
        pendingDeposits[addr].push(Deposit({time: now, amount: balanceOf(addr)})); // solium-disable-line security/no-block-members
    }

    //////////////////////// VIEW
    /**
     * @dev Calculates `user`'s balance that is locked in {pendingDeposits}
     */
    function lockedBalance(address user) public virtual view returns (uint256) {
        uint256 balanceLocked = 0;
        uint256 pendingDepositsLength = pendingDeposits[user].length;
        uint256 nonWhitelistedDelay = managementContract.nonWhitelistedDelay();

        // Iterating starting from the most recent deposits. Cannot check `>= 0`, as the `i--` will cause underflow and a very large integer
        // Second condition in the loop is checking the time. We calculate `balanceLocked` using deposits that happened within `nonWhitelistedDelay` (most likely 24 hours)
        for (uint256 i = pendingDepositsLength - 1; i != uint256(-1) && pendingDeposits[user][i].time > now - nonWhitelistedDelay; i--) { // solium-disable-line security/no-block-members
            balanceLocked = balanceLocked.add(pendingDeposits[user][i].amount);
        }
        return balanceLocked;
    }

    /**
     * @dev Calculates `user`'s available balance for instant transfer
     * by subtracting the balance locked in {pendingDeposits} from the over
     * balance.
     */
    function unlockedBalance(address user) public virtual view returns (uint256) {
        return balanceOf(user).sub(lockedBalance(user));
    }
}
