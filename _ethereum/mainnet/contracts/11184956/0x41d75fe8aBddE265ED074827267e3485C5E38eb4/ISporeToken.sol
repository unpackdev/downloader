// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ISporeToken {
    /* ========== STANDARD ERC20 ========== */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* ========== EXTENSIONS ========== */

    function burn(uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function addInitialLiquidityTransferRights(address account) external;

    function enableTransfers() external;

    function addMinter(address account) external;

    function removeMinter(address account) external;
}
