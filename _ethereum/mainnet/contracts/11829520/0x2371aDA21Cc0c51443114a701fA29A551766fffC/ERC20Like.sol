// SPDX-License-Identifier: MIT
pragma solidity ^0.6.1;

import "./IERC20.sol";

abstract contract ERC20Like is IERC20 {
    function totalSupply() external view virtual override returns (uint256);

    function balanceOf(address account) external view virtual override returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
    override
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        virtual
    override
        returns (uint256);

    function approve(address spender, uint256 amount)
        external
        virtual
    override
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool);

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8);

    function burn(uint256 value) public virtual;
}
