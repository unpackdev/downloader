// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Factory.sol";

struct WhitelistedToken {
    TokenInfo tokenInfo;
    address contractAddress;
}

struct WhitelistSetting {
    address contractAddress;
    bool isWhitelisted;
}

interface IWhitelist {
    event WhitelistTokens(address caller, WhitelistSetting[] whitelistSettings);

    function whitelistTokens(WhitelistSetting[] memory whitelist) external;

    function isWhitelistedToken(address token) external view returns (bool);
}
