// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IERC20Token {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address _user, uint256 _amount) external;

    function burn(uint256 _amount) external;

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}
