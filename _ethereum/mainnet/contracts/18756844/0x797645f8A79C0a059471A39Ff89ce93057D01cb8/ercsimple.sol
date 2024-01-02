// SPDX-License-Identifier: MIT
/**

Website: https://ercsimple.xyz
Telegram: https://t.me/ercsimple
Twitter: https://twitter.com/ercsimple

At Simple, we defy the rampant scams and lack of trust in the crypto world. 
Our core principle is simplicity: clean code, rigorous audits, and no hidden traps. 
We redefine crypto standards by prioritizing transparency and trust through features like clean and audited code, a fair token distribution model, locked liquidity to prevent rugs, a 1% burn tax for deflationary impact, and renounced contract ownership. 
Join us in our mission to create a safer, more reliable investment environment at ercsimple.xyz.

Learn more at ercsimple.xyz.

**/

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol"; // Import Ownable contract, Ownership will be renounced after the presale is finalized

contract Simple is ERC20, Ownable(address(msg.sender)) { // Needed to set the Pink Sale presale address. Ownership will be renounced after the presale is finalized
    uint256 private constant BURN_RATE = 1; // 5% burn rate

    address private uniswapliq;

    constructor(uint256 initialSupply) ERC20("Simple", "SIMPLE") {
    _mint(msg.sender, initialSupply * (10**uint256(decimals())));
    uniswapliq = address(0); 
    }


    // Set the Pink Sale address after deployment
    function setPinkSaleAddress(address _uniswapliq) external onlyOwner { // Pink Sale presale address
        uniswapliq = _uniswapliq;
    }

    // Transfer function with burn mechanism
    function transfer(address to, uint256 value) public override returns (bool) {
        require(value > 0, "ERC20: Transfer value must be greater than zero");

        uint256 burnvalue;
        uint256 transfervalue;

        if (
            msg.sender != owner() && // Check if the sender is not the owner
            msg.sender != uniswapliq &&
            to != owner() && // Check if the recipient is not the owner
            to != uniswapliq
        ) {
            burnvalue = (value * BURN_RATE) / 100;
            transfervalue = value - burnvalue;
        } else {
            burnvalue = 0;
            transfervalue = value;
        }

        if (burnvalue > 0) {
            _burn(msg.sender, burnvalue);
        }

        _transfer(msg.sender, to, transfervalue);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(from != address(0), "ERC20: Transfer from the zero address");
        require(value > 0, "ERC20: Transfer value must be greater than zero");

        uint256 burnvalue;
        uint256 transfervalue;

        address spender = _msgSender();

        if (
            from != owner() && // Check if the sender is not the owner
            from != uniswapliq &&
            to != owner() && // Check if the recipient is not the owner
            to != uniswapliq
        ) {
            burnvalue = (value * BURN_RATE) / 100;
            transfervalue = value - burnvalue;
        } else {
            burnvalue = 0;
            transfervalue = value;
        }

        if (burnvalue > 0) {
            _burn(from, burnvalue);
        }
        

        _spendAllowance(from, spender, value);
        _transfer(from, to, transfervalue);

        return true;
    }

}