// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IKeep3rV1Helper {
    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);
}

interface IKeep3rV1 {
    function keepers(address keeper) external returns (bool);

    function KPRH() external view returns (IKeep3rV1Helper);

    function receipt(
        address credit,
        address keeper,
        uint256 amount
    ) external;

    function workReceipt(address keeper, uint256 amount) external;

    function addJob(address job) external;

    function addKPRCredit(address job, uint256 amount) external;

    function bond(address bonding, uint256 amount) external;

    function activate(address bonding) external;
}
