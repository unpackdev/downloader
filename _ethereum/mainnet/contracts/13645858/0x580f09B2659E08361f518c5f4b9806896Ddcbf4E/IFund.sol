// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFund {
    function underlying() external view returns (address);

    function fundManager() external view returns (address);

    function relayer() external view returns (address);

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerShare() external view returns (uint256);

    function totalValueLocked() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);
}
