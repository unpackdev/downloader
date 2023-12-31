pragma solidity ^0.6.0;

import "./Operator.sol";
import "./ERC20Burnable.sol";

contract Bond is ERC20Burnable, Ownable, Operator {
    /**
     * @notice Constructs the OK Bond ERC-20 contract.
     */
    constructor() public ERC20("OKB", "OKB") {}

    /**
     * @notice Operator mints ok bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of ok bonds to mint to
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
