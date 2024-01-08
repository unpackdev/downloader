// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./StakingController.sol";
import "./StakingControllerLib.sol";
import "./ViewExecutor.sol";
import "./Viewer.sol";
import "./RevertCaptureLib.sol";
import "./Bytes.sol";

contract Query is Viewer {
  using BytesManip for *;

  constructor(address sc, address user) public {
    StakingController(sc).receiveCallback(user, address(0x0));
    address viewLayer = address(new Viewer());
    bytes memory response =
      StakingController(sc).query(
        viewLayer,
        abi.encodeWithSelector(Viewer.render.selector, user)
      );
    bytes memory returnData = abi.encode(response, 0, 0, block.timestamp);
    assembly {
      return(add(0x20, returnData), mload(returnData))
    }
  }

  function decodeResponse()
    public
    returns (
      bytes memory,
      uint256,
      uint256,
      uint256
    )
  {}
}
