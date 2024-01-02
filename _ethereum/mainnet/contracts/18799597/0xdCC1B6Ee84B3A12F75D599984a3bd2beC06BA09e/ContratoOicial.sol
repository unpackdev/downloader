// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract ContratoInteligente {
    address public dono;
    mapping(address => uint256) public saldosTokens;
    address[] public tokensSuportados;

    event TransferenciaRealizada(address remetente, address destinatario, uint256 valor);

    modifier apenasDono() {
        require(msg.sender == dono, "Apenas o dono pode chamar esta funcao");
        _;
    }

    constructor() {
        dono = msg.sender;
        // Adicione aqui os endereços dos contratos ERC-20 suportados pelo contrato
        tokensSuportados.push(0x6B175474E89094C44Da98b954EedeAC495271d0F); // Exemplo de outro token (DAI)
        tokensSuportados.push(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT
    }

    function enviarUSDT(address destinatario, uint256 valor) public apenasDono {
        IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        require(usdt.transfer(destinatario, valor), "Falha ao enviar USDT");
        emit TransferenciaRealizada(address(this), destinatario, valor);
    }

    function receberUSDT(address remetente, uint256 valor) public apenasDono {
        IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        require(usdt.transferFrom(remetente, address(this), valor), "Falha ao receber USDT");
        emit TransferenciaRealizada(remetente, address(this), valor);
    }

    function acessarSaldoUSDT() public view returns (uint256) {
        IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        return usdt.balanceOf(address(this));
    }

    function obterTokensSuportados() public view returns (address[] memory) {
        return tokensSuportados;
    }

    function obterSaldoToken(address tokenAddress) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    // Função adicional para obter saldos de todos os tokens suportados
    function obterSaldosTokensSuportados() public view returns (uint256[] memory) {
        uint256[] memory saldos = new uint256[](tokensSuportados.length * 2);

        for (uint256 i = 0; i < tokensSuportados.length; i++) {
            saldos[i * 2] = uint256(uint160(tokensSuportados[i])); // Convertendo o endereço para uint256
            saldos[i * 2 + 1] = obterSaldoToken(tokensSuportados[i]); // Saldo do token
        }

        return saldos;
    }
}
