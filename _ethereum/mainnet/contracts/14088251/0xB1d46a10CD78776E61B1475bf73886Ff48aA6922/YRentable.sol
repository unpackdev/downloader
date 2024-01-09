// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "ERC721.sol";
import "IERC721.sol";
import "Counters.sol";
import "Ownable.sol";

contract YRentable is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIds;

    address internal _minter;

    constructor() ERC721("YRentable", "YRENTABLE") {}

    modifier onlyMinter() {
        require(_msgSender() == _minter, "Only minter");
        _;
    }

    function setMinter(address minter_) external onlyOwner {
        _minter = minter_;
    }

    function getMinter() external view returns (address) {
        return _minter;
    }

    function mint(address to) external onlyMinter returns (uint256) {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);

        return newTokenId;
    }
}
