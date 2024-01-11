//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./CrossTowerStorefrontUserToken1155.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix,
        address operator
    ) external returns (address addr) {
        addr = address(
            new CrossTowerStorefrontUserToken1155{salt: _salt}(
                name,
                symbol,
                tokenURIPrefix,
                operator
            )
        );
        CrossTowerStorefrontUserToken1155 token = CrossTowerStorefrontUserToken1155(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}