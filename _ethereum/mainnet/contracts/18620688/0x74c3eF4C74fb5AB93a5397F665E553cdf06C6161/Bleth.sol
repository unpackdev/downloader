// SPDX-License-Identifier: MIT
// Liquid Blast Ether contract
// Owner is unshETH vault multisig
// Not using contract because Blast withdrawal is not yet determined, and points may not work with
// Deposits will be made periodically by the multisig, every $500k
// Fees used for development, roughly equal to 3 months of staking yield
// Upon Blast withdrawals going live, BlETH withdrawal contract will allow users to withdraw ETH + farmed points
// Blast airdrop from farmed points will be converted to ETH and added to the withdrawal contract (minus small fee)

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";


contract BlastETH is ERC20Burnable, Ownable {

    uint public feeBps;
    address public feeReceiver;
    event FeesUpdated(uint feeBps, address feeReceiver);

    /* ========== CONSTRUCTOR ========== */
    constructor(uint _feeBps, address _feeReceiver, address _owner) ERC20("Liquid Blast Ether", "BlETH") {
        feeBps = _feeBps;
        feeReceiver = _feeReceiver;
        transferOwnership(_owner);
    }

    function setFees(uint _feeBps, address _feeReceiver) external onlyOwner {
        require(feeBps <= 250, "feeBps too high");
        feeBps = _feeBps;
        feeReceiver = _feeReceiver;
        emit FeesUpdated(_feeBps, _feeReceiver);
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable {

        uint amount = msg.value;
        uint fee = amount * feeBps / 10000;
        uint amountAfterFee = amount - fee;

        //send fee to feeReceiver
        Address.sendValue(payable(feeReceiver), fee);

        //send remaining ETH to vault multisig
        Address.sendValue(payable(owner()), amountAfterFee);

        //mint BLASTETH to sender
        _mint(msg.sender, amountAfterFee);
    }

}