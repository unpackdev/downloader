//SPDX-License-Identifier: Unlicense

pragma solidity 0.7.3;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    // function store() external view returns (address);
    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function deposit(uint256 amountWei, address token) external;
    function depositFor(uint256 amountWei, address token, address holder) external;

    function withdrawAll() external;
    function withdraw(uint256 numberOfShares, address token) external;

    function underlyingBalanceWithInvestmentForHolder(address holder) view external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function doHardWork() external;
}
