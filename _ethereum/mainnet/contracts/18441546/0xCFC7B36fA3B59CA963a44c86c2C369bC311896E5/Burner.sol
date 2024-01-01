// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenMinter.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";


contract Burner is ReentrancyGuard{

    address public immutable cvxprisma;
    event Burned(address indexed _address, uint256 _amount);

    constructor(address _cvxprisma){
        cvxprisma = _cvxprisma;
    }

    function burn() external nonReentrant returns(uint256 amount){
        amount = IERC20(cvxprisma).balanceOf(address(this));
        ITokenMinter(cvxprisma).burn(address(this),amount);
        emit Burned(address(this),amount);
    }

    function burnAtSender(uint256 _amount) external nonReentrant returns(uint256 amount){
        ITokenMinter(cvxprisma).burn(msg.sender,_amount);
        emit Burned(msg.sender, _amount);
        return _amount;
    }

}