// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./UniERC20.sol";
import "./Ownable.sol";
import "./IWhitelistRegistry.sol";

/// @title Contract with simple whitelist
contract WhitelistRegistrySimple is IWhitelistRegistry, Ownable {
    using UniERC20 for IERC20;

    error ArraysLengthsDoNotMatch();
    error SameStatus();

    event StatusUpdate(address indexed addr, bool status);

    mapping(address => bool) public isWhitelisted;

    function batchSetStatus(address[] calldata addresses, bool[] calldata statuses) external onlyOwner {
        uint256 length = addresses.length;
        if (length != statuses.length) revert ArraysLengthsDoNotMatch();
        for (uint256 i = 0; i < length; ++i) {
            _setStatus(addresses[i], statuses[i]);
        }
    }

    function setStatus(address _address, bool _status) external onlyOwner {
        _setStatus(_address, _status);
    }

    function _setStatus(address _address, bool _status) private {
        if (isWhitelisted[_address] == _status) revert SameStatus();
        isWhitelisted[_address] = _status;
        emit StatusUpdate(_address, _status);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        token.uniTransfer(payable(msg.sender), amount);
    }
}
