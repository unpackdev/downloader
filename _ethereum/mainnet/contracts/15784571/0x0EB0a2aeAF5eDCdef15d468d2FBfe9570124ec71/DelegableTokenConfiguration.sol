//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//   __        __    _        _   _
//   \ \      / /_ _| | _____| | | |_ __
//    \ \ /\ / / _` | |/ / _ \ | | | '_ \
//     \ V  V / (_| |   <  __/ |_| | |_) |
//      \_/\_/ \__,_|_|\_\___|\___/| .__/
//                                 |_|
//       WakeUp Labs 2022

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

abstract contract DelegableTokenConfiguration is Ownable {
    bool internal _allowTransferBeforeUserExpired;
    bool internal _allowChangeUserBeforeUserExpired;

    constructor(
        bool allowTransferBeforeUserExpired,
        bool allowChangeUserBeforeUserExpired
    ) {
        _allowTransferBeforeUserExpired = allowTransferBeforeUserExpired;
        _allowChangeUserBeforeUserExpired = allowChangeUserBeforeUserExpired;
    }

    function setAllowTransferBeforeUserExpired(bool value) external onlyOwner {
        _allowTransferBeforeUserExpired = value;
    }

    function setAllowChangeUserBeforeUserExpired(bool value)
        external
        onlyOwner
    {
        _allowChangeUserBeforeUserExpired = value;
    }

    function getAllowTransferBeforeUserExpired() external view returns (bool) {
        return _allowTransferBeforeUserExpired;
    }

    function getAllowChangeUserBeforeUserExpired()
        external
        view
        returns (bool)
    {
        return _allowChangeUserBeforeUserExpired;
    }
}
