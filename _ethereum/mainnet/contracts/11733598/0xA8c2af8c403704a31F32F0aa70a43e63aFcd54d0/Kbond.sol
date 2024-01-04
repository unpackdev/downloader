pragma solidity ^0.6.0;

import "./Operator.sol";
import "./ERC20Burnable.sol";

contract Kbond is ERC20Burnable, Ownable, Operator {
    /**
     * @notice Constructs the KBOND ERC-20 contract.
     */
    constructor() public ERC20('KBOND', 'KBOND') {}

    /**
     * @notice Operator mints kKbonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of kKbonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

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
