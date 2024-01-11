//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC777.sol";

interface IPToken is IERC777 {
    function redeem(uint256 amount, string calldata underlyingAssetRecipient) external returns (bool);
}
