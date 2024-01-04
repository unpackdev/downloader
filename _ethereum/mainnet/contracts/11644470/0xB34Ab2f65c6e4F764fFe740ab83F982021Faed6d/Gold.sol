pragma solidity ^0.6.0;

import "./ERC20Burnable.sol";
import "./Operator.sol";

contract Gold is ERC20Burnable, Operator {
    /**
     * @notice Constructs the Basis Gold ERC-20 contract.
     */
    constructor() public ERC20('BSG', 'BSG') {
        // Mints Basis Gold to contract creator for initial Uniswap oracle deployment.
        // Will be burned after oracle deployment
        _mint(msg.sender, 10**15);
    }

    /**
     * @notice Operator mints basis gold to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of basis gold to mint to
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
