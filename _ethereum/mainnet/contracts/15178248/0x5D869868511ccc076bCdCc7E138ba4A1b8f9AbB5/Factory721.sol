//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "./OwnNFTPASTEL721.sol";

contract Factory721 {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new NFTPASTEL721UserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        NFTPASTEL721UserToken token = NFTPASTEL721UserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}
