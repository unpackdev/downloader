// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.4;
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

//██╗░░░██╗████████╗░█████╗░
//██║░░░██║╚══██╔══╝██╔══██╗
//╚██╗░██╔╝░░░██║░░░██║░░╚═╝
//░╚████╔╝░░░░██║░░░██║░░██╗
//░░╚██╔╝░░░░░██║░░░╚█████╔╝
//░░░╚═╝░░░░░░╚═╝░░░░╚════╝░

contract VTC is ERC20, ERC20Burnable, Ownable {
  using SafeMath for uint256;
  uint256 constant maxAllowed=8000000*10**18;
  uint256 private _totalSupply;
  uint256 private max;
  mapping(address => uint256) private _balances;
  mapping(address => bool) operators;
  
  constructor() ERC20("Virtual Transactable Currency", "VTC") { 

  }
  function generate(address to, uint256 amount) external {
    require((max+amount)<=maxAllowed,"All tokens have been staked");
    require(operators[msg.sender], "No Access");
    _totalSupply = _totalSupply.add(amount);
    max=max.add(amount);
    _balances[to] = _balances[to].add(amount);
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (operators[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function operatoradd(address operator) external onlyOwner {
    operators[operator] = true;
  }

  function operatordelete(address operator) external onlyOwner {
    operators[operator] = false;
  }
  
  function maxSupply() public  pure returns (uint256) {
    return maxAllowed;
  }
  
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

}