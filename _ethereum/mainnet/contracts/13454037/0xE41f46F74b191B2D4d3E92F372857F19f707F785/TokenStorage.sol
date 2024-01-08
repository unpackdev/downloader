pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

import "./ITokenStorage.sol";

contract TokenStorage is ITokenStorage, Ownable {
    using SafeERC20 for IERC20;

    function transfer(IERC20 token, address to, uint256 amount) public onlyOwner {
        require (token.balanceOf(address(this)) >= amount, "insufficient reserved token balance");
        token.safeTransfer(to, amount);
    }

    function burn(ERC20Burnable token, uint256 amount) public onlyOwner {
        require (token.balanceOf(address(this)) >= amount, "insufficient reserved token balance");
        token.burn(amount);
    }
}
