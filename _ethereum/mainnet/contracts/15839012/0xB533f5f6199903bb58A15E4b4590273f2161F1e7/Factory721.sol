//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./BluebitUser721Token.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix,
        address operator
    ) external returns (address addr) {
        addr = address(
            new BlueBitUser721Token{salt: _salt}(name, symbol, tokenURIPrefix, operator)
        );
        BlueBitUser721Token token = BlueBitUser721Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}