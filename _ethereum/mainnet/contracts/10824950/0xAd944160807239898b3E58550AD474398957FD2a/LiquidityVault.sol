pragma solidity ^0.5.13;


/**
 * 
 * Squirrel's Liquidity Vault
 * 
 * Simple smart contract to lock the uniswap liquidity.
 * For project info visit: https://squirrel.finance
 * 
 */
contract LiquidityVault {

    ERC20 constant liquidityToken = ERC20(0x0C5136B5d184379fa15bcA330784f2d5c226Fe96);
    
    address blobby = msg.sender;
    
    uint256 public migrationStart;
    address public migrationRecipient;
    
    /**
     * There may be desire by NUT holders to migrate liquidity in future
     * So this function allows liquidity to be moved, after a 14 days lockup -preventing abuse.
     */
    function startLiquidityMigration(address recipient) external {
        require(msg.sender == blobby);
        migrationStart = now;
        migrationRecipient = recipient;
    }
    
    
    /**
     * Moves liquidity to new location, assuming the 14 days lockup has passed -preventing abuse.
     */
    function processMigration() external {
        require(msg.sender == blobby);
        require(migrationRecipient != address(0));
        require(migrationStart + 14 days < now); // Requires 14 days have passed
        
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(migrationRecipient, liquidityBalance);
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