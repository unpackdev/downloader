pragma solidity ^0.6.0;


contract TeamVault {
    
    ERC20 constant GUFIToken = ERC20(0xd53F0115E3d255d2E6F7DeAd5E0E17aE45EEBDDa);
    ERC20 constant TeamToken = ERC20(0xb7d0596e636dBEc773075372868b14d5a224C0Fd);
    
    address blobby = msg.sender;
    uint256 public lastTradingFeeDistribution;
    uint256 public migrationLock;
    address public migrationRecipient;
    
    
 
    function distributeWeekly(address recipient) external {
        uint256 teamBalance = TeamToken.balanceOf(address(this));
        require(lastTradingFeeDistribution + 7 days < now); // Max once a day
        require(msg.sender == blobby);
        TeamToken.transfer(recipient, (teamBalance / 100));
        lastTradingFeeDistribution = now;
    } 
    
    
    function startTeamMigration(address recipient) external {
        require(msg.sender == blobby);
        migrationLock = now + 120 days;
        migrationRecipient = recipient;
    }
    
    
    function processMigration() external {
        require(msg.sender == blobby);
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 teamBalance = TeamToken.balanceOf(address(this));
        TeamToken.transfer(migrationRecipient, teamBalance);
    }
    
    
    
    function getBlobby() public view returns (address){
        return blobby;
    }
    function getTeamBalance() public view returns (uint256){
        return TeamToken.balanceOf(address(this));
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