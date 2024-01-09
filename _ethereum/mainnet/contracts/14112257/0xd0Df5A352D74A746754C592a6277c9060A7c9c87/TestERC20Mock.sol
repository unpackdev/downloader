pragma solidity 0.6.11;

import "./ERC20.sol";

contract TestERC20Mock is ERC20 {
    
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
