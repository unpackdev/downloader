// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./UniERC20.sol";
import "./Ownable.sol";
import "./IWhitelistRegistry.sol";

contract WhitelistRegistrySimple is IWhitelistRegistry, Ownable {
    using UniERC20 for IERC20;

    error SameStatus();

    event StatusUpdate(address indexed addr, uint256 status);

    mapping(address => uint256) public status;

    function setStatus(address addr, uint256 _status) external onlyOwner {
        if (status[addr] == _status) revert SameStatus();
        status[addr] = _status;
        emit StatusUpdate(addr, _status);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.uniTransfer(payable(msg.sender), amount);
    }
}
