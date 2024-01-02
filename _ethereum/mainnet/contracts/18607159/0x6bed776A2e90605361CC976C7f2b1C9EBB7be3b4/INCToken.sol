//Incenti is a decentralized solution uniting projects, creators, and users on Twitter, designed to help you grow, earn, and reward. 
//Powered by AmoLabs
//https://incenti.xyz/
//https://twitter.com/incentixyz
// SPDX-License-Identifier: OSL-3.0
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract AmolabsIncenti is ERC20, Ownable {

    bool private prelaunch;
    uint256 private taxRate;
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("Incenti", "INC") Ownable(msg.sender) {
        uint256 _totalSupply = 5000000000000 * (10 ** decimals());

        prelaunch = true;
        taxRate = 20;

        _mint(msg.sender, _totalSupply);
    }

    function openTrading() external onlyOwner {
        prelaunch = false;
    }

    function setTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate <= 21, "Invalid tax rate"); //Tax rate must be lower than 21%
        taxRate = newTaxRate;
    }

    function _applyTax(uint256 amount) internal view returns (uint256) {
        return (amount * (100 - taxRate)) / 100;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(prelaunch) {
            require(to == owner() || from == owner(), "Trading is not yet active");
        } else if (to != owner() && from != owner()) {
            uint256 taxedAmount = _applyTax(amount);
            uint256 tax = amount - taxedAmount;
            _transfer(from, deadAddress, tax);
            amount = taxedAmount;
        }

        super._update(from, to, amount);
    }
}