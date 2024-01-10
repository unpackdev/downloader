//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChainScoutsExtension.sol";
import "./IUtilityERC20.sol";

contract Leveller is ChainScoutsExtension {
    IUtilityERC20 public token;
    uint[] public costs;

    constructor(IUtilityERC20 _token) {
        token = _token;
        costs = [5, 10, 25, 50, 100];
        enabled = false;
    }

    function extensionKey() public override pure returns (string memory) {
        return "leveller";
    }

    function adminSetCosts(uint[] calldata _costs) external onlyAdmin {
        costs = _costs;
    }

    function levelUp(uint tokenId) external canAccessToken(tokenId) whenEnabled {
        ChainScoutMetadata memory md = chainScouts.getChainScoutMetadata(tokenId);
        for (uint i = 0; i < costs.length; ++i) {
            if (md.level == i + 1) {
                token.burn(msg.sender, costs[i] * 1 ether);
                md.level++;
                chainScouts.adminSetChainScoutMetadata(tokenId, md);
                return;
            }
        }
        revert("This token is already max level");
    }
}