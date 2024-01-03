pragma solidity 0.5.17;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract ERC20Mock is ERC20, ERC20Detailed("", "", 18) {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}