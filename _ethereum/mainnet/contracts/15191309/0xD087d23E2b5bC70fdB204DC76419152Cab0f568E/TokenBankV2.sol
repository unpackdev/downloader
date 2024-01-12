pragma solidity >=0.4.21 <0.6.0;
import "./MultiSigTools.sol";
import "./TrustListTools.sol";
import "./TokenClaimer.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenBankV2 is Ownable, TokenClaimer, TrustListTools{
  using SafeERC20 for IERC20;

  string public bank_name;
  //address public erc20_token_addr;

  event withdraw_token(address token, address to, uint256 amount);
  event issue_token(address token, address to, uint256 amount);

  event RecvETH(uint256 v);
  function() external payable{
    emit RecvETH(msg.value);
  }

  constructor(string memory name) public{
    bank_name = name;
  }


  function claimStdTokens(address _token, address payable to)
    public onlyOwner{
      _claimStdTokens(_token, to);
  }

  function balance(address erc20_token_addr) public view returns(uint){
    if(erc20_token_addr == address(0x0)){
      return address(this).balance;
    }
    return IERC20(erc20_token_addr).balanceOf(address(this));
  }

  function transfer(address erc20_token_addr, address payable to, uint tokens)
    public
    onlyOwner
    returns (bool success){
    require(tokens <= balance(erc20_token_addr), "TokenBankV2 not enough tokens");
    if(erc20_token_addr == address(0x0)){
      (bool _success, ) = to.call.value(tokens)("");
      require(_success, "TokenBankV2 transfer eth failed");
      emit withdraw_token(erc20_token_addr, to, tokens);
      return true;
    }
    IERC20(erc20_token_addr).safeTransfer(to, tokens);
    emit withdraw_token(erc20_token_addr, to, tokens);
    return true;
  }

  function issue(address erc20_token_addr, address payable _to, uint _amount)
    public
    is_trusted(msg.sender)
    returns (bool success){
      require(_amount <= balance(erc20_token_addr), "TokenBankV2 not enough tokens");
      if(erc20_token_addr == address(0x0)){
        (bool _success, ) = _to.call.value(_amount)("");
        require(_success, "TokenBankV2 transfer eth failed");
        emit issue_token(erc20_token_addr, _to, _amount);
        return true;
      }
      IERC20(erc20_token_addr).safeTransfer(_to, _amount);
      emit issue_token(erc20_token_addr, _to, _amount);
      return true;
    }
}


contract TokenBankV2Factory {
  event CreateTokenBank(string name, address addr);

  function newTokenBankV2(string memory name) public returns(address){
    TokenBankV2 addr = new TokenBankV2(name);
    emit CreateTokenBank(name, address(addr));
    addr.transferOwnership(msg.sender);
    return address(addr);
  }
}
