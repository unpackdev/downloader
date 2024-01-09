// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ITribeOne {
    function approveLoan(
        uint256 _loanId,
        uint256 _amount,
        address _agent
    ) external;

    function relayNFT(
        uint256 _loanId,
        address _agent,
        bool _accepted
    ) external payable;
}
