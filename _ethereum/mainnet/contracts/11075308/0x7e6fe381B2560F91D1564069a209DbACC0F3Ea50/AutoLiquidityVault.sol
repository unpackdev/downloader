/**

 * GearAutomatic's Liquidity Vault
 
 * Smart contract to decentralize the uniswap liquidity for GearAutomatic, providing proof of liquidity indefinitely!

 * Official Website: 
   https://www.GearProtocol.com
 
 */




pragma solidity ^0.6.0;



interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}



contract AutoLiquidityVault {
    
    using SafeMath for uint256;
    
    ERC20 public liquidityToken = ERC20(0xd508b41cac055fdcEdf0631a85a0aDE2808bb5b9);
    
    address owner = msg.sender;
    uint256 public lastTradingFeeDistribution = now;
    
    uint256 public migrationLock;
    address public migrationRecipient;
    
    
    // Has a daily hardcap of 1% trading fees distribution.

    function distributeTradingFees() external {
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        require(msg.sender == owner);
        require(lastTradingFeeDistribution < now);
        uint256 OnePercent = liquidityBalance.mul(1).div(100);
        liquidityToken.transfer(owner, OnePercent);
        lastTradingFeeDistribution = lastTradingFeeDistribution + 24 hours;
    } 
    

    // Function allows liquidity to be migrated, after 1 month lockup -preventing abuse.

    function startLiquidityMigration(address recipient) external {
        require(msg.sender == owner);
        migrationLock = now + 720 hours;
        migrationRecipient = recipient;
    }
    
    
    // Migrates liquidity to new location, assuming the 1 month lockup has passed -preventing abuse.

    function processMigration() external {
        require(msg.sender == owner);
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(migrationRecipient, liquidityBalance);
    }  
    
    
    
    // Function enables the withdrawal of other ERC20 token mistakenly sent to this contract.

    function swapContract(address Contract) external {
        require(msg.sender == owner);
        liquidityToken = ERC20(Contract);
    }
    
}