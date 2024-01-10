
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./ProxyERC20.sol";
import "./IElysian.sol";

contract ProxyERC20Mintable is ProxyERC20 {
    
    constructor(address _owner) public ProxyERC20(_owner) {}

    function mint(uint amount, address dst, bool isEscrowed) external returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IElysian(address(target)).mint(amount, dst, isEscrowed);

        // Event emitting will occur via Proxy._emit()
        return true;
    }

}