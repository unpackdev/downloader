/*

 * Stack HODL Vault
 
 * Smart contract to decentralize 10% of Stack total supply reserved to reward top 10 HODLers on weekly basis

 * Official Website:
   https://DexStack.Finance
 
 * Telelgram Group:
   https://t.me/DexStackFinance
   
 */
 




pragma solidity ^0.6.0;



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



contract StackHodlVault {
    
    using SafeMath for uint256;
    
    ERC20 constant StackToken = ERC20(0xdFbcaCF4D31DA9089dC6d1Ee32CE4CCF4Ef0ac50);
    
    address owner = msg.sender;
    uint256 public lastHodlTokenDistribution = now;
    
    uint256 public migrationLock;
    address public migrationRecipient;
    
    
// Function allows a weekly hardcap of 10% HODL token distribution.

    function distributeHodlToken() external {
        uint256 StackBalance = StackToken.balanceOf(address(this));
        require(msg.sender == owner);
        require(lastHodlTokenDistribution < now);
        uint256 TenPercent = StackBalance.mul(10).div(100);
        StackToken.transfer(owner, TenPercent);
        lastHodlTokenDistribution = lastHodlTokenDistribution + 7 days;
    } 
    

// Function allows HODL token to be migrated, after 1 month lockup -preventing abuse.


    function startMigration(address recipient) external {
        require(msg.sender == owner);
        migrationLock = now + 720 hours;
        migrationRecipient = recipient;
    }
    
    
// Migrates HODL token to new location, assuming the 1 month lockup has passed -preventing abuse.


    function processMigration() external {
        require(msg.sender == owner);
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 StackBalance = StackToken.balanceOf(address(this));
        StackToken.transfer(migrationRecipient, StackBalance);
    }  
    
}



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