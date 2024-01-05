pragma solidity 0.6.12;

import "./ERC1155.sol";

contract MockERC1155 is ERC1155('Mock') {
  function mint(uint id, uint amount) public {
    _mint(msg.sender, id, amount, '');
  }
}
