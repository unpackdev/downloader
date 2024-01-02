// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContratoUSDT {
    address public owner;
    mapping(address => uint256) public saldo;
    uint256 public limiteTransacao = 1000000 * 10**6; // 1 milhão de USDT

    event Enviar(address remetente, address destinatario, uint256 quantidade);
    event Receber(address remetente, uint256 quantidade);
    event Trocar(address remetente, uint256 quantidade);

    modifier onlyOwner() {
        require(msg.sender == owner, "Somente o proprietario pode chamar esta funcao");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function enviar(address destinatario, uint256 quantidade) external {
        require(quantidade <= limiteTransacao, "A quantidade excede o limite permitido");
        require(saldo[msg.sender] >= quantidade, "Saldo insuficiente");

        saldo[msg.sender] -= quantidade;
        saldo[destinatario] += quantidade;

        emit Enviar(msg.sender, destinatario, quantidade);
    }

    function receber(uint256 quantidade) external {
        require(quantidade <= limiteTransacao, "A quantidade excede o limite permitido");

        saldo[msg.sender] += quantidade;

        emit Receber(msg.sender, quantidade);
    }

    function trocar(uint256 quantidade) external onlyOwner {
        require(quantidade <= limiteTransacao, "A quantidade excede o limite permitido");
        // Lógica de troca aqui

        emit Trocar(msg.sender, quantidade);
    }

    function atualizarLimiteTransacao(uint256 novoLimite) external onlyOwner {
        limiteTransacao = novoLimite;
    }
}