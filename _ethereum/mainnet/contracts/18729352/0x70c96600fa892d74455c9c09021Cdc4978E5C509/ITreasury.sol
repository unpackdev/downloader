// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ITreasury {
    function deposit(
        uint _amount,
        address _token,
        uint _profit
    ) external returns (uint send_);

    function withdraw(uint _amount, address _token) external;

    function incurDebt(uint _amount, address _token) external;

    function repayDebtWithReserve(uint _amount, address _token) external;

    function repayDebtWithOHM(uint _amount) external;

    function manage(address _token, uint _amount) external;

    function mintRewards(address _recipient, uint _amount) external;

    function auditReserves() external;

    function totalReserves() external view returns (uint);

    function totalDebt() external view returns (uint);

    function excessReserves() external view returns (uint);

    function valueOf(
        address _token,
        uint _amount
    ) external view returns (uint value_);
}
