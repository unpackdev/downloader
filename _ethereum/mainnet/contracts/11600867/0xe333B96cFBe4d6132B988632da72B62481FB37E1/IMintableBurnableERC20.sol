pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./ERC20Burnable.sol";

interface IMintableBurnableERC20 is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;
}
