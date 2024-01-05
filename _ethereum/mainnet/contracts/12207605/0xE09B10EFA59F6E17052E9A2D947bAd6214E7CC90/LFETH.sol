// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

import "./Operator.sol";

contract LFETH is ERC20Burnable, Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /** 
    * @notice Constructs the Lift.Kitchen LFETH Token ERC-20 contract.
    *
    * the LFETH token is the peg token for the Lift.Kitchen algorthmic coin
    * expansion comes from being above the peg 1.05 (programatically).
    *
    */
    constructor() ERC20('Lift.Kitchen ETH', 'LFETH') {
    }

    function mint(address _recipient, uint256 _amount)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(_recipient);
        _mint(_recipient, _amount);
        uint256 balanceAfter = balanceOf(_recipient);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}
