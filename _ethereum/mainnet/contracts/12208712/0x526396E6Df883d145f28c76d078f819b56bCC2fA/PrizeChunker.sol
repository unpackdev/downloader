pragma solidity >=0.6.0;

import "./IERC20Upgradeable.sol";
import "./PeriodicPrizeStrategyListener.sol";
import "./PeriodicPrizeStrategy.sol";

contract PrizeChunker is PeriodicPrizeStrategyListener {

  event AddedPrizeChunk(uint256 prize);

  IERC20Upgradeable public token;
  uint256 public prizeSize;
  PeriodicPrizeStrategy public prizeStrategy;

  constructor (IERC20Upgradeable _token, uint256 _prizeSize, PeriodicPrizeStrategy _prizeStrategy) public {
    require(address(_token) != address(0), "PrizeChunker/token-not-def");
    require(_prizeSize > 0, "PrizeChunker/prize-gt-zero");
    require(address(_prizeStrategy) != address(0), "PrizeChunker/prize-strat-not-def");

    token = _token;
    prizeSize = _prizeSize;
    prizeStrategy = _prizeStrategy;
  }

  function afterPrizePoolAwarded(uint256 randomNumber, uint256 prizePeriodStartedAt) external override onlyPrizeStrategy {
    uint256 balance = token.balanceOf(address(this));
    uint256 prize = prizeSize;
    if (balance < prize) {
      prize = balance;
    }
    if (prize > 0) {
      token.transfer(address(prizeStrategy.prizePool()), prize);
    }

    emit AddedPrizeChunk(prize);
  }

  modifier onlyPrizeStrategy() {
    require(msg.sender == address(prizeStrategy), "PrizeChunker/only-prize-strat");
    _;
  }
}