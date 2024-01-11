// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity <=0.8.10;

interface ITreasury {
    function tokenValue(address _token, uint256 _amount)
        external
        view
        returns (uint256);

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function mintRewards(address _recipient, uint256 _amount) external;
}
