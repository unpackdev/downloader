// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ArtBoxTypes.sol";

library ArtBoxUtils {
  function clone(ArtBoxTypes.Box memory from)
    internal
    pure
    returns (ArtBoxTypes.Box memory)
  {
    return
      ArtBoxTypes.Box(
        from.id,
        from.locked,
        from.x,
        from.y,
        from.box,
        from.minter,
        from.locker
      );
  }
}
