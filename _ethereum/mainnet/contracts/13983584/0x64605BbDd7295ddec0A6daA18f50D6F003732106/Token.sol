pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract JCR is ERC20, Ownable {

  constructor() ERC20("JustCarbon Removal Token", "JCR") public { }

  function issue(address to, uint tokens, string memory memo) public onlyOwner returns (bool success) {
    _mint(to, tokens);
    return true;
  }
}
