pragma solidity ^0.5.17;

/**
 * 
 * Clash Token's Liquidity Vault
 * 
 * Simple smart contract to decentralize the uniswap liquidity, providing proof of liquidity indefinitely.
 * Timelock for team tokens.
 * Original smart contract: MrBlobby (UniPower), modified by George.
 * https://www.spiritclash.com/
 * 
 */
 
contract Vault {
    
    ERC20 constant ClashToken = ERC20(0x6Fa0952355607dFB2d399138B7fE10EB90F245e4);
    ERC20 constant liquidityToken = ERC20(0x894E287673EDbD90428B1a67DEae3e7D094E3E12);
    
    address owner = msg.sender;
    uint256 public VaultCreation = now;
    uint256 public lastWithdrawal;
    
    uint256 public migrationLock;
    address public migrationRecipient;

    event liquidityMigrationStarted(address recipient, uint256 unlockTime);
    
    
    /**
     * Withdraw liquidity
     * Has a hardcap of 1% per 48 hours
     */
    function withdrawLiquidity(address recipient, uint256 amount) external {
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        require(amount < (liquidityBalance / 100)); // Max 1%
        require(lastWithdrawal + 48 hours < now); // Max once every 48 hrs
        require(msg.sender == owner);
        
        liquidityToken.transfer(recipient, amount);
        lastWithdrawal = now;
    } 
    
    
    /**
     * This function allows liquidity to be moved, after a 14 days lockup -preventing abuse.
     */
    function startLiquidityMigration(address recipient) external {
        require(msg.sender == owner);
        migrationLock = now + 14 days;
        migrationRecipient = recipient;
        emit liquidityMigrationStarted(recipient, migrationLock);
    }
    
    
    /**
     * Moves liquidity to new location, assuming the 14 days lockup has passed -preventing abuse.
     */
    function processMigration() external {
        require(msg.sender == owner);
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(migrationRecipient, liquidityBalance);
    }
    
    
    /**
     * ClashToken tokens locked in this Vault can be withdrawn 3 months after its creation.
     */
    function withdrawClashToken(address recipient, uint256 amount) external {
        require(msg.sender == owner);
        require(now > VaultCreation + 90 days);
        ClashToken.transfer(recipient, amount);
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