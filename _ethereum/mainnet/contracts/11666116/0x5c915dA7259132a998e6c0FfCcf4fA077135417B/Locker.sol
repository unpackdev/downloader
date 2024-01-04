/**
 *Submitted for verification at Etherscan.io on 2021-01-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

pragma solidity ^0.4.13;

contract _ERC20Basic {
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool);
}


contract Locker {
    address owner;
    
    address tokenAddress = 0xA5959E9412d27041194c3c3bcBE855faCE2864F7; // UniDexGas (UNDG) token address
    uint256 unlockUnix = now + (31 days) * 2; // 2 months
    
    _ERC20Basic token = _ERC20Basic(tokenAddress);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function unlockTeamTokens() public {
        require(owner == msg.sender, "You is not owner");
        require( now > unlockUnix, "Is not unlock time now");
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    //Control
    function getLockAmount() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getTokenAddress()  public view returns (address) {
        return tokenAddress;
    }
    
    function getUnlockTimeLeft() public view returns (uint) {
        return unlockUnix - now;
    }
}