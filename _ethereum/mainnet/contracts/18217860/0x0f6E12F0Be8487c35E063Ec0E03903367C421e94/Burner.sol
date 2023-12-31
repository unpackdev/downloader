// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ITokenMinter.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


contract Burner is ReentrancyGuard{

    address public immutable cvxfxn;
    event Burned(address indexed _address, uint256 _amount);

    constructor(address _cvxfxn){
        cvxfxn = _cvxfxn;
    }

    function burn() external nonReentrant returns(uint256 amount){
        amount = IERC20(cvxfxn).balanceOf(address(this));
        ITokenMinter(cvxfxn).burn(address(this),amount);
        emit Burned(address(this),amount);
    }

    function burnAtSender(uint256 _amount) external nonReentrant returns(uint256 amount){
        ITokenMinter(cvxfxn).burn(msg.sender,_amount);
        emit Burned(msg.sender, _amount);
        return _amount;
    }

}