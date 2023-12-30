pragma solidity ^0.7.0;

struct UnipumpGroupData
{
    uint64 tokenListId;
    address leader;

    uint32 runTimeout;
    bool aborted;
    bool complete;
    
    uint32 startTimeout;
    uint16 maxRunTimeHours;  
    uint16 leaderProfitShareOutOf10000;
    
    uint256 leaderUppCollateral;
    uint256 requiredMemberUppFee;
    uint256 minEthToJoin;

    uint256 minEthToStart;
    uint256 maxEthAcceptable;

    // ^-- parameters
    
    address[] members;
    uint256 totalContributions;

    // ^-- pre-start
}

struct UnipumpGroupDataMappings
{
    // To work around deficiencies in solidity

    mapping (address => bool) authorizedTraders;
    // ^-- any time before finish/abort

    mapping (address => uint256) contributions;
    // ^-- pre-start

    mapping (address => uint256) balances;
    mapping (address => mapping (address => bool)) withdrawals;
    // ^-- operational
}

struct UnipumpTokenList
{
    address owner;
    bool locked;
    address[] tokens;
    mapping (address => uint256) tokenIndexes;    
}
library UnipumpTokenListLibrary
{
    function lock(UnipumpTokenList storage tokenList)
        public
    {
        require (msg.sender == tokenList.owner, "Owner only");
        require (!tokenList.locked, "Already locked");
        require (tokenList.tokens.length > 0, "List is empty");
        tokenList.locked = true;
    }

    function add(
        UnipumpTokenList storage tokenList,
        address[] memory tokens
    )
        public
    {
        require (msg.sender == tokenList.owner, "Owner only");
        require (!tokenList.locked, "Already locked");
        for (uint256 x = 0; x < tokens.length; ++x) {
            address token = tokens[x];
            if (tokenList.tokenIndexes[token] == 0) {
                tokenList.tokens.push(token);
                tokenList.tokenIndexes[token] = tokenList.tokens.length;
            }
        }
    }
    
    function remove(
        UnipumpTokenList storage tokenList,
        address[] memory tokens
    )
        public
    {
        require (msg.sender == tokenList.owner, "Owner only");
        require (!tokenList.locked, "Already locked");
        for (uint256 x = 0; x < tokens.length; ++x) {
            address token = tokens[x];
            uint256 index = tokenList.tokenIndexes[token];
            if (index > 0) {
                if (tokenList.tokens.length > index) {
                    address other = tokenList.tokens[tokenList.tokens.length - 1];
                    tokenList.tokens[index - 1] = other;
                    tokenList.tokenIndexes[other] = index;
                }
                tokenList.tokens.pop();
                tokenList.tokenIndexes[token] = 0;
            }
        }
    }

    function exists(
        UnipumpTokenList storage tokenList,
        address token
    )
        public
        view
        returns (bool)
    {
        return tokenList.tokenIndexes[token] > 0;
    }
}