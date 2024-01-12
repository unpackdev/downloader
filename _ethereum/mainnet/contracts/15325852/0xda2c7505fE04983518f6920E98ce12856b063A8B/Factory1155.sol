// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./HootenaniUser1155Token.sol";

contract Factory1155 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new HootenaniUser1155Token{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        HootenaniUser1155Token token = HootenaniUser1155Token(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}
