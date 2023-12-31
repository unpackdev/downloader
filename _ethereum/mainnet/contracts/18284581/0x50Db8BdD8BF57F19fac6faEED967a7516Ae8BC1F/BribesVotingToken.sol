// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";

/**
 * @title   BribesVotingToken
 * @author  ConvexFinance -> WombexFinance
 * @notice  Simply creates a token that can be minted and burned from the operator
 */
contract BribesVotingToken is ERC20 {
    address public operator;

    event UpdateOperator(address indexed sender, address indexed operator);

    constructor(address _operator) public ERC20("vlWMX Vote", "vlWMXV") {
        operator = _operator;
    }

    function updateOperator(address operator_) external {
        require(msg.sender == operator, "!authorized");
        operator = operator_;

        emit UpdateOperator(msg.sender, operator_);
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
