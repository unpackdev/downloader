// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.5 <0.9.0;

/// @dev is used to avoid decsimal point
uint256 constant factor = 10 ** 10;

/// @dev tokens types. Each type has different accrual size of the royalty and staking 
enum TokenType{ REGULAR, EXPIRIENCED, INCORRIGIBLE, META }
/*
The weight of the token in the distribution of profits from staking. 
Calculated based on the percentage of royalty deductions
If we have 100 wei to distribution and 4 stakes each with different token type they will receive the profit according to these weight.
*/
uint8 constant regWeight = 20;
uint8 constant expWeight = 23;
uint8 constant incrWeight = 27;
uint8 constant metaWeight = 30;

library NftCommon {
    /// @dev returns token type by token id. Tokens distribution: 11111112222223333344 , where:
    /// 1 - REGULAR
    /// 2 - EXPIRIENCED
    /// 3 - INCORRIGIBLE
    /// 4 - META
    /// total we have 10_000 tokens. We split it to 500 batches each of 20 tokens. Each batch contains: 7 reg, 6 exp, 5 incr and 2 meta tokens.
    /// reg = 7 * 500 = 3500 tokens total
    /// exp = 6 * 500 = 3000 tokens total
    /// incr = 5 * 500 = 2500 tokens total
    /// meta = 2 * 500 = 1000 tokens total
    function getTokenType(uint256 tokenId) internal pure returns(TokenType) {
        require(tokenId > 0, "token id should be larger then 0");
        uint256 res = (tokenId - 1) % 20; // (id - 1) because id is starting from 1
        if(res <= 6) { // from 0 to 6 = 7 tokens
            return TokenType.REGULAR;
        }
        else if(res >= 7 && res <= 12) { // from 7 to 12 = 6 tokens
            return TokenType.EXPIRIENCED;
        }
        else if(res >= 13 && res <= 17) { // from 13 to 17 = 5 tokens
            return TokenType.INCORRIGIBLE;
        }
        else { // from 18 to 19 = 2 tokens
            return TokenType.META;
        }
    }
}