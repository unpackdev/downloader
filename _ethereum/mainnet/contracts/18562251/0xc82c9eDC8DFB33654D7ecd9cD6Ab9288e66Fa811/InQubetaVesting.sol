// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Address.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

contract InQubetaVesting is Pausable, AccessControl {
    using SafeERC20 for IERC20;

    /// @notice The address of the ERC20 token is vesting and receiving
    IERC20 public immutable vestingToken;

    /// @notice Provides information about the added addresses information
    struct VestingInfo {
        uint vestingAmount; // The total amount of tokens to be vested
        uint unvestedAmount; // The amount of tokens that have not yet been receiving
        uint vestingStart; // The time when the lock-in period begins
        uint vestingReleaseStartDate; // The time of the end of the blocking period
        uint vestingEnd; // The time when the lock-up period ends
        uint vestingSecondPeriod; // The duration of the vest period after the lockup period
    }

    /// @notice Info for user addresses which to their vests nonce
    mapping(address => uint) public vestingNonces;
    /// @notice Info for user addresses to their vesting schedule
    mapping(address => mapping(uint => VestingInfo)) public vestingInfos;
    /// @notice Info for user addresses authorization status to vesting and receiving tokens
    mapping(address => bool) public vesters;

    /// @notice Indicating whether anyone can vesting tokens on behalf of users
    bool public canAnyoneUnvest;

    /// @notice Emitted when a vester's status has been updated
    event UpdateVesters(address vester, bool isActive);
    /// @notice Emitted when tokens are blocked
    event Vest(
        address indexed user,
        uint vestNonce,
        uint amount,
        uint indexed vestingFirstPeriod,
        uint vestingSecondPeriod,
        uint vestingReleaseStartDate,
        uint vestingEnd
    );
    /// @notice Emitted when a user's a tokens are receiving
    event Unvest(address indexed user, uint amount);
    /// @notice Emitted when an transferring funds to the specified wallet
    event Rescue(address indexed to, uint amount);
    /// @notice Emitted when an transferring funds of the selected token contract to the specified wallet
    event RescueToken(address indexed to, address indexed token, uint amount);
    /// @notice Emitted when the flag canAnyoneUnvest is updated
    event ToggleCanAnyoneUnvest(bool indexed canAnyoneUnvest);

    /**
     * @notice Initializes the contract
     * @param vestingTokenAddress The address of the ERC20 token being vesting
     */
    constructor(address vestingTokenAddress, address ownerAddress) {
        require(
            Address.isContract(vestingTokenAddress),
            "InQubetaVesting: Not a contract"
        );
        require(ownerAddress != address(0), "InQubetaVesting: Zero address");

        _grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        vestingToken = IERC20(vestingTokenAddress);
    }

    /**
     * @notice External function for users to vest locking
     * @param user The address of the user who will vests tokens
     * @param amount The amount of tokens to be vested
     * @param vestingFirstPeriod The duration of the first vesting period, in seconds
     * @param vestingSecondPeriod The duration of the second vesting period, in seconds
     */
    function vest(
        address user,
        uint amount,
        uint vestingFirstPeriod,
        uint vestingSecondPeriod
    ) external whenNotPaused {
        _vest(user, amount, vestingFirstPeriod, vestingSecondPeriod);
    }

    /**
     * @notice External function an array of users to vest locking
     * @param users An array addresses of the user who will vests tokens
     * @param amounts The amount of tokens to be vested for each user
     * @param vestingFirstPeriod The duration of the first vesting period, in seconds
     * @param vestingSecondPeriod The duration of the second vesting period, in seconds
     */
    function vestForBatch(
        address[] memory users,
        uint256[] memory amounts,
        uint256 vestingFirstPeriod,
        uint256 vestingSecondPeriod
    ) external whenNotPaused {
        require(
            users.length == amounts.length,
            "InQubetaVesting: Invalid array length"
        );

        for (uint256 i; i < users.length; i++) {
            _vest(
                users[i],
                amounts[i],
                vestingFirstPeriod,
                vestingSecondPeriod
            );
        }
    }

    /**
     * @notice Internal function for users to vest locking
     * @param user The address of the user who will invest tokens
     * @param amount The amount of tokens to be vested
     * @param vestingFirstPeriodDuration The duration of the first vesting period, in seconds
     * @param vestingSecondPeriodDuration The duration of the second vesting period, in seconds
     */
    function _vest(
        address user,
        uint amount,
        uint vestingFirstPeriodDuration,
        uint vestingSecondPeriodDuration
    ) internal whenNotPaused {
        require(
            vesters[msg.sender] || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "InQubetaVesting::vest: Not allowed"
        );
        require(
            user != address(0),
            "InQubetaVesting::vest: Vest to the zero address"
        );
        uint nonce = ++vestingNonces[user];

        vestingInfos[user][nonce].vestingAmount = amount;
        vestingInfos[user][nonce].vestingStart = block.timestamp;
        vestingInfos[user][nonce]
            .vestingSecondPeriod = vestingSecondPeriodDuration;
        uint vestingReleaseStartDate = block.timestamp +
            vestingFirstPeriodDuration;
        uint vestingEnd = vestingReleaseStartDate + vestingSecondPeriodDuration;
        vestingInfos[user][nonce]
            .vestingReleaseStartDate = vestingReleaseStartDate;
        vestingInfos[user][nonce].vestingEnd = vestingEnd;
        emit Vest(
            user,
            nonce,
            amount,
            vestingFirstPeriodDuration,
            vestingSecondPeriodDuration,
            vestingReleaseStartDate,
            vestingEnd
        );
    }

    /**
     * @notice External function which will cause to receiving tokens for a user
     */
    function unvest() external whenNotPaused returns (uint unvested) {
        return _unvest(msg.sender);
    }

    /**
     * @notice External function for receiving tokens for a specific user
     * @param user The address of the user for whom tokens will be received
     */
    function unvestFor(
        address user
    ) external whenNotPaused returns (uint unvested) {
        require(
            canAnyoneUnvest || vesters[msg.sender],
            "InQubetaVesting: Not allowed"
        );
        return _unvest(user);
    }

    /**
     * @notice External function for receiving tokens for a batch of users
     * @param users An array of user addresses for whom the tokens will be received
     */
    function unvestForBatch(
        address[] memory users
    ) external whenNotPaused returns (uint unvested) {
        require(
            canAnyoneUnvest || vesters[msg.sender],
            "InQubetaVesting: Not allowed"
        );
        uint length = users.length;
        for (uint i = 0; i < length; i++) {
            unvested += _unvest(users[i]);
        }
    }

    /**
     * @notice Internal function which will cause to receiving tokens for a user
     * @param user The address of the user who will receive tokens
     */
    function _unvest(address user) internal returns (uint unvested) {
        uint nonce = vestingNonces[user];
        require(nonce > 0, "InQubetaVesting: No vested amount");
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount)
                continue;
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            uint toUnvest;
            if (vestingInfo.vestingSecondPeriod != 0) {
                toUnvest =
                    ((block.timestamp - vestingInfo.vestingReleaseStartDate) *
                        vestingInfo.vestingAmount) /
                    vestingInfo.vestingSecondPeriod;
                if (toUnvest > vestingInfo.vestingAmount) {
                    toUnvest = vestingInfo.vestingAmount;
                }
            } else {
                toUnvest = vestingInfo.vestingAmount;
            }
            uint totalUnvestedForNonce = toUnvest;
            toUnvest -= vestingInfo.unvestedAmount;
            unvested += toUnvest;
            vestingInfos[user][i].unvestedAmount = totalUnvestedForNonce;
        }
        require(unvested > 0, "InQubetaVesting: Unvest amount is zero");
        vestingToken.safeTransfer(user, unvested);
        emit Unvest(user, unvested);
    }

    /**
     * @notice External function for returns the amount of tokens available for vested for a user
     * @param user The address of the available balance to get receiving tokens
     */
    function availableForUnvesting(
        address user
    ) external view returns (uint unvestAmount) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount)
                continue;
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            uint toUnvest;
            if (vestingInfo.vestingSecondPeriod != 0) {
                toUnvest =
                    ((block.timestamp - vestingInfo.vestingReleaseStartDate) *
                        vestingInfo.vestingAmount) /
                    vestingInfo.vestingSecondPeriod;
                if (toUnvest > vestingInfo.vestingAmount) {
                    toUnvest = vestingInfo.vestingAmount;
                }
            } else {
                toUnvest = vestingInfo.vestingAmount;
            }
            toUnvest -= vestingInfo.unvestedAmount;
            unvestAmount += toUnvest;
        }
    }

    /**
     * @notice External function returns the total amount of received tokens for a user
     * @param user The address of the user to check
     */
    function userUnvested(
        address user
    ) external view returns (uint totalUnvested) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingReleaseStartDate > block.timestamp) continue;
            totalUnvested += vestingInfo.unvestedAmount;
        }
    }

    /**
     * @notice External function calculates the amount of tokens vested and unclaimed for a given user
     * @param user The address of the user to check
     */
    function userVestedUnclaimed(
        address user
    ) external view returns (uint unclaimed) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            VestingInfo memory vestingInfo = vestingInfos[user][i];
            if (vestingInfo.vestingAmount == vestingInfo.unvestedAmount)
                continue;
            unclaimed += (vestingInfo.vestingAmount -
                vestingInfo.unvestedAmount);
        }
    }

    /**
     * @notice External function return the total amount of tokens which the user has invested
     * @param user The user whose vested amount will be returned
     */
    function userTotalVested(
        address user
    ) external view returns (uint totalVested) {
        uint nonce = vestingNonces[user];
        if (nonce == 0) return 0;
        for (uint i = 1; i <= nonce; i++) {
            totalVested += vestingInfos[user][i].vestingAmount;
        }
    }

    /**
     * @notice External function to add or remove the status of a vester
     * @param vester The address of the vester whose status is to be updated
     * @param isActive Whether or not the vester is authorized to vest and receive tokens
     */
    function updateVesters(
        address vester,
        bool isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            vester != address(0),
            "InQubetaVesting::updateVesters: Zero address"
        );
        vesters[vester] = isActive;
        emit UpdateVesters(vester, isActive);
    }

    function toggleCanAnyoneUnvest() external onlyRole(DEFAULT_ADMIN_ROLE) {
        canAnyoneUnvest = !canAnyoneUnvest;
        emit ToggleCanAnyoneUnvest(canAnyoneUnvest);
    }

    /**
     * @notice External function for certain tokens mistakenly sent to the contract
     * @param to The address to which the tokens will be sent
     * @param tokenAddress The address of the token to be rescued
     * @param amount The amount of tokens to be rescued
     */
    function rescue(
        address to,
        address tokenAddress,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            to != address(0),
            "InQubetaVesting::rescue: Cannot rescue to the zero address"
        );
        require(amount > 0, "InQubetaVesting::rescue: Cannot rescue 0");

        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    /**
     * @notice External function for tokens mistakenly sent to the contract
     * @param to The address to which the tokens will be sent
     * @param amount The amount of tokens to be rescued
     */
    function rescue(
        address payable to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            to != address(0),
            "InQubetaVesting::rescue: Cannot rescue to the zero address"
        );
        require(amount > 0, "InQubetaVesting::rescue Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
}
