// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "ERC721ReadOnlyProxy.sol";

interface IORentableHooks {
    function afterOTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external ;
}

contract ORentable is ERC721ReadOnlyProxy {
    address internal _rentable;

    string constant PREFIX = "o";

    constructor(address wrapped_) ERC721ReadOnlyProxy(wrapped_, PREFIX) {}

    function init(address wrapped, address owner) external virtual {
        _init(wrapped, PREFIX, owner);
    }

    function setRentable(address rentable_) external onlyOwner {
        _rentable = rentable_;
        _minter = rentable_;
    }

    function getRentable() external view returns (address) {
        return _rentable;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);
        IORentableHooks(_rentable).afterOTokenTransfer(_wrapped, from, to, tokenId);
    }
}
