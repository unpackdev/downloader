// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20Burnable.sol";

import "./Operator.sol";

contract HAIF is ERC20Burnable, Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Constructs the Lift HAIF Token ERC-20 contract.
     *
     * I am the token represented by a new VAULT that acts as a hedge fund.
     * It takes in funds (from say the IdeaFund) and issues a HAIF token for the 
     * IdeaFund to hold so that it can represent value a small LP of this must be created
     * to create a value that we can track value to?  Or some other way to give this 
     * token value on Coingecko/TheGraph Protocol
     *
     * This could quickly become a project (hedgefund) so this token may be held
     * people folks other than just the IdeaFund
     *
     * Or maybe we like the idea and spin out a new token just for public facing
     * HedgeFund investing...
     *
     */
    constructor() ERC20('Human AI Fund', 'HAIF') {
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
