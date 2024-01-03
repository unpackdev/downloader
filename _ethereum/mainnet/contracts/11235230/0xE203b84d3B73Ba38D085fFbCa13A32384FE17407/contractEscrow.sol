// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
pragma solidity ^0.4.17;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract contractEscrow {
    address public owner = msg.sender;
    address public feeAddress = msg.sender;
  address tracker_0x_address = 0x1E96E56857613eF737B4048FCFFD1450226dc9E3; // ContractA Address
  uint public totalTokenBalance = ERC20(tracker_0x_address).balanceOf(address(this));
  uint public totalBuyers = 0;
  uint public totalReferrers = 0;
  uint public totalBuyToken = 0;
  uint public totalWeiUsedToBuy = 0;
  uint public totalReferralEarn = 0;
  uint public tokenPriceToWei = 1000;
  uint public referralRewardPercent = 25;
  mapping ( address => bool ) public buyer;
  mapping ( address => bool ) public referrer;
  mapping ( address => uint256 ) public balances;
  address[] private buyers;
  address[] private referrers;
  
  function() external payable {
        buy(owner);
    }
  function getlist() public view returns(address[], address[] ){
      require(msg.sender == owner, "Should be owner!");
      return (buyers, referrers);
  }
  function setPrice(uint price) public {
      require(msg.sender == owner, "Should be owner!");
      tokenPriceToWei = price;
  }
  function setFeeAddress(address FeeAddress) public {
      require(msg.sender == owner, "Should be owner!");
      feeAddress = FeeAddress;
  }
  function setTokenAdddress(address TokenAddress) public {
      require(msg.sender == owner, "Should be owner!");
      tracker_0x_address = TokenAddress;
  }
    function setRewardPercent(uint percent) public {
      require(msg.sender == owner, "Should be owner!");
      referralRewardPercent = percent;
  }
  function buyExt(address referrerAddress) external payable{
      buy(referrerAddress);
  }
  
  function buy(address referrerAddress) private{
      require(msg.value >= 0.02 ether, "Minimum buy 0.02");
      uint buyAmount = msg.value * tokenPriceToWei;
      //require(ERC20(tracker_0x_address).balanceOf(this) >= buyAmount, "Token balance insufficient in contract");
      if(msg.data.length != 0) {
          if (buyer[referrerAddress]){
              ERC20(tracker_0x_address).transfer(msg.sender, buyAmount);
              ERC20(tracker_0x_address).transfer(referrerAddress, buyAmount*referralRewardPercent/100);
              address(referrerAddress).transfer(msg.value*referralRewardPercent/100 );
              address(feeAddress).transfer(address(this).balance);
          } else {
              ERC20(tracker_0x_address).transfer(msg.sender, buyAmount);
              ERC20(tracker_0x_address).transfer(referrerAddress, buyAmount*referralRewardPercent/100);
              address(feeAddress).transfer(address(this).balance);
          }
          totalReferralEarn = totalReferralEarn + (msg.value*referralRewardPercent/100);
          totalReferrers = totalReferrers + 1;
          referrers.push(referrerAddress);
          
      }else {
          ERC20(tracker_0x_address).transfer( msg.sender, buyAmount);
          address(feeAddress).transfer(address(this).balance);
      }
      buyer[msg.sender] = true;
      totalBuyers = totalBuyers + 1;
      buyers.push(msg.sender);
      totalBuyToken = totalBuyToken + buyAmount;
      totalWeiUsedToBuy = totalWeiUsedToBuy + msg.value;
      totalTokenBalance = ERC20(tracker_0x_address).balanceOf(address(this));
  }

  function deposit(uint tokens) public {

    // add the deposited tokens into existing balance 
    balances[msg.sender]+= tokens;

    // transfer the tokens from the sender to this contract
    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    totalTokenBalance = ERC20(tracker_0x_address).balanceOf(address(this));
  }

  function returnTokens(uint tokens) public {
      if (balances[msg.sender] > tokens)
    ERC20(tracker_0x_address).transfer(msg.sender, tokens);
    balances[msg.sender] = balances[msg.sender] - tokens;
    totalTokenBalance = ERC20(tracker_0x_address).balanceOf(address(this));
    
  }
  function returnAllTokens() public {
    ERC20(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
    balances[msg.sender] = 0;
    totalTokenBalance = ERC20(tracker_0x_address).balanceOf(address(this));
    
  }
  function depositCustomToken(address tokenContractHash, uint tokens) public {
    require(msg.sender == owner, "Should be owner!");
    // transfer the tokens from the sender to this contract
    ERC20(tokenContractHash).transferFrom(msg.sender, address(this), tokens);
  }
 
  function returnAllCustomTokens(address tokenContractHash, address toAddress) public {
     require(msg.sender == owner, "Should be owner!");
    ERC20(tokenContractHash).transfer(toAddress, ERC20(tokenContractHash).balanceOf(address(this)));
  }
  
  function bulkDrop(address tokenContractHash, address[] recipients, uint256[] values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      ERC20(tokenContractHash).transfer(recipients[i], values[i]);
    }
  }
  function bulkDropSameValue(address tokenContractHash, address[] recipients, uint256 value) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      ERC20(tokenContractHash).transfer(recipients[i], value);
    }
  }

}