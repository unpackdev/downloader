// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PDAI is PTokenBase {
    constructor(address _controller)
        public
        PTokenBase("pDAI Pool", "pDAI", 0x6B175474E89094C44Da98b954EedeAC495271d0F, _controller)
    {}
}
