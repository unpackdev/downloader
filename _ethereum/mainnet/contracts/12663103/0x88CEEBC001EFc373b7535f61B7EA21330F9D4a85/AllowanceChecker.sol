pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Constants.sol";

contract AllowanceChecker is Constants {

    function approveIfNeeded(address _token, address _spender) internal {
        if (IERC20(_token).allowance(address(this), _spender) < MAX_INT) {
            IERC20(_token).approve(_spender, MAX_INT);
        }
    }

}
