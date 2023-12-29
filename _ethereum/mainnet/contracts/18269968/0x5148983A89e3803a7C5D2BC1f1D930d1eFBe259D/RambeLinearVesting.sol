// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";

/// @title Linear Vesting With Cliff
/// @notice Smart contract to implement linear vesting, cliff for users by owner
/// uses Owanble2Step, SafeERC20 and ReentrancyGuard from OZ
contract RambeLinearVestingWithCliff is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //// CUSTOM ERRORS ////
    error ZeroAddressNotAllowed();
    error AlreadyClaimed();
    error ZeroAmountNotAllowed();
    error ArrayLengthMismatch();
    error ClaimNotStartedYet();
    error CannotClaimNativeToken();
    error VestingPeriodIsTooLong();
    error CliffIsTooLong();
    error TokenTransferFailed();

    /// @notice token address
    IERC20 private immutable token;

    /// @notice user struct with all information for user vesting
    /// allocatedTokens: total Tokens allocation
    /// claimedTokens: total tokens claimed
    /// vestingStartTime: When vesting begins
    /// vestingEndTime: when vesting ends
    /// vesting Duration: vesting duration 
    struct User {
        uint256 totalTokens;
        uint256 claimedTokens;
        uint256 vestingStartTime;
        uint256 vestingEndTime;
        uint256 vestingDuration;
    }

    /// @dev total lockers ever created
    uint256[] private indexedLockers;
    /// @dev list of users to which tokens are alloted
    address[] private userIndex;
    /// @dev locker id to user
    mapping(uint256 => address) private lockerOwnerAddress;
    /// @dev current locker id
    uint256 private currentLockerID = 1;

    /// @notice mapping for users struct
    mapping(address => mapping(uint256 => User)) public users;
    /// event emitted when user claime token
    event TokensClaimed(address indexed user, uint256 indexed amount);
    event MultipleVestingAdded(
        address[] indexed users,
        uint256[] indexed tokenAmounts
    );
    event VestingAdded(address indexed user, uint256 indexed tokens);

    /// @dev create presale vesting smartcontract using OZ ownable, safeERC20.
    /// initialized the token address value
    constructor(address _token) {
        if (_token == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        token = IERC20(_token);
    }

    /// @notice owner set vesting for account
    /// @param account: user address
    /// @param amount: total tokens to be alloted in wei format
    /// @param cliff: cliff period in days
    /// @param vestingPeriod: vesting duration in days
    /// Example -- (0x123, 120e18, 12, 180)
    /// means address 0x123 has been alloted with 120 tokens, whose vesting period is 6 months
    /// His vesting start time will be 12 days from now.
    /// means he can start claiming his unlocked amount after it.
    function addVesting(
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 vestingPeriod
    ) external onlyOwner {
        if (account == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (amount == 0) {
            revert ZeroAmountNotAllowed();
        }

        /// Max cliff for vesting is 6 months
        if(cliff > 180) {
            revert CliffIsTooLong();
        }
            
        //Max vesting period could be of 2 years
        if(vestingPeriod > 730) {
            revert VestingPeriodIsTooLong();
        }
        uint256 vestStart = block.timestamp + (cliff * 1 days);
        uint256 vestEnd = vestStart + (vestingPeriod * 1 days);
        uint256 vestPeriod = vestingPeriod * 1 days;
        uint256 lockerId = currentLockerID;
        lockerOwnerAddress[lockerId] = account;
        userIndex.push(account);
        indexedLockers.push(lockerId);
        currentLockerID = lockerId + 1;
        users[account][lockerId] = User({
            totalTokens: amount,
            claimedTokens: 0,
            vestingStartTime: vestStart,
            vestingEndTime: vestEnd,
            vestingDuration: vestPeriod
        });

        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        if(balanceAfter - balanceBefore != amount){
            revert TokenTransferFailed();
        }
        emit VestingAdded(account, amount);
    }

    /// @notice add vesting to multiple accounts with different cliff and vesting period
    /// @param accounts: users address array
    /// @param amounts: amounts array to alloted for each user
    /// @param cliffs: cliff period in days
    /// @param vestingPeriods:vesting duration in days
    function addMultipleVesting(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256[] calldata cliffs,
        uint256[] calldata vestingPeriods
    ) external onlyOwner {
        uint256 accountsLength = accounts.length;
        uint256 amountsLength = amounts.length;
        uint256 cliffsLength = cliffs.length;
        uint256 vestingPeriodsLength = vestingPeriods.length;
        if (accountsLength != amountsLength) {
            revert ArrayLengthMismatch();
        }
        if(accountsLength != cliffsLength){
            revert ArrayLengthMismatch();
        }
        if(accountsLength != vestingPeriodsLength){
            revert ArrayLengthMismatch();
        }
        uint256 sum = 0;
        for (uint256 i = 0; i < accountsLength; ++i) {
            address account = accounts[i];
            uint256 amount = amounts[i];
            uint256 cliff = cliffs[i];
            uint256 vestingPeriod = vestingPeriods[i];

            if (account == address(0)) {
                revert ZeroAddressNotAllowed();
            }
            if (amount == 0) {
                revert ZeroAmountNotAllowed();
            }
            
            /// Max cliff for vesting is 6 months
            if(cliff > 180) {
                revert CliffIsTooLong();
            }
            
            //Max vesting period could be of 2 years
            if(vestingPeriod > 730) {
                revert VestingPeriodIsTooLong();
            }

            sum = sum + amount;

            uint256 vestStart = block.timestamp + (cliff * 1 days);
            uint256 vestEnd = vestStart + (vestingPeriod * 1 days);
            uint256 vestPeriod = vestingPeriod * 1 days;
            uint256 lockerId = currentLockerID;
            lockerOwnerAddress[lockerId] = account;
            userIndex.push(account);
            indexedLockers.push(lockerId);
            currentLockerID = lockerId + 1;

            users[account][lockerId] = User({
                totalTokens: amount,
                claimedTokens: 0,
                vestingStartTime: vestStart,
                vestingEndTime: vestEnd,
                vestingDuration: vestPeriod
            });
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), sum);
        uint256 balanceAfter = token.balanceOf(address(this));
        if(balanceAfter - balanceBefore != sum){
            revert TokenTransferFailed();
        }
        emit MultipleVestingAdded(accounts, amounts);
    }

    /// @notice add vesting to multiple accounts having Same cliff and vesting duration
    /// @param accounts: users address array
    /// @param amounts: amounts array to alloted for each user
    /// @param cliff: cliff period in days
    /// @param vestingPeriod:vesting duration in days
    function addMultipleVestingWithSameCliffAndVestingDuration(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 cliff,
        uint256 vestingPeriod
    ) external onlyOwner {
        uint256 accountsLength = accounts.length;
        uint256 amountsLength = amounts.length;
        if (accountsLength != amountsLength) {
            revert ArrayLengthMismatch();
        }
        /// Max cliff for vesting is 6 months
        if(cliff > 180) {
           revert CliffIsTooLong();
        }
            
        //Max vesting period could be of 2 years
        if(vestingPeriod > 730) {
           revert VestingPeriodIsTooLong();
        }
        uint256 sum = 0;
        for (uint256 i = 0; i < accountsLength; ++i) {
            address account = accounts[i];
            uint256 amount = amounts[i];

            if (account == address(0)) {
                revert ZeroAddressNotAllowed();
            }
            if (amount == 0) {
                revert ZeroAmountNotAllowed();
            }

            sum = sum + amount;

            uint256 vestStart = block.timestamp + (cliff * 1 days);
            uint256 vestEnd = vestStart + (vestingPeriod * 1 days);
            uint256 vestPeriod = vestingPeriod * 1 days;
            uint256 lockerId = currentLockerID;
            lockerOwnerAddress[lockerId] = account;
            userIndex.push(account);
            indexedLockers.push(lockerId);
            currentLockerID = lockerId + 1;

            users[account][lockerId] = User({
                totalTokens: amount,
                claimedTokens: 0,
                vestingStartTime: vestStart,
                vestingEndTime: vestEnd,
                vestingDuration: vestPeriod
            });
        }
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), sum);
        uint256 balanceAfter = token.balanceOf(address(this));
        if(balanceAfter - balanceBefore != sum){
            revert TokenTransferFailed();
        }
        emit MultipleVestingAdded(accounts, amounts);
    }

    ///@notice  users can claim there tokens using this function
    function claim(uint256 lockerId) external nonReentrant {
        User storage user = users[msg.sender][lockerId];
        if (block.timestamp < user.vestingStartTime) {
            revert ClaimNotStartedYet();
        }
        if (user.claimedTokens == user.totalTokens) {
            revert AlreadyClaimed();
        }
        uint256 unlockedTokens = getUnlockedAmount(lockerId, msg.sender);

        user.claimedTokens = user.claimedTokens + unlockedTokens;
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, unlockedTokens);
        uint256 balanceAfter = token.balanceOf(address(this));
        if(balanceBefore - balanceAfter != unlockedTokens){
            revert TokenTransferFailed();
        }
        emit TokensClaimed(msg.sender, unlockedTokens);
    }

    /// @dev owner can claim other erc20 tokens, if accidently sent by someone
    /// @param _token: token address to be rescued
    /// @param _amount: amount to rescued
    /// Requirements --
    /// Cannot claim native token
    function claimOtherERC20(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(token)) {
            revert CannotClaimNativeToken();
        }
        IERC20 tkn = IERC20(_token);
        uint256 balanceBefore = tkn.balanceOf(address(this));
        tkn.safeTransfer(owner(), _amount);
        uint256 balanceAfter = tkn.balanceOf(address(this));
        if(balanceBefore - balanceAfter != _amount){
            revert TokenTransferFailed();
        }
    }

    /// @notice returns the unlocked amount for particular lock id
    /// @param lockerId: locker id of user
    /// @param account: user address
    function getUnlockedAmount(uint256 lockerId, address account) public view returns (uint256) {
        User storage user = users[account][lockerId];
        uint256 unlockedTokens;
        if (block.timestamp < user.vestingStartTime) {
            unlockedTokens = 0;
        } else if (block.timestamp >= user.vestingEndTime){
            unlockedTokens = user.totalTokens - user.claimedTokens;
        }else {
            uint256 timeElapsed = block.timestamp - user.vestingStartTime;
            uint256 releaseAmount = (user.totalTokens * timeElapsed) /
                user.vestingDuration;
            unlockedTokens = releaseAmount - user.claimedTokens;
        }
        return unlockedTokens;
    }

    /// @return _lockers id's array for user
    /// @param _user: user address
    function getLockersListForUser(
        address _user
    ) external view virtual returns (uint256[] memory _lockers) {
        uint256[] memory _indexedLockers = indexedLockers;
        bool[] memory _isUserLocker = new bool[](_indexedLockers.length);
        uint256 indexedTokenCount = _indexedLockers.length;
        uint256 userLockerCount = 0;

        for (uint256 i = 0; i < indexedTokenCount; i++) {
            _isUserLocker[i] = lockerOwnerAddress[_indexedLockers[i]] == _user;
            if (_isUserLocker[i]) userLockerCount += 1;
        }

        _lockers = new uint256[](userLockerCount);
        uint256 count = 0;
        for (uint256 i = 0; i < indexedTokenCount; i++) {
            if (_isUserLocker[i]) {
                _lockers[count] = _indexedLockers[i];
                count += 1;
            }
        }
    }
}
