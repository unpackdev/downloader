pragma solidity >=0.6.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract MockAave is ERC20 {
    using SafeMath for uint256;

    constructor() public ERC20("AAVE", "AAVE") {
        _mint(msg.sender, 1000e18);
    }

}