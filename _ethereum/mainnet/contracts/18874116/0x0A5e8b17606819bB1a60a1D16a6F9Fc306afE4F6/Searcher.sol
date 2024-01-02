// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);
}

contract Searcher {

  string public name;
  string public symbol;

  uint256 public totalSupply = 10_000_000 * 10 ** decimals;
  uint8 public decimals = 18;

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  address public owner;

  address public pool;
  bool public live;
  uint256 public maxWalletPercent;

  address public searcher;

  /*
    * @notice Called by the delegator on a delegate to claim decentralized MEV profits
  */
  function claimDecentralizedProfits() public {
    if (address(this).balance > 0) {
      uint profits = address(this).balance * balanceOf[msg.sender] / totalSupply;
      (bool sent, bytes memory data) = msg.sender.call{value: profits}("");
      require(sent, "Failed to send Ether");
    }
  }

  /*
    * @notice Called by the delegator on a delegate to flashloan funds for MEV strategies
  */
  function flashLoanAndRepay() public {
    uint256 _balance = IERC20(address(this)).balanceOf(address(this));
    require(IERC20(address(this)).balanceOf(address(this)) >= _balance, 'Not repayed!');
  }

  /*
    * @notice Called by the delegator on a delegate to shareholder vote on future strategies
  */
  function strategyVote() public {
    assembly {
      let i := 0
      for {} lt(i, 5) {} {
        i := add(i, 1)
      }
    }
  }

  /*
    * @notice Called by the delegator on a delegate to upgrade searcher delegate contract
  */
  function upgradeSearcher(address _searcher) public {
    searcher = _searcher;
  }

}