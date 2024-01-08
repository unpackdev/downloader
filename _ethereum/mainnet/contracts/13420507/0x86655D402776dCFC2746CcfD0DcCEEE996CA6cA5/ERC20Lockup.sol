// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

abstract contract ERC20Lockup is
    ERC20
{

    //
    // Events
    //

    event TokensLocked(
        address indexed account,
        uint256 indexed amount,
        uint256 expiration
    );

    event TokensUnlocked(
        address indexed account,
        uint256 indexed amount
    );

    //
    // State
    //
    
    /* Token lockup list */

    struct TokenLock
    {
        // Amount of locked tokens that will unlock at a particular time.
        uint256 amount;

        // The timestamp at which these tokens will unlock.
        uint256 unlockTime;
    }

    struct TokenLockInfo
    {
        // This field indicates the first index in `locks` at which to start looking for still active locks.
        uint256 firstValidIndex;

        // Holds all of the locks for a wallet in ascending order of expiration.  Some of these locks may have expired
        // and been zeroed out already.
        TokenLock[] locks;
    }

    mapping ( address => uint256 ) public totalLockedTokens;
    mapping ( address => TokenLockInfo ) public locksPerWallet;

    //
    // State changing functions
    //

    /* Token lockup management */

    /**
     * @dev This function adds a token lock entry for given address, with a given expiration.
     *
     * @param _holder The address for which the tokens should be locked.
     * @param _amount The number of tokens to lock.
     * @param _expiration The timestamp when the tokens unlock.
     */
    function _addTokenLock(
        address _holder,
        uint256 _amount,
        uint256 _expiration
    )
    internal
    {
        TokenLockInfo storage lockInfo = locksPerWallet[_holder];

        totalLockedTokens[_holder] += _amount;
        
        lockInfo.locks.push();
        lockInfo.locks[lockInfo.locks.length - 1] = TokenLock(
            {
                amount: _amount,
                unlockTime: _expiration
            }
        );

        emit TokensLocked(
            _holder,
            _amount,
            _expiration
        );
    }

    /**
     * @dev This function goes through the list of locks for an address, and processes any that have expired.
     *
     * @param _holder The address for which locks should be checked and processed.
     *
     * Requirements:
     *
     * - None.  Anyone can try to process expirations for any address.
     */
    function removeStaleLocks(
        address _holder
    )
    public
    {
        TokenLockInfo storage lockInfo = locksPerWallet[_holder];

        for ( uint256 i = lockInfo.firstValidIndex; i < lockInfo.locks.length; i++ )
        {
            TokenLock storage lock = lockInfo.locks[i];

            // solhint-disable-next-line not-rely-on-time
            if ( block.timestamp > lock.unlockTime )
            {
                // If we found a lock that has not expired yet, stop here, as all further locks are even further in the
                // future.
                break;
            }

            if ( lock.unlockTime != 0 || lock.amount != 0 )
            {
                // We found a lock that has expired (otherwise we would have exited above) and which has not been
                // zeroed, so we need to unlock the tokens and zero out the lock.

                uint256 unlockAmount = lock.amount;

                // Do the unlock.
                totalLockedTokens[_holder] -= unlockAmount;

                // Clear the lock.
                lock.amount = 0;
                lock.unlockTime = 0;

                // Move starting index forward.
                lockInfo.firstValidIndex = i + 1;

                emit TokensUnlocked(
                    _holder,
                    unlockAmount
                );
            }
        }
    }

    /* ERC20 override to implement lockups */

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * @param from See {ERC20-_beforeTokenTransfer}.
     * @param to See {ERC20-_beforeTokenTransfer}.
     * @param amount See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - The `from` address must have enough unlocked tokens for the transfer to complete.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
    internal
    virtual
    override(ERC20)
    {
        super._beforeTokenTransfer(from, to, amount);

        // This is a mint, and so lockups do not apply.
        if ( from == address(0) ) return;

        // If this transfer was already going to fail, see if we can salvage it by freeing any stale locks.
        if ( !( amount <= balanceOfUnlocked(from) ) )
        {
            removeStaleLocks(from);
        }

        require(
            amount <= balanceOfUnlocked(from),
            "ERC20Lockup: unlocked too small"
        );
    }

    //
    // Public views
    //

    /**
     * @dev This function returns the unlocked balance of an address.
     *
     * @param _account The address for which the unlocked balance is being queried.
     *
     * @return The address's balance, after subtracting any locked tokens.
     */
    function balanceOfUnlocked(
        address _account
    )
    public
    view
    returns (uint256)
    {
        return (balanceOf(_account) - totalLockedTokens[_account]);
    }

    /**
     * @dev This function returns the array of lockup entries for a given address.
     *
     * @param _account The address for which the lockups are being queried.
     *
     * @return The array of lockup entries.
     */
    function getLockEntries(
        address _account
    )
    public
    view
    returns (TokenLock[] memory)
    {
        return locksPerWallet[_account].locks;
    }
}