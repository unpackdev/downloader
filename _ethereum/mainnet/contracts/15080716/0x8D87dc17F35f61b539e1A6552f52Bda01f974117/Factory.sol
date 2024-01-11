//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./WeaponDepotNFTUserToken.sol";

contract Factory {
    event Deployed(address owner, address contractAddress);

    function deploy(
        bytes32 _salt,
        string memory name,
        string memory symbol,
        string memory tokenURIPrefix
    ) external returns (address addr) {
        addr = address(
            new WeaponDepotNFTUserToken{salt: _salt}(name, symbol, tokenURIPrefix)
        );
        WeaponDepotNFTUserToken token = WeaponDepotNFTUserToken(address(addr));
        token.transferOwnership(msg.sender);
        emit Deployed(msg.sender, addr);
    }
}
