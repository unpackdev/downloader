// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./BeaNFTURIStorage.sol";
import "./IERC721.sol";

/**
 * @dev BeaNFT's ERC721 Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard based on OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol) with subcollections.
 */

abstract contract BeaNFTInternal is BeaNFTURIStorage {

    mapping(address => mapping(uint8 => uint32)) private _balances;
    mapping(uint256 => address) private _owners;

    address internal genesisAddress;
    address internal signer;

    function subcollections() pure public returns (uint256[2] memory) {
        return [uint256(2048),4048];
    }

    function subcollection(uint256 id) public pure returns (uint8) {
        for (uint8 i = 0; i < subcollections().length; i++) {
            if (id < subcollections()[i]) return i;
        }
        require(false, "BeaNFT: No subcollection for Id");
        return 0;
    }

    function balanceOf(address owner) public view virtual override returns (uint256 balance) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        uint numSubcollections = subcollections().length;
        for (uint8 i = 0; i < numSubcollections; i++) {
            balance = balance + _balances[owner][i];
        }
    }

    function balanceOfSubcollection(address owner, uint8 id) public view virtual returns (uint256) {
        require(owner != address(0), "BeaNFT: balance query for the zero address");
        require(id < subcollections().length, "BeaNFT: subcollection does not exist");

        // Until we mint Genesis NFTs on new contract, get balance from Genesis contract
        if (id == 0) return IERC721(genesisAddress).balanceOf(owner);
        return _balances[owner][id];
    }

    function balanceOfVotes(address owner) public view virtual returns (uint256 votes) {
        require(owner != address(0), "BeaNFT: balance query for the zero address");
        uint genesis = balanceOfSubcollection(owner, 0);
        if (genesis > 4) genesis = 4;

        if (genesis == 4) votes += 14;
        else if (genesis == 3) votes += 12;
        else if (genesis == 2) votes += 9;
        else if (genesis == 1) votes += 5;
        uint balance = balanceOf(owner);
        if (balance > 5) balance = 5;
        votes += balance - genesis;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to][subcollection(tokenId)] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        _balances[owner][subcollection(tokenId)] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        
        uint8 sId = subcollection(tokenId);
        _balances[from][sId] -= 1;
        _balances[to][sId] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _batchMintToAccount(address to, uint256[] calldata tokenIds) internal {
        _beforeTokenTransfer(address(0), to, tokenIds[0]);
        require(to != address(0), "ERC721: mint to the zero address");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            __MintInBatch(to, tokenIds[i]);
        }
        _balances[to][subcollection(tokenIds[0])] += uint32(tokenIds.length);

    } 
    function __MintInBatch(address to, uint256 tokenId) internal virtual {
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
}
