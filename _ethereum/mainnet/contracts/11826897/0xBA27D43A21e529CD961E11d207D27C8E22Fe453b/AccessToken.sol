// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @dev Non-transferrable, ownable ERC-20
 */
contract AccessToken is ERC20, Ownable {
    using SafeMath for uint256;

    event BudgetChanged(address indexed _usr, uint256 indexed _amount);

    mapping(address => uint256) public budgets;

    function budgetOf(address _usr) external view returns (uint256) {
        return budgets[_usr];
    }

    function setBudget(address _usr, uint256 _newBudget) external onlyOwner {
        budgets[_usr] = _newBudget;
        emit BudgetChanged(_usr, _newBudget);
    }

    /**
     * @dev Sets the default values and owner
     */
    constructor(string memory name_, string memory symbol_) public ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(from == address(0) || budgets[from].sub(amount) >= 0, "AccessToken/cannot-transfer");
    }
}
