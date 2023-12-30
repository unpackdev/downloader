pragma solidity ^0.4.16;

/**
 * token contract functions
*/
contract Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal constant returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract lockContract is owned{
    using SafeMath for uint256;
    
    /*
     * deposit vars
    */
    struct Items {
        address tokenAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (uint256 => Items) public lockedToken;
    
    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);
    
    /**
     * Constrctor function
    */
    function lockContract() public {

    }
    
    /**
     *lock tokens
    */
    function lockTokens(address _tokenAddress, uint256 _amount, uint256 _unlockTime) onlyOwner public returns (uint256 _id) {
        require(_amount > 0);
        require(_unlockTime < 10000000000);
        require(Token(_tokenAddress).transferFrom(msg.sender, this, _amount));
        
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        
        allDepositIds.push(_id);
    }
    
    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) public onlyOwner {
        require(block.timestamp >= lockedToken[_id].unlockTime);
        require(!lockedToken[_id].withdrawn);
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount));
        
        lockedToken[_id].withdrawn = true;
        
        LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

     /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return Token(_tokenAddress).balanceOf(this);
    }
    
    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[])
    {
        return allDepositIds;
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address tokenAddress, uint256 tokenAmount, uint256 unlockTime, bool withdrawn)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    
    /*get number of active deposits*/
    function numOfActiveDeposits() public view returns (uint256) {
        uint256 staked = 0;
        for (uint i = 0; i < allDepositIds.length; i++) {
            if (!lockedToken[allDepositIds[i]].withdrawn) {
                staked++;
            }
        }
        return staked;
    }
    
    /*get getWithdrawableDeposits*/
    function getWithdrawableDeposits() view public returns (uint256[])
    {
        uint256[] memory deposits = new uint256[](numOfActiveDeposits());
        uint256 tempIdx = 0;
        for(uint256 i = 0; i < allDepositIds.length; i++) {
            if(!lockedToken[allDepositIds[i]].withdrawn) {
                deposits[tempIdx] =  allDepositIds[i];
                tempIdx ++;
            }
        }
        return deposits;
    }
    
}