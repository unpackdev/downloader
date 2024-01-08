// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./Ownable.sol";

contract ProtocolFeeVault is Ownable {
    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function call(address target, bytes calldata data) payable onlyOwner external {
        (bool success, bytes memory reason) = target.call{value: msg.value}(data);
        require(success, string(reason));
    }
}
