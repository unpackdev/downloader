// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Sig.sol";

interface IToken {
    function supplyLimit(uint256 id) external returns (uint256);

    function totalSupply(uint256 id) external returns (uint256);

    function mintFT(address to, uint256 tokenID, uint256 quantity) external;

    function mintNFT(address to, uint256 tokenID) external;

    function batchMintNFT(address to, uint256[] calldata ids) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract CBSProxy is Ownable {
    address public token;
    mapping(address => bool) public authorized;

    function setAuthorized(address addr, bool allowed) public onlyOwner {
        authorized[addr] = allowed;
    }

    function setTokenAddress(address addr) public onlyOwner {
        token = addr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(authorized[_msgSender()], "Not authorized.");

        _transferOrMint(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        require(authorized[_msgSender()], "Not authorized.");
        require(ids.length == amounts.length, "Array mismatch.");

        for (uint i = 0; i < ids.length; i++) {
            _transferOrMint(from, to, ids[i], amounts[i], data);
        }
    }

    function _transferOrMint(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        // If the supply limit of the token ID is 1, we know it's an NFT, meaning it could be transferred or minted.
        if (IToken(token).supplyLimit(id) == 1) {
            _transferOrMintNFT(from, to, id, data);
            return;
        }

        // If the supply limit is NOT 1, it's a FT. FTs don't exist on chain when they are custodially held, so we
        // always mint.
        IToken(token).mintFT(to, id, amount);
    }

    function _transferOrMintNFT(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) internal {
        if (IToken(token).totalSupply(id) == 1) {
            IToken(token).safeTransferFrom(from, to, id, 1, data);
            return;
        }

        IToken(token).mintNFT(to, id);
    }
}
