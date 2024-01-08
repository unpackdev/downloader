// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC20Upgradeable.sol";

interface IAnkrBond_R1 {

    event RatioUpdate(uint256 newRatio);

    function initialize(address operator, address pool, string memory token, uint8 initDecimals) external;

    function ratio() external view returns (uint256);

    function mintSharesTo(address to, uint256 shares) external;

    function burnSharesFrom(address from, uint256 shares) external;

    function totalSharesSupply() external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function balanceToShares(uint256 amount) external view returns (uint256);
}
