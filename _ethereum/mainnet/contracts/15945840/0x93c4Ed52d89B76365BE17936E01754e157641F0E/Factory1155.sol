// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;


import "./crpcnm01User1155Token.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new crpcnm01User1155Token{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        crpcnm01User1155Token token = crpcnm01User1155Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}