// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CourageToken is ERC20 {
    address public treasury = 0xCFf86964A23f44533C16B6A2534cFDCdaEDAEB2A;
    
    constructor() ERC20("Courage The Dog", "COURAGE") {
        // Mint the total supply of 369,000,000,000 tokens
        _mint(msg.sender, 369000000000 * 10 ** uint256(decimals()));
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        // Calculate the amount to send to the treasury
        uint256 treasuryFee = (amount * 2) / 100; // 2% fee

        // Transfer the amount minus the treasury fee to the recipient
        super.transfer(recipient, amount - treasuryFee);

        // Transfer the treasury fee to the treasury wallet
        super.transfer(treasury, treasuryFee);

        return true;
    }
}