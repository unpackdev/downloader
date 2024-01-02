/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */

import "./IRWAOracle.sol";
import "./Ownable.sol";

pragma solidity 0.8.16;

contract RWAOracleTestOnly is IRWAOracle, Ownable {
  // Matches contracts/rwaOracles/IRWAOracleExternalComparisonCheck.sol
  event RWAExternalComparisonCheckPriceSet(
    int256 oldChainlinkPrice,
    uint80 indexed oldRoundId,
    int256 newChainlinkPrice,
    uint80 indexed newRoundId,
    int256 oldRWAPrice,
    int256 newRWAPrice
  );
  uint256 public price;
  uint256 public timestamp;

  constructor(address owner, uint256 _startingPrice) {
    transferOwnership(owner);
    price = _startingPrice;
    timestamp = block.timestamp;
    emit RWAExternalComparisonCheckPriceSet(
      0,
      0,
      0,
      0,
      0,
      int256(_startingPrice)
    );
  }

  function getPriceData() external view override returns (uint256, uint256) {
    return (price, timestamp);
  }

  function setPrice(uint256 _price) external onlyOwner {
    emit RWAExternalComparisonCheckPriceSet(
      0,
      0,
      0,
      0,
      int256(price),
      int256(_price)
    );
    price = _price;
    timestamp = block.timestamp;
  }
}
