// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PLINK is PTokenBase {
    constructor(address _controller)
        public
        PTokenBase("pLINK Pool", "pLINK", 0x514910771AF9Ca656af840dff83E8264EcF986CA, _controller)
    {}
}
