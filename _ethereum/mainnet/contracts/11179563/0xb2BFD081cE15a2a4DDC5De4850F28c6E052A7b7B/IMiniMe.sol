// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IMiniMe {
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

    /* ========== MINIME EXTENSIONS ========== */

    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
}
