// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";

contract Vesting is Ownable {

    /// @notice CPOOL token contract
    IERC20 public immutable cpool;

    /// @notice Timestamp of the vesting begin time
    uint256 public immutable vestingBegin;

    /// @notice Timestmap of the vesting end time
    uint256 public immutable vestingEnd;

    struct VestingParams {
        uint256 amount;
        uint256 vestingCliff;
        uint256 lastUpdate;
        uint256 claimed;
    }

    /// @notice Mapping of IDs to vesting params
    mapping(uint256 => VestingParams) public vestings;

    /// @notice Mapping of addresses to lists of their vesting IDs
    mapping(address => uint256[]) public vestingIds;

    /// @notice Total amount of vested tokens
    uint256 public totalVest;

    /// @notice Next vesting object ID
    uint256 private _nextVestingId;

    struct HoldParams {
        address recipient;
        uint256 amount;
        uint256 unlocked;
        uint256 vestingCliff;
    }

    // CONSTRUCTOR

    /**
     * @notice Contract constructor
     * @param cpool_ Address of the CPOOL contract
     * @param vestingBegin_ Timestamp of the vesting begin time
     * @param vestingEnd_ Timestamp of the vesting end time
     */
    constructor(IERC20 cpool_, uint256 vestingBegin_, uint256 vestingEnd_) Ownable() {
        require(vestingEnd_ > vestingBegin_, "Vesting: vesting end should be greater than vesting begin");

        cpool = cpool_;
        vestingBegin = vestingBegin_;
        vestingEnd = vestingEnd_;
    }

    /**
     * @notice Function to claim tokens
     * @param account Address to claim tokens for
     */
    function claim(address account) external {
        uint256 totalAmount;
        for (uint8 i = 0; i < vestingIds[account].length; i++) {
            uint256 amount = getAvailableBalance(vestingIds[account][i]);
            if (amount > 0) {
                totalAmount += amount;
                vestings[vestingIds[account][i]].claimed += amount;
                vestings[vestingIds[account][i]].lastUpdate = block.timestamp;
            }
        }
        require(cpool.transfer(account, totalAmount), "Vesting::claim: transfer error");
    }
    
    // RESTRICTED FUNCTIONS

    /**
     * @notice Owner function to hold tokens to a batch of accounts
     * @param params List of HoldParams objects with vesting params
     */
    function holdTokens(HoldParams[] memory params) external onlyOwner {
        uint256 totalAmount;
        for (uint8 i = 0; i < params.length; i++) {
            totalAmount += params[i].amount;
        }
        require(cpool.transferFrom(msg.sender, address(this), totalAmount), "Vesting::holdTokens: transfer failed");
        totalVest += totalAmount;
        for (uint8 i = 0; i < params.length; i++) {
            _holdTokens(params[i]);
        }
    }

    /**
     * @notice Function gets total amount of available for claim tokens for account
     * @param account Account to calculate amount for
     * @return amount Total amount of available tokens
     */
    function getAvailableBalanceOf(address account) external view returns (uint256 amount) {
        for (uint8 i = 0; i < vestingIds[account].length; i++) {
            amount += getAvailableBalance(vestingIds[account][i]);
        }
    }

    /**
     * @notice Function gets amount of available for claim tokens in exact vesting object
     * @param id ID of the vesting object
     * @return Amount of available tokens
     */
    function getAvailableBalance(uint256 id) public view returns (uint256) {
        VestingParams memory vestParams = vestings[id];
        if (block.timestamp < vestParams.vestingCliff) {
            return 0;
        }
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = vestParams.amount - vestParams.claimed;
        } else {
            amount = vestParams.amount * (block.timestamp - vestParams.lastUpdate) / (vestingEnd - vestingBegin);
        }
        return amount;
    }

     /**
     * @notice Function gets amount of vesting objects for account
     * @param account Address of account
     * @return Amount of vesting objects
     */
    function vestingCountOf(address account) external view returns (uint256) {
        return vestingIds[account].length;
    }

    // PRIVATE FUNCTIONS

    /**
     * @notice Private function to hold tokens for one account
     * @param params HoldParams object with vesting params
     */
    function _holdTokens(HoldParams memory params) private {
        require(params.amount > 0, "Vesting::holdTokens: can not hold zero amount");
        require(vestingEnd > params.vestingCliff, "Vesting::holdTokens: cliff is too late");
        require(params.vestingCliff >= vestingBegin, "Vesting::holdTokens: cliff is too early");
        require(params.unlocked <= params.amount, "Vesting::holdTokens: unlocked can not be greater than amount");
    
        if (params.unlocked > 0) {
            cpool.transfer(params.recipient, params.unlocked);
        }
        if (params.unlocked < params.amount) {
            vestings[_nextVestingId] = VestingParams({
                amount: params.amount - params.unlocked,
                vestingCliff: params.vestingCliff,
                lastUpdate: vestingBegin,
                claimed: 0
            });
            vestingIds[params.recipient].push(_nextVestingId);
            _nextVestingId++;
        }
    }
}
