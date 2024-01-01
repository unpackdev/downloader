// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IClh {
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
