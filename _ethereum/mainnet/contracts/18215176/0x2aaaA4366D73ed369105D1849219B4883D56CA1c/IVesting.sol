//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IVesting {
    function setAllocations(
        address[] memory recipients_,
        uint256[] memory allocations_
    ) external;

    function increaseAllocation(
        address recipient_,
        uint256 amount_
    ) external;
}
