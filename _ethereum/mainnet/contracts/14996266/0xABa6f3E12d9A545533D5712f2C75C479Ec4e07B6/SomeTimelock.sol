// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./TimelockController.sol";

contract SomeTimelock is TimelockController {
    constructor(uint256 minDelay)
        TimelockController(
            minDelay,
            _getInitialProposerList(),
            _getInitialProposerList()
        )
    {}

    function _getInitialProposerList()
        private
        view
        returns (address[] memory addressList)
    {
        addressList = new address[](1);
        addressList[0] = msg.sender;
    }
}
