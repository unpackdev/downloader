// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./IOFTMintable.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

/**
 * @title Migration
 * @notice This contract facilitates the migration of an old token to a new token.
 * @dev The exchange rate between the old and new tokens is set by the contract owner.
 * Whitelisted addresses can migrate tokens after the deadline.
 * Non-whitelisted addresses can only migrate tokens before the deadline.
 * The contract owner can add or remove addresses from the whitelist or blacklist.
 * The contract owner can also pause or unpause the migration process.
 */
contract Migration is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Paused status of the migration.
    bool public paused;

    /// @notice Old token address to migrate from.
    IERC20 public prevToken;

    /// @notice New token address to migrate to.
    IOFTMintable public newToken;

    /// @notice Exchange rate for swapping old token to new one.
    uint256 public exchangeRate;

    /// @dev Exchange rate divider, hardcoded for the current use case.
    uint256 constant DIVIDER = 1e18;

    /// @notice Migration deadline for non-whitelisted addresses.
    uint256 public immutable deadline;

    /// @dev Set of blacklisted addresses.
    EnumerableSet.AddressSet private blacklist;

    /// @notice Amounts for whitelisted addresses.
    mapping(address => uint256) public whitelistedAmounts;

    /**
     * @notice Event emitted when the exchange rate is set.
     * @param rate exchange rate.
     */
    event SetExchangeRate(uint256 indexed rate);

    /**
     * @notice Event emitted when tokens are migrated.
     * @param account Address which migrated tokens.
     * @param prev Amount of old tokens migrated.
     * @param migrated Amount of new tokens received.
     */
    event Migrated(
        address indexed account,
        uint256 indexed prev,
        uint256 indexed migrated
    );

    /**
     * @notice Event emitted when an address is added to the blacklist.
     * @param account Address added to the blacklist.
     */
    event AddedToBlacklist(address indexed account);

    /**
     * @notice Event emitted when an address is removed from the blacklist.
     * @param account Address removed from the blacklist.
     */
    event RemovedFromBlacklist(address indexed account);

    /**
     * @notice Event emitted when an address is added to the whitelist.
     * @param account Address added to the whitelist.
     * @param amount Amount to whitelist.
     */
    event AddedWhitelistedAmount(
        address indexed account,
        uint256 indexed amount
    );

    /**
     * @notice Event emitted when address is removed from whitelist.
     * @dev White listed amount is set to 0.
     * @param account Address removed from the whitelist.
     */
    event RemovedWhitelistedAmount(address indexed account);

    /**
     * @notice Event emitted when ERC20 tokens are withdrawn by the owner.
     * @param token Address of token withdrawn.
     * @param amount Amount of token withdrawn.
     */
    event EmergencyWithdrawn(address indexed token, uint256 indexed amount);

    /**
     * @notice Event emitted when migration is paused.
     */
    event Paused();

    /**
     * @notice Event emitted when migration is unpaused.
     */
    event Unpaused();

    /**
     * @notice Modifier to check if the caller is in the blacklist.
     */
    modifier isBlacklist() {
        require(
            !blacklist.contains(msg.sender),
            "Address is listed in blacklist"
        );
        _;
    }

    /**
     * @dev Constructor.
     * @param _prev address of previous token.
     * @param _migrated address of new token.
     * @param _rate exchange rate.
     * @param _deadline migration deadline (timestamp).
     */
    constructor(
        address _prev,
        address _migrated,
        uint256 _rate,
        uint256 _deadline
    ) {
        require(_prev != address(0), "Invalid address");
        require(_migrated != address(0), "Invalid address");
        require(_rate != 0, "Invalid exchange rate");
        require(_deadline >= block.timestamp + 7 days, "Invalid deadline");

        prevToken = IERC20(_prev);
        newToken = IOFTMintable(_migrated);
        exchangeRate = _rate;
        deadline = _deadline;

        emit SetExchangeRate(_rate);
    }

    ///////////////////////
    /// User Functions  ///
    ///////////////////////

    /**
     * @notice Migrate old tokens to new tokens.
     * @dev This function can only be called by non-blacklisted addresses.
     * @dev Account needs first to approve the contract to spend the old tokens.
     * @dev If the deadline is passed, the account needs to have whitelisted amount.
     * @param _amount amount of old tokens to migrate.
     */
    function migrate(uint256 _amount) external isBlacklist {
        require(
            block.timestamp <= deadline ||
                whitelistedAmounts[msg.sender] >= _amount,
            "Deadline; whitelisted < _amount"
        );
        require(_amount != 0, "Invalid migration amount");
        require(!paused, "Migration paused");

        // 1. receive previous token
        prevToken.safeTransferFrom(msg.sender, address(this), _amount);

        // 2. migrate to new token
        uint256 migratedAmt = (_amount * exchangeRate) / DIVIDER;
        require(migratedAmt != 0, "Invalid migrated amount");
        if (block.timestamp > deadline) {
            whitelistedAmounts[msg.sender] -= _amount;
        }

        newToken.mint(msg.sender, migratedAmt);
        emit Migrated(msg.sender, _amount, migratedAmt);
    }

    ///////////////////////
    /// Owner Functions ///
    ///////////////////////

    /**
     * @notice Set exchange rate.
     * @dev This function can only be called by the contract owner.
     * @param _rate new exchange rate.
     */
    function setExchangeRate(uint256 _rate) external onlyOwner {
        require(_rate != 0, "Invalid exchange rate");

        exchangeRate = _rate;
        emit SetExchangeRate(_rate);
    }

    /**
     * @notice Add whitelisted amounts for the accounts.
     * @dev This function can only be called by the contract owner.
     * @dev Both `_list` and `_amounts` arrays must have the same length.
     * @param _list array of accounts.
     * @param _amounts array of amounts to whitelist.
     */
    function addWhitelistedAmounts(
        address[] calldata _list,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_list.length != 0, "Invalid array length");
        require(_list.length == _amounts.length, "Array length mismatch");

        for (uint i; i < _list.length; ) {
            whitelistedAmounts[_list[i]] += _amounts[i];
            emit AddedWhitelistedAmount(_list[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Remove whitelisted amount of the account.
     * @dev This function can only be called by the contract owner.
     * @param _list array of accounts.
     */
    function removeWhitelistedAmounts(
        address[] memory _list
    ) external onlyOwner {
        require(_list.length != 0, "Invalid array length");

        for (uint i; i < _list.length; ) {
            whitelistedAmounts[_list[i]] = 0;
            emit RemovedWhitelistedAmount(_list[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Add addresses to blacklist.
     * @dev This function can only be called by the contract owner.
     * @param _list array of blacklisted accounts.
     */
    function addBlacklist(address[] memory _list) external onlyOwner {
        require(_list.length != 0, "Invalid array length");

        for (uint i; i < _list.length; ) {
            if (!blacklist.contains(_list[i])) {
                blacklist.add(_list[i]);
                emit AddedToBlacklist(_list[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Remove addresses from blacklist.
     * @dev This function can only be called by the contract owner.
     * @param _list array of accounts.
     */
    function removeBlacklist(address[] memory _list) external onlyOwner {
        require(_list.length != 0, "Invalid array length");

        for (uint i; i < _list.length; ) {
            if (blacklist.contains(_list[i])) {
                blacklist.remove(_list[i]);
                emit RemovedFromBlacklist(_list[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Emergency withdraw ERC20 tokens.
     * @dev This function can only be called by the contract owner.
     * @param _token address of ERC20 token to withdraw.
     */
    function emergencyWithdraw(IERC20 _token) external onlyOwner {
        require(address(_token) != address(prevToken), "Invalid address");
        uint256 _amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), _amount);

        emit EmergencyWithdrawn(address(_token), _amount);
    }

    /**
     * @notice Pause migration.
     * @dev This function can only be called by the contract owner.
     */
    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    /**
     * @notice Unpause migration.
     * @dev This function can only be called by the contract owner.
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }
}
