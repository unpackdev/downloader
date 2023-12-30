pragma solidity ^0.7.0;
interface IUnipumpTradingGroup
{
    function leader() external view returns (address);
    function close() external;
    function closeWithNonzeroTokenBalances() external;
    function anyNonzeroTokenBalances() external view returns (bool);
    function tokenList() external view returns (IUnipumpTokenList);
    function maxSecondsRemaining() external view returns (uint256);
    function group() external view returns (IUnipumpGroup);
    function externalBalanceChanges(address token) external view returns (bool);

    function startTime() external view returns (uint256);
    function endTime() external view returns (uint256);
    function maxEndTime() external view returns (uint256);

    function startingWethBalance() external view returns (uint256);
    function finalWethBalance() external view returns (uint256);
    function leaderWethProfitPayout() external view returns (uint256);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) 
        external 
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint256 deadline
    ) 
        external 
        returns (uint256[] memory amounts);
        
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) 
        external;

    function withdraw(address token) external;
}
interface IUnipumpGroup 
{
    function contribute() external payable;
    function abort() external;
    function startPumping() external;
    function isActive() external view returns (bool);
    function withdraw() external;
    function leader() external view returns (address);
    function tokenList() external view returns (IUnipumpTokenList);
    function leaderUppCollateral() external view returns (uint256);
    function requiredMemberUppFee() external view returns (uint256);
    function minEthToJoin() external view returns (uint256);
    function minEthToStart() external view returns (uint256);
    function maxEthAcceptable() external view returns (uint256);
    function maxRunTimeSeconds() external view returns (uint256);
    function leaderProfitShareOutOf10000() external view returns (uint256);
    function memberCount() external view returns (uint256);
    function members(uint256 at) external view returns (address);
    function contributions(address member) external view returns (uint256);
    function totalContributions() external view returns (uint256);
    function aborted() external view returns (bool);
    function tradingGroup() external view returns (IUnipumpTradingGroup);
}
interface IUnipumpTokenList
{
    function parentList() external view returns (IUnipumpTokenList);
    function isLocked() external view returns (bool);
    function tokens(uint256 index) external view returns (address);
    function exists(address token) external view returns (bool);
    function tokenCount() external view returns (uint256);

    function lock() external;
    function add(address token) external;
    function addMany(address[] calldata _tokens) external;
    function remove(address token) external;    
}

interface IUnipumpGroupManager
{
    function groupLeaders(uint256 at) external view returns (address);
    function groupLeaderCount() external view returns (uint256);
    function groups(uint256 at) external view returns (IUnipumpGroup);
    function groupCount() external view returns (uint256);
    function groupCountByLeader(address leader) external view returns (uint256);
    function groupsByLeader(address leader, uint256 at) external view returns (IUnipumpGroup);

    function createGroup(
        IUnipumpTokenList tokenList,
        uint256 uppCollateral,
        uint256 requiredMemberUppFee,
        uint256 minEthToJoin,
        uint256 minEthToStart,
        uint256 startTimeout,
        uint256 maxEthAcceptable,
        uint256 maxRunTimeSeconds,
        uint256 leaderProfitShareOutOf10000
    ) 
        external
        returns (IUnipumpGroup group);
}

contract UnipumpGroupManagerProxy is IUnipumpGroupManager
{
    IUnipumpGroupManager public groupManager;
    address immutable owner;

    constructor()
    {
        owner = msg.sender;
    }

    function setGroupManager(IUnipumpGroupManager _groupManager) public
    {
        require (msg.sender == owner, "Owner only");
        groupManager = _groupManager;
    }

    function checkProxy() private view
    {
        require (address(groupManager) != address(0), "Group operations have not yet begun");        
    }
    
    function groupLeaders(uint256 at) 
        public
        override
        view 
        returns (address)
    {
        checkProxy();
        return groupManager.groupLeaders(at);
    }

    function groupLeaderCount() 
        public
        override
        view 
        returns (uint256)
    {
        checkProxy();
        return groupManager.groupLeaderCount();        
    }

    function groups(uint256 at) 
        public
        override
        view 
        returns (IUnipumpGroup)
    {
        checkProxy();
        return groupManager.groups(at);        
    }

    function groupCount() 
        public
        override
        view returns (uint256)
    {
        checkProxy();
        return groupManager.groupCount();        
    }

    function groupCountByLeader(address leader) 
        public
        override
        view 
        returns (uint256)
    {
        checkProxy();
        return groupManager.groupCountByLeader(leader);        
    }

    function groupsByLeader(address leader, uint256 at) 
        public
        override
        view 
        returns (IUnipumpGroup)
    {
        checkProxy();
        return groupManager.groupsByLeader(leader, at);        
    }

    function createGroup(
        IUnipumpTokenList tokenList,
        uint256 uppCollateral,
        uint256 requiredMemberUppFee,
        uint256 minEthToJoin,
        uint256 minEthToStart,
        uint256 startTimeout,
        uint256 maxEthAcceptable,
        uint256 maxRunTimeSeconds,
        uint256 leaderProfitShareOutOf10000
    ) 
        public
        override
        returns (IUnipumpGroup group)
    {
        checkProxy();
        return groupManager.createGroup(
            tokenList,
            uppCollateral,
            requiredMemberUppFee,
            minEthToJoin,
            minEthToStart,
            startTimeout,
            maxEthAcceptable,
            maxRunTimeSeconds,
            leaderProfitShareOutOf10000);        
    }
}