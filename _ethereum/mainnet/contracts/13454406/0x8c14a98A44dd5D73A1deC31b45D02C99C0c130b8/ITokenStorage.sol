pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

interface ITokenStorage {
    function transfer(IERC20 token, address to, uint256 amount) external;
    function burn(ERC20Burnable token, uint256 amount) external;
}
