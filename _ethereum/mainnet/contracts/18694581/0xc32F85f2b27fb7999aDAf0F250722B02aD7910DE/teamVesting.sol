// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./MerkleProof.sol";


contract vesting is Ownable {
    using SafeERC20 for IERC20;

    struct Allocation {
        uint amountOut;
        uint vesting_time;
        uint lock_time;
        uint firstClaimAmount;
        uint claimed;
    }

    IERC20 public immutable TOKEN;

    mapping(string => Allocation) public allocs;

    uint public totalTokens;
    uint public state;
    uint public START_CLAIM_TIME;

    constructor(
        IERC20 _token,
        Allocation[] memory _allocs,
        string[] memory _allocName,
        address _multisig
    ) {
        TOKEN = _token;
        require(_allocs.length == _allocName.length, "diff arrays size");
        for (uint i = 0; _allocName.length > i; i++) {
            Allocation memory alloc = _allocs[i];
            allocs[_allocName[i]] = Allocation({
                amountOut: alloc.amountOut,
                vesting_time: alloc.vesting_time,
                lock_time: alloc.lock_time,
                firstClaimAmount: alloc.firstClaimAmount,
                claimed: alloc.claimed
            });
        }
        transferOwnership(_multisig);
    }

    function setTotalTokens(uint amount) external onlyOwner {
        require(START_CLAIM_TIME == 0, "claim started");
        TOKEN.safeTransferFrom(_msgSender(), address(this), amount);
        totalTokens += amount;
    }

    function startClaim(uint additionalTime) external onlyOwner {
        require(START_CLAIM_TIME == 0, "claim started");
        require(additionalTime <= 1 days, "too long");

        START_CLAIM_TIME = block.timestamp + additionalTime;
        delete state;
    }

    function claim(string memory _allocName, address _to) external onlyOwner {
        uint startClaimTimeCached = START_CLAIM_TIME;
        require(startClaimTimeCached > 0, "cannot claim yet");
        uint claimable = pendingOf(_allocName);
        require(claimable > 0, "nothing to claim");
        allocs[_allocName].claimed += claimable;
        TOKEN.safeTransfer(_to, claimable);
    }

    function pendingOf(string memory _allocName) public view returns (uint) {
        uint startClaimTimeCached = START_CLAIM_TIME +
            allocs[_allocName].lock_time;
        if (START_CLAIM_TIME == 0 || startClaimTimeCached > block.timestamp)
            return 0;
        Allocation storage alloc = allocs[_allocName];
        uint amount = alloc.firstClaimAmount;
        uint userFinal = alloc.amountOut - alloc.firstClaimAmount;
        uint max = alloc.amountOut;
        amount += (userFinal * (block.timestamp - startClaimTimeCached)) /
            alloc.vesting_time;
        if (amount > max) amount = max;

        return amount - alloc.claimed;
    }

    function isLock(string memory _allocName) public view returns (bool) {
        uint lockTime = allocs[_allocName].lock_time + START_CLAIM_TIME;
        if (block.timestamp >= lockTime) return false;
        else return true;
    }

    function _firstClaim(string memory _allocName, address _to) private {
        uint firstOut;
        require(allocs[_allocName].amountOut > 0, "Wrong allocName");
        firstOut = allocs[_allocName].firstClaimAmount;
        if (firstOut == 0) return;
        allocs[_allocName].claimed += firstOut;
        TOKEN.safeTransfer(_to, firstOut);
    }
}
