pragma solidity >=0.5.0 <0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



contract TokenDeployInit {
    function getTokens() internal pure returns (address[] memory) {
        address[] memory tokens = new address[](16);
        tokens[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        tokens[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        tokens[2] = 0x0000000000085d4780B73119b644AE5ecd22b376;
        tokens[3] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        tokens[4] = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
        tokens[5] = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
        tokens[6] = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03;
        tokens[7] = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
        tokens[8] = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
        tokens[9] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        tokens[10] = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        tokens[11] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
        tokens[12] = 0x1985365e9f78359a9B6AD760e32412f4a445E862;
        tokens[13] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
        tokens[14] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        tokens[15] = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;
        return tokens;
    }
}
