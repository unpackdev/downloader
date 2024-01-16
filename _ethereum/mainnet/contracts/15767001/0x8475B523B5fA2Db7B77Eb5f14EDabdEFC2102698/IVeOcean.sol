// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeOcean {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    // State view functions

    function token() external view returns (address);

    function supply() external view returns (uint256);

    // mapping(address => LockedBalance) locked;
    function locked(address addr) external view returns (LockedBalance memory);

    function epoch() external view returns (uint256);

    // Aragon's view methods for compatibility
    function controller() external view returns (address);

    function transfersEnabled() external view returns (bool);

    // ERC20
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint256);

    // Checker for whitelisted (smart contract) wallets which are allowed to deposit
    // The goal is to prevent tokenizing the escrow
    function smart_wallet_checker() external view returns (address);

    function future_smart_wallet_checker() external view returns (address);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    /**
     * @notice Get the most recently recorded rate of voting power decrease for `addr`
     * @param addr Address of the user wallet
     * @return Value of the slope
     */
    function get_last_user_slope(address addr) external view returns (int128);

    /**
     * @notice Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function user_point_history__ts(address _addr, uint256 _idx)
        external
        view
        returns (uint256);

    /**
     * @notice Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function locked__end(address _addr) external view returns (uint256);

    /**
     * @notice Get the current voting power for `addr`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address addr, uint256 _t)
        external
        view
        returns (uint256);

    /**
     * @notice Measure voting power of `addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply(uint256 t) external view returns (uint256);

    /**
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256);

    /**
     * @notice Deposit `_value` tokens for `_addr` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
     * @param _addr User's wallet address
     * @param _value Amount to add to user's lock
     */
    function deposit_for(address _addr, uint256 _value) external;

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external;

    /**
     * @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
     * @param _value Amount to deposit
     * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
     */
    function create_lock(uint256 _value, uint256 _unlock_time) external;

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increase_amount(uint256 _value) external;

    /**
     * @notice Extend the unlock time for `msg.sender` to `_unlock_time`
     * @param _unlock_time New epoch time for unlocking
     */
    function increase_unlock_time(uint256 _unlock_time) external;

    function changeController(address _newController) external;
}
