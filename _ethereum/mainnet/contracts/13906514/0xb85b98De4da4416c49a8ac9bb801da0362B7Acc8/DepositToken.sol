// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Interfaces.sol";
import "./ERC20.sol";


contract DepositToken is ERC20 {

    address public operator;

    constructor(address _operator, address _lptoken)
    ERC20(
        string(
            abi.encodePacked(ERC20(_lptoken).name()," Unit Protocol Deposit")
        ),
        string(abi.encodePacked("up", ERC20(_lptoken).symbol()))
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