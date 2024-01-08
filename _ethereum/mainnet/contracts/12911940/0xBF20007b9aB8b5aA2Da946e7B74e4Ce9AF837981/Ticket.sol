// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "./SortitionSumTreeFactory.sol";
import "./UniformRandomNumber.sol";

import "./ControlledToken.sol";
import "./TicketInterface.sol";

contract Ticket is ControlledToken, TicketInterface {
  using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;

  bytes32 constant private TREE_KEY = keccak256("ArchiPrize/Ticket");
  uint256 constant private MAX_TREE_LEAVES = 5;

  SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    TokenControllerInterface _controller
  )
    public
    virtual
    override
    initializer
  {
    super.initialize(_name, _symbol, _decimals, _controller);
    sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);
  }

  function chanceOf(address user) external view returns (uint256) {
    return sortitionSumTrees.stakeOf(TREE_KEY, bytes32(uint256(user)));
  }

  function draw(uint256 randomNumber) external view override returns (address) {
    uint256 bound = totalSupply();
    address selected;
    if (bound == 0) {
      selected = address(0);
    } else {
      uint256 token = UniformRandomNumber.uniform(randomNumber, bound);
      selected = address(uint256(sortitionSumTrees.draw(TREE_KEY, token)));
    }
    return selected;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == to) {
      return;
    }

    if (from != address(0)) {
      uint256 fromBalance = balanceOf(from).sub(amount);
      sortitionSumTrees.set(TREE_KEY, fromBalance, bytes32(uint256(from)));
    }

    if (to != address(0)) {
      uint256 toBalance = balanceOf(to).add(amount);
      sortitionSumTrees.set(TREE_KEY, toBalance, bytes32(uint256(to)));
    }
  }

}