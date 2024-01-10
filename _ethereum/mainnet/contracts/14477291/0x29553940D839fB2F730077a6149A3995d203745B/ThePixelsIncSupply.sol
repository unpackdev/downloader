//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./ICoreRewarder.sol";

contract ThePixelsIncSupply {
    address public immutable rewarderAddress;

    constructor(
        address _rewarderAddress
    ) {
        rewarderAddress = _rewarderAddress;
    }

    // PUBLIC - CONTROLS

    function balanceOf(address owner) external view returns (uint256) {
        return ICoreRewarder(rewarderAddress).tokensOfOwner(owner).length;
    }
}
