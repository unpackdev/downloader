pragma solidity ^0.8.20;

interface DelegateApprovals {
    function canIssueFor(
        address authoriser,
        address delegate
    ) external view returns (bool);
    function approveIssueOnBehalf(address delegate) external;
}