// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IBankStorage.sol";

interface IBank is IBankStorage {
    function strategies(uint256 i) external view returns (address);

    function totalStrategies() external view returns (uint256);

    function underlyingBalance() external view returns (uint256);

    function strategyBalance(uint256 i) external view returns (uint256);

    function investedBalance() external view returns (uint256);

    function virtualBalance() external view returns (uint256);

    function virtualPrice() external view returns (uint256);

    function pause() external;

    function unpause() external;

    function invest(address strategy, uint256 amount) external;

    function investAll(address strategy) external;

    function exit(address strategy, uint256 amount) external;

    function exitAll(address strategy) external;

    function deposit(uint256 amount) external;

    function depositFor(uint256 amount, address recipient) external;

    function withdraw(uint256 amount) external;
}
