// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IOpenBloxL1.sol";

struct BatchBlox {
    uint256 tokenId;
    uint256 genes;
    uint16 generation;
    uint256 parent0Id;
    uint256 parent1Id;
    uint256 ancestorCode;
    address receiver;
}

contract AirdropS4 is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public nftAddress;

    constructor(address _nftAddress) {
        require(_nftAddress != address(0), "Airdrop: invalid nft address");

        nftAddress = _nftAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function batchMint(BatchBlox[] calldata bloxes) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Airdrop: not minter");

        for (uint8 i = 0; i < bloxes.length; ++i) {
            IOpenBloxL1(nftAddress).mintBlox(
                bloxes[i].tokenId,
                bloxes[i].genes,
                bloxes[i].generation,
                bloxes[i].parent0Id,
                bloxes[i].parent1Id,
                bloxes[i].ancestorCode,
                bloxes[i].receiver
            );
        }
    }

    function resetNftAddress(address _nftAddress) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Airdrop: not admin");
        require(_nftAddress != address(0), "Airdrop: invalid nft address");

        nftAddress = _nftAddress;
    }
}
