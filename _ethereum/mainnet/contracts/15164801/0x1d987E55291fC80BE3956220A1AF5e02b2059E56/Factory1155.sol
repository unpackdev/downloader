//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./OwnAPPOGNFT1155.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new APPOGNFT1155UserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        APPOGNFT1155UserToken token = APPOGNFT1155UserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}