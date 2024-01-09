// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskTreasury {
    function useFunds(
        address _token,
        uint256 _amount,
        address _user
    ) external;

    function userTokenBalance(address _user, address _token)
        external
        view
        returns (uint256 balance);

    function depositFunds(
        address _receiver,
        address _token,
        uint256 _amount
    ) external payable;
}
