// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20Mintable {
    function mint(address _to, uint256 _value) external;

    function burn(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}
