// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./IBridge.sol";
import "./Utilities.sol";

contract CommunityReservePipe is Utilities {
  address constant SOURCE_TOKEN = 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
  address constant ROLLUP_BRIDGE = 0x96E471B5945373dE238963B4E032D3574be4d195;
  address constant TREASURY = 0x5d136Ef53fC4d85AE3A5e28Cc6762ec9975d18Dc;

  constructor () {
    Utilities._safeApprove(SOURCE_TOKEN, ROLLUP_BRIDGE, uint256(-1));
  }

  fallback () external payable {
    uint256 balance = Utilities._safeBalance(SOURCE_TOKEN, msg.sender);
    Utilities._safeTransferFrom(SOURCE_TOKEN, msg.sender, address(this), balance);
    IBridge(ROLLUP_BRIDGE).deposit(SOURCE_TOKEN, balance, TREASURY);
  }
}
