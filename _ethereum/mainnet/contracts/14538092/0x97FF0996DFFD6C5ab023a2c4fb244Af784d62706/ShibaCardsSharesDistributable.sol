// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ShibaCardsAccessible.sol";

import "./ISharesDistributer.sol";
import "./IDividendsDistributer.sol";

abstract contract ShibaCardsSharesDistributable is ShibaCardsAccessible {
  ISharesDistributer public sharesDistributer;

  function setSharesDistributer(address distributer)
    public
    onlyAdmin
  {
    sharesDistributer = ISharesDistributer(distributer);
  }
}
