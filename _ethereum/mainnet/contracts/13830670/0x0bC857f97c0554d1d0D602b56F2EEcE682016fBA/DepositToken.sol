// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";


contract DepositToken is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public operator;

    constructor(address _operator, address _lptoken)
        public
        ERC20(
             string(
                abi.encodePacked(ERC20(_lptoken).name()," Convex Deposit")
            ),
            string(abi.encodePacked("cvx", ERC20(_lptoken).symbol()))
        )
    {
        operator =  _operator;
    }
    
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        
        _burn(_from, _amount);
    }

}