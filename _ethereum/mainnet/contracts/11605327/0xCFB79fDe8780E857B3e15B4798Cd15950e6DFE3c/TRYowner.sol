// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address payable owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = payable(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0), "Cannot transfer ownership to the 0 address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


interface TRYToken {
    function setTrans100 (uint256 _trans100) external;
    function setRewardPoolDivisor (uint256 _rdiv) external;    
    function setRebalanceDivisor (uint256 _rebalanceDivisor) external; 
    function setRebalanceInterval (uint256 _interval) external;  
    function setRebalanceRewardDivisior (uint256 _rDivisor) external;
    function toggleFeeless (address _addr) external; 
    function setOracle (address _addr, bool _bool) external; 
    function setMinRebalanceAmount (uint256 amount_) external;
    function setBurnTxFee (uint256 amount_) external;
    function setAntiDumpFee (uint256 amount_) external;
    function RebalanceLiquidity () external;
    function addLPFarm(address _farm) external;
}

contract TRYowner is Ownable{
    
    using SafeMath for uint256;
    
    
    TRYToken public token;
    
    
    constructor() 
    {
        token = TRYToken(0xc12eCeE46ed65D970EE5C899FCC7AE133AfF9b03); 
        
    }
    
    function setTrans100(uint256 _trans100) public onlyOwner {
        require(_trans100 <= 100e18, "Cannot set over 100 transactions"); 
        token.setTrans100(_trans100);
    }
    
    function setRewardPoolDivisor(uint256 _rdiv) public onlyOwner {
        require(_rdiv >= 100, "Cannot set over 1% RewardPoolDivisor"); 
        token.setRewardPoolDivisor(_rdiv);
    }
    
    function setRebalanceDivisor(uint256 _rebalanceDivisor) public onlyOwner {
        require(_rebalanceDivisor >= 10, "Cannot set rebalanceDivisor over 10%");
        require(_rebalanceDivisor <= 100, "Cannot set rebalanceDivisor under 1%");
        token.setRebalanceDivisor(_rebalanceDivisor);
    }
    
    function setRebalanceInterval(uint256 _interval) public onlyOwner{
        require(_interval<= 7200, "Cannot set over 2 hour interval");  
        require(_interval>= 3600, "Cannot set under 1 hour interval");
        token.setRebalanceInterval(_interval);
    }
    
    function setRebalanceRewardDivisior(uint256 _rDivisor) public onlyOwner {
        require(_rDivisor <= 25, "Cannot set rebalanceRewardDivisor under 4%");
        require(_rDivisor >= 10, "Cannot set rebalanceRewardDivisor over 10%");
        token.setRebalanceRewardDivisior(_rDivisor);   
    } 

    function toggleFeeless(address _addr) public onlyOwner {
        token.toggleFeeless(_addr); 
    }
    
    function setOracle(address _addr, bool _bool) public onlyOwner {  
        token.setOracle(_addr, _bool);
    } 
    
    function setMinRebalanceAmount(uint256 amount_) public onlyOwner {
        require(amount_ <= 100e18, "Cannot set over 100 TRY tokens");
        require(amount_ >= 20e18, "Cannot set under 20 TRY tokens");
        token.setMinRebalanceAmount(amount_);
    }
    
    function setBurnTxFee(uint256 amount_) public onlyOwner {
        require(amount_ >= 100, "Cannot set over 1% burnTxFee"); 
        token.setBurnTxFee(amount_);
    }
    
    function setAntiDumpFee(uint256 amount_) public onlyOwner {
        require(amount_ >= 10, "Cannot set over 10% antiDumpFee"); 
        require(amount_ <= 100, "Cannot set under 1% antiDumpFee");
        token.setAntiDumpFee(amount_);
    }
    
    function RebalanceLiquidity() public {
        token.RebalanceLiquidity();
    }
    
    function addLPFarm(address _farm) public onlyOwner{
        require(_farm == address(0), "LPfarm already set");
        token.addLPFarm(_farm);
    }
    
}