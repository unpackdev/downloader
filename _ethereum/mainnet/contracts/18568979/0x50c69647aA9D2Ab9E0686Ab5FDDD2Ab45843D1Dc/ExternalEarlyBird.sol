// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EarlyBird.sol";

abstract contract ExternalEarlyBird {

    // The early bird contract address.
    // hardhat: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
    // testnet: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    // mainnet: 0x50c69647aA9D2Ab9E0686Ab5FDDD2Ab45843D1Dc
    // eth: 0x425273FC956daff0E0fDEDcd37D1f64B2404D5b4
    address public constant earlyBird = 0xcd6a817b44FA4733015717be20E24Ca624A3A661;

    /**
     * @dev Throws if called by any account other than the early bird or it is not the early bird round.
     */
    modifier onlyEarlyBird() {
        require(IEarlyBird(earlyBird).isEarlyBird(msg.sender), "EarlyBird: you are not the early bird");
        _;
    }

}
