// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import "./TokenTurner.sol";

contract TokenTurnerMainnet is TokenTurner {
  function INPUT_TOKEN () internal view override returns (address) {
    // DAI
    return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  }

  function OUTPUT_TOKEN () internal view override returns (address) {
    // HBT
    return 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
  }

  function COMMUNITY_FUND () internal view override returns (address) {
    // multisig
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  function getCurrentEpoch () public view override returns (uint256 epoch) {
    // ~~(Date.parse('2021-03-10 11:00 UTC+1') / 1000)
    uint256 FUNDING_START_DATE = 1615370400;
    // 1 week
    uint256 EPOCH_SECONDS = 604800;
    epoch = (block.timestamp - FUNDING_START_DATE) / EPOCH_SECONDS;
    if (epoch > MAX_EPOCH) {
      epoch = MAX_EPOCH;
    }
  }
}
