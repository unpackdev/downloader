// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./IPGAT.sol";

// simplified reward swap contract
contract RewardSwap {

  IPGAT public apToken;
  address public miner;
  address public immutable operator;

  event Mint(address indexed recipient, uint256 amount);

  modifier onlyMiner() {
    require(msg.sender == miner, "Only Miner contract can call");
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == operator, "Only Operator can call");
    _;
  }

  constructor (address _apToken, address _miner) {
    apToken = IPGAT(_apToken);
    miner = _miner;
    operator = msg.sender;
  }

  function setMiner(address _miner) external onlyOperator {
    miner = _miner;
  }

  function setAPToken(address _apToken) external onlyOperator {
    apToken = IPGAT(_apToken);
  }

  function swap(address _recipient, uint256 _amount) external onlyMiner returns (uint256) {
    apToken.mint(_recipient, _amount);
    emit Mint(_recipient, _amount);
    return _amount;
  }
}
