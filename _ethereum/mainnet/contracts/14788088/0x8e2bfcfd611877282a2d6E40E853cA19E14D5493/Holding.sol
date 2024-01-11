import "./IERC20.sol";
contract Holding {

  uint256 public unlocked;
  address public recipient;
  address public token;
  address public owner; 

  constructor(address _token, address _recipient) {
    owner = msg.sender;
    token = _token;
    recipient = _recipient;
  }

  function unlock(uint256 unlockAmount) public onlyOwner {
    require(unlockAmount <= IERC20(token).balanceOf(address(this)), "unlock > balance"); 
    unlocked = unlockAmount;
  }

  function sendToken(uint256 amount) public onlyOwner {
    require(amount <= unlocked, "more than unlocked");
    IERC20(token).transfer(recipient, amount);       
  }

  function changeRecipient(address newRecipient) public onlyOwner {
    require(newRecipient != address(0));
    recipient  = newRecipient;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

  modifier onlyOwner {
      require(msg.sender == owner, "only owner");
      _;
  }

}
