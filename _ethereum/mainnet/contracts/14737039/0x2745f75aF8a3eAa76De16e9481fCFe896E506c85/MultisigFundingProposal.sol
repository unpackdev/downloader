// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./ISablier.sol";

contract MultisigFundingProposal {
    address public constant TORN = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address public constant MULTISIG = 0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4;
    address public constant SABLIER = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888;
    uint256 public constant AMOUNT = 35_000 ether; // 35,000 TORN
    uint256 public constant VESTING_AMOUNT = 65_000 ether; // 65,000 TORN
    uint256 public constant VESTING_PERIOD = 31_536_000; // 365 days

    event StreamCreated(uint256 streamId);

    function executeProposal() external {
        // send TORN to multisig
        require(IERC20(TORN).transfer(MULTISIG, AMOUNT), "Transfer failed");

        // init Sablier stream for multisig funding
        IERC20(TORN).approve(SABLIER, VESTING_AMOUNT);
        uint256 streamId = ISablier(SABLIER).createStream(
            MULTISIG,
            VESTING_AMOUNT - (VESTING_AMOUNT % VESTING_PERIOD),
            TORN,
            block.timestamp + 3600, // 1 hour from now
            block.timestamp + VESTING_PERIOD + 3600 // VESTING_PERIOD and 1 hour from now
        );
        emit StreamCreated(streamId);
    }
}
