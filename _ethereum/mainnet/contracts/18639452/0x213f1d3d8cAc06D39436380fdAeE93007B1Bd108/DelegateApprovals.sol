pragma solidity ^0.8.20;

interface DelegateApprovals {
    function canIssueFor(
        address authoriser,
        address delegate
    ) external view returns (bool);
    function approveIssueOnBehalf(address delegate) external;

    function canClaimFor(address authoriser, address delegate) external view returns (bool);

    function approveClaimOnBehalf(address delegate) external;

    function canBurnFor(address authoriser, address delegate) external view returns (bool);

    function approveBurnOnBehalf(address delegate) external;
}