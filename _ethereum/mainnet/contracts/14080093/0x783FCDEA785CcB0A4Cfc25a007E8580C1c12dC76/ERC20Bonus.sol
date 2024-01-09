pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

contract ERC20TokenBankInterface{
  //function balance() public view returns(uint);
 // function token() public view returns(address, string memory);
  function issue(address _to, uint _amount) public returns (bool success);
}
interface IERC20 {
    function totalSupplyAt(uint _blockNumber) external view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint);
}

contract ERC20Bonus{
  using SafeMath for uint;

  ERC20TokenBankInterface public bank;
  address public share_address;
  uint public snapshot_block;
  uint public start_block;
  uint public end_block;
  uint public bonus_total;
  uint public claimed_bonus; 

  mapping (address => bool) public is_claimed;

  event ClaimedBonus(address account, uint shareAmount, uint amount);

  constructor(address _bank, address _share_address, uint _snapshot_block, uint _start_block, uint _end_block, uint _bonus_total) public {
    require(_bank != address(0x0), "invalid address");
    require(_share_address != address(0x0), "not ERC20");
    bank = ERC20TokenBankInterface(_bank);
    share_address = _share_address;
    snapshot_block = _snapshot_block;
    start_block = _start_block;
    end_block = _end_block;
    bonus_total = _bonus_total;
  }

  function claimBonus() public returns(bool){
    require(block.number >= start_block, "bonus not begin");
    require(block.number <= end_block, "bonus end");
    require(!is_claimed[msg.sender], "has claimed");
    uint share_amount = IERC20(share_address).balanceOfAt(msg.sender, snapshot_block);
    require(share_amount > 0, "no share");
    uint share_total = IERC20(share_address).totalSupplyAt(snapshot_block);

    uint bonus_amount = share_amount.safeMul(bonus_total).safeDiv(share_total);

    is_claimed[msg.sender] = true;
    claimed_bonus += bonus_amount;
    bank.issue(msg.sender, bonus_amount);
    emit ClaimedBonus(msg.sender, share_amount, bonus_amount);
    return true;
  }

  
}

contract ERC20BonusFactory{
  event CreateERC20Bonus(address addr);

  function newBonus(address _bank, address _share_address, uint _snapshot_block, uint _start_block, uint _end_block, uint _bonus_total)
  public returns (ERC20Bonus){
    ERC20Bonus addr = new ERC20Bonus(_bank, _share_address, _snapshot_block, _start_block, _end_block, _bonus_total);
    emit CreateERC20Bonus(address(addr));
    return addr;
  }
}