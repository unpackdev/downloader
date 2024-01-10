// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IUserTokenLockup.sol";

contract UserTokenLockup is Initializable, IUserTokenLockup {
    /// @dev Emitted when user `user` creates a lockup with an index of `vaultIndex` containing `amount` of tokens which can be claimed on `unlockDate`
    event LockupCreated(address indexed user, uint32 vaultIndex, uint256 amount, uint64 unlockDate);

    /// @dev Emitted when user `user` claims a lockup with an index of `vaultIndex` containing `amount` of tokens
    event LockupClaimed(address indexed user, uint256 amount, uint32 vaultIndex);

    /// @notice Tokens locked amount
    uint256 public override totalTokensLocked;

    /// @dev [user address] => [lockup status: Encoded(tokensLocked, currentVaultIndex, numberOfActiveVaults)]
    mapping(address => uint256) public encodedLockupStatuses;

    /// @dev [user token lockup key: Encoded(user address, vaultIndex)] => [token lockup value: Encoded(tokenAmount, unlockDate)]
    mapping(uint256 => uint256) public encodedTokenLockups;

    function _UserTokenLockup_init_unchained() internal initializer {}

    /// @dev Get current block timestamp
    /// @return blockTimestamp
    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Should override this function
    function _issueUnlockedTokensToUser(
        address, /*user*/
        uint256 /*amount*/
    ) internal virtual returns (uint256) {
        require(false, "you must override this function");
        return 0;
    }

    /// @notice Encode user lockup status
    ///
    /// @param tokensLocked Tokens locked amount
    /// @param currentVaultIndex The current vault index
    /// @param numberOfActiveVaults The number of activeVaults
    /// @return userLockupStatus Encoded user lockup status
    function createUserLockupStatus(
        uint256 tokensLocked,
        uint32 currentVaultIndex,
        uint32 numberOfActiveVaults
    ) internal pure returns (uint256) {
        return (tokensLocked << 64) | (uint256(currentVaultIndex) << 32) | uint256(numberOfActiveVaults);
    }

    /// @notice Decode an encoded user lockup status
    ///
    /// @param lockupStatus Encoded user lockup status
    /// @return tokensLocked
    /// @return currentVaultIndex
    /// @return numberOfActiveVaults
    function decodeUserLockupStatus(uint256 lockupStatus)
        internal
        pure
        returns (
            uint256 tokensLocked,
            uint32 currentVaultIndex,
            uint32 numberOfActiveVaults
        )
    {
        tokensLocked = lockupStatus >> 64;
        currentVaultIndex = uint32((lockupStatus >> 32) & 0xffffffff);
        numberOfActiveVaults = uint32(lockupStatus & 0xffffffff);
    }

    function createTokenLockupKey(address user, uint32 vaultIndex) internal pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(vaultIndex);
    }

    function decodeTokenLockupKey(uint256 tokenLockupKey) internal pure returns (address user, uint32 vaultIndex) {
        vaultIndex = uint32(tokenLockupKey & 0xffffffff);
        user = address(uint160(tokenLockupKey >> 32));
    }

    function createTokenLockupValue(uint256 tokenAmount, uint64 unlockDate) internal pure returns (uint256) {
        return (uint256(unlockDate) << 192) | tokenAmount;
    }

    function decodeTokenLockupValue(uint256 tokenLockupValue)
        internal
        pure
        returns (uint256 tokenAmount, uint64 unlockDate)
    {
        tokenAmount = tokenLockupValue & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        unlockDate = uint32(tokenLockupValue >> 192);
    }

    /// @notice Get user lockup status with address `user`
    ///
    /// @param user The address of user
    /// @return tokensLocked
    /// @return currentVaultIndex
    /// @return numberOfActiveVaults
    function userLockupStatus(address user)
        public
        view
        returns (
            uint256 tokensLocked,
            uint32 currentVaultIndex,
            uint32 numberOfActiveVaults
        )
    {
        return decodeUserLockupStatus(encodedLockupStatuses[user]);
    }

    /// @notice Get user lockup data
    ///
    /// @param user The address of user
    /// @param vaultIndex vault index
    /// @return tokenAmount
    /// @return unlockDate
    function getTokenLockup(address user, uint32 vaultIndex)
        public
        view
        returns (uint256 tokenAmount, uint64 unlockDate)
    {
        return decodeTokenLockupValue(encodedTokenLockups[createTokenLockupKey(user, vaultIndex)]);
    }

    /// @notice Get next token lockup for user
    ///
    /// @param user The address of user
    /// @return tokenAmount
    /// @return unlockDate
    /// @return vaultIndex
    function getNextTokenLockupForUser(address user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint64 unlockDate,
            uint32 vaultIndex
        )
    {
        (, uint32 currentVaultIndex, ) = userLockupStatus(user);
        vaultIndex = currentVaultIndex;
        (tokenAmount, unlockDate) = getTokenLockup(user, currentVaultIndex);
    }

    function _createTokenLockup(
        address user,
        uint256 amount,
        uint64 unlockDate,
        bool allowAddToFutureVault
    ) internal returns (uint256) {
        require(amount > 0, "amount must be > 0");
        require(user != address(0), "cannot create a lockup for a null user");
        require(unlockDate > block.timestamp, "cannot create a lockup that expires now or in the past!");

        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        require(
            amount < (0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - tokensLocked),
            "cannot store this many tokens in the locked contract at once!"
        );
        tokensLocked += amount;
        uint64 futureDate;

        if (
            numberOfActiveVaults != 0 &&
            currentVaultIndex != 0 &&
            (futureDate = uint64(encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] >> 192)) >=
            unlockDate
        ) {
            require(
                allowAddToFutureVault || futureDate == unlockDate,
                "allowAddToFutureVault must be enabled to add to future vaults"
            );
            // if the current vault's date is later than our unlockDate, add the value to it
            amount +=
                encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] &
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            unlockDate = futureDate;
        } else {
            currentVaultIndex += 1;
            numberOfActiveVaults += 1;
        }

        totalTokensLocked += amount;

        encodedLockupStatuses[user] = createUserLockupStatus(tokensLocked, currentVaultIndex, numberOfActiveVaults);

        encodedTokenLockups[createTokenLockupKey(user, currentVaultIndex)] = createTokenLockupValue(amount, unlockDate);

        return currentVaultIndex;
    }

    /// @dev Claim next token lockup
    function _claimNextTokenLockup(address user) internal returns (uint256) {
        require(user != address(0), "cannot claim for null user");
        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        currentVaultIndex = currentVaultIndex + 1 - numberOfActiveVaults;

        require(tokensLocked > 0 && numberOfActiveVaults > 0 && currentVaultIndex > 0, "user has no tokens locked up!");
        (uint256 tokenAmount, uint64 unlockDate) = getTokenLockup(user, currentVaultIndex);
        require(tokenAmount > 0 && unlockDate <= _getTime(), "cannot claim tokens that have not matured yet!");
        numberOfActiveVaults -= 1;
        encodedLockupStatuses[user] = createUserLockupStatus(
            tokensLocked - tokenAmount,
            numberOfActiveVaults == 0 ? currentVaultIndex : (currentVaultIndex + 1),
            numberOfActiveVaults
        );
        require(totalTokensLocked >= tokenAmount, "not enough tokens locked in the contract!");
        totalTokensLocked -= tokenAmount;
        _issueUnlockedTokensToUser(user, tokenAmount);
        return tokenAmount;
    }

    /// @dev Claim up to next `N` token lockups
    function _claimUpToNextNTokenLockups(address user, uint32 maxNumberOfClaims) internal returns (uint256) {
        require(user != address(0), "cannot claim for null user");
        require(maxNumberOfClaims > 0, "cannot claim 0 lockups");
        (uint256 tokensLocked, uint32 currentVaultIndex, uint32 numberOfActiveVaults) = userLockupStatus(user);
        currentVaultIndex = currentVaultIndex + 1 - numberOfActiveVaults;

        require(tokensLocked > 0 && numberOfActiveVaults > 0 && currentVaultIndex > 0, "user has no tokens locked up!");
        uint256 curTimeShifted = _getTime() << 192;
        uint32 maxVaultIndex = (maxNumberOfClaims > numberOfActiveVaults ? numberOfActiveVaults : maxNumberOfClaims) +
            currentVaultIndex;
        uint256 userShifted = uint256(uint160(user)) << 32;
        uint256 totalAmountToClaim = 0;
        uint256 nextCandiate;

        while (
            currentVaultIndex < maxVaultIndex &&
            (nextCandiate = encodedTokenLockups[userShifted | uint256(currentVaultIndex)]) < curTimeShifted
        ) {
            totalAmountToClaim += nextCandiate & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            currentVaultIndex++;
            numberOfActiveVaults--;
        }
        require(totalAmountToClaim > 0 && currentVaultIndex > 1, "cannot claim nothing!");
        require(totalAmountToClaim <= tokensLocked, "cannot claim more than total locked!");
        if (numberOfActiveVaults == 0) {
            currentVaultIndex--;
        }

        encodedLockupStatuses[user] = createUserLockupStatus(
            tokensLocked - totalAmountToClaim,
            currentVaultIndex,
            numberOfActiveVaults
        );
        require(totalTokensLocked >= totalAmountToClaim, "not enough tokens locked in the contract!");
        totalTokensLocked -= totalAmountToClaim;
        _issueUnlockedTokensToUser(user, totalAmountToClaim);
        return totalAmountToClaim;
    }
}
