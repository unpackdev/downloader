// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMasterOfTokens {
    event NewToken(
        address _tokenAddress,
        address _pairAddress,
        uint256 _unlockTimestamp,
        uint256 _initialLiq,
        uint256 _phase1Tax,
        uint256 _phase2Tax,
        uint256 _phase1Length,
        uint256 _phase2Length,
        uint256 _finalBuyTax,
        uint256 _finalSellTax
    );

    struct TokenDeployed {
        address tokenAddress;
        address pairAddress;
        uint256 unlockTimestamp;
        uint256 initialLiq;
        uint256 phase1Tax;
        uint256 phase2Tax;
        uint256 phase1Length;
        uint256 phase2Length;
        uint256 finalBuyTax;
        uint256 finalSellTax;
    }

    function addNewToken(TokenDeployed memory _token) external;
    function getToken(uint256 _nonce) external view returns (TokenDeployed memory);
}
