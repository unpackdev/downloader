// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IIYKYKERC1155.sol";


contract IYKYKERC1155 is ERC1155, IIYKYKERC1155, Ownable {
  
  address public minter;

  event Minter(
    address newMinter,
    uint256 timestamp
  );

  constructor() ERC1155("ipfs://QmacPfXeZT4Gh6GeZ6kXq9uJ8SsWUTqXZ5Y6FQ5xgnxCML/{id}.json") {}

  modifier onlyIYKYKFundContract {
    require(minter == msg.sender, "Only IYKYKFund contract can mint or burn token");
    _;
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }

  function mint(address account, uint256 id, uint256 amount, bytes memory data) external override onlyIYKYKFundContract {
    _mint(account, id, amount, data);
  }

  function setMinter(address newMinter) external onlyOwner {
    require(newMinter != address(0), "Invalid address");
    minter = newMinter;
    emit Minter(newMinter, block.timestamp);
  }

}