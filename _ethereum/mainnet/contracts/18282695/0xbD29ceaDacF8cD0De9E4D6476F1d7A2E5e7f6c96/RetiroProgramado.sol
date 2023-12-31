// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract RetiroProgramado {
    address public owner;
    uint256 public balance;
    uint256 public lastWithdrawTime;
    uint256 public constant withdrawalInterval = 100 hours; // Intervalo de 100 horas
    uint256 public constant feeRate = 3; // 0.3%

    constructor() {
        owner = msg.sender;
        lastWithdrawTime = block.timestamp;
    }

    receive() external payable {
        require(msg.value > 0, "Debe enviar Ether.");
        balance += msg.value;
    }

    function withdraw() external {
        require(msg.sender == owner, "Solo el propietario puede realizar retiros.");
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastWithdraw = currentTime - lastWithdrawTime;
        
        require(timeSinceLastWithdraw >= withdrawalInterval, "Debe esperar al menos 100 horas para realizar otro retiro.");
        
        uint256 fee = (balance * feeRate) / 1000; // Calcula el 0.3% del saldo
        uint256 amountToWithdraw = balance - fee;
        
        require(amountToWithdraw > 0, "No hay fondos disponibles para retirar.");
        
        lastWithdrawTime = currentTime;
        balance = 0;
        
        payable(owner).transfer(amountToWithdraw); // Envía el Ether al propietario
    }
}