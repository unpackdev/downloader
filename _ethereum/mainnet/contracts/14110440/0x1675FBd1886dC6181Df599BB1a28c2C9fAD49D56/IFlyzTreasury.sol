// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IFlyzTreasury {
    function excessReserves() external view returns (uint256);

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 sent_);

    function valueOfToken(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);

    function mintRewards(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount, address _token) external;
}
