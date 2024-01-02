// SPDX-License-Identifier: UNLICENSED
// Powered by Agora
pragma solidity ^0.8.21;

interface IAgoraERC20Config {

    /**
     * @dev information used to construct the token.
     */
    struct TokenConstructorParameters {
        bytes baseParameters;
        bytes taxParameters;
        bytes tokenLPInfo;
    }

    /**
     * @dev Basic info of the token
     */
    struct TokenInfoParameters {
        string name;
        string symbol;
        bool autoCreateLiquidity;
        uint256 maxSupply;
        address tokensRecepient;
        uint256 maxTokensWallet;
        bool payInTax;
    }

    /**
     *  @dev This struct express the taxes on per 1000, to allow percetanges between 0 and 1. 
     */
    struct TaxParameters {
        uint256 buyTax;
        uint256 sellTax;
        uint256 maxTxBuy;
        uint256 maxTxSell;
        address taxSwapRecepient;
    }

    /**
     * @dev Liquidity pool supply information
     */
    struct TokenLpInfo {
        uint256 lpTokensupply;
        uint256 ethForSupply;
        bool burnLP;
        uint256 lockFee;
        uint256 lpLockUpInDays;
    }
}