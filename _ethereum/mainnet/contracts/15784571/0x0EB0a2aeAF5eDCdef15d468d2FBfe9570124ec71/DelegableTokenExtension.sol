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
import "./ERC4907Extension.sol";
import "./DelegableTokenConfiguration.sol";

abstract contract DelegableTokenExtension is
    ERC4907Extension,
    DelegableTokenConfiguration
{
    constructor(string memory name, string memory symbol)
        ERC4907Extension(name, symbol)
    {}

    function setUser(
        uint256 tokenId,
        address user,
        uint256 expires
    ) public virtual override {
        require(
            _allowChangeUserBeforeUserExpired ||
                this.userOf(tokenId) == address(0),
            "token not available"
        );

        super.setUser(tokenId, user, expires);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            _allowTransferBeforeUserExpired ||
                this.userOf(tokenId) == address(0),
            "token not available"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }
}
