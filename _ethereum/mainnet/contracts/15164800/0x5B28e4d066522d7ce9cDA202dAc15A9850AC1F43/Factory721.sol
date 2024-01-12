//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./OwnAPPOGNFT721.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new APPOGNFT721UserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        APPOGNFT721UserToken token = APPOGNFT721UserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}