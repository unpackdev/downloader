// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

abstract contract IERC721 {
    function mint(address to, uint quantity) external virtual;

    function ownerOf(uint tokenId) external view virtual returns (address);
}

contract MinterAirdrop is Ownable {
    IERC721 public hoodies;
    IERC721 public prophets;

    mapping(uint => bool) public claimed;

    constructor(IERC721 _hoodies, IERC721 _prophets) {
        hoodies = _hoodies;
        prophets = _prophets;
    }

    function setHoodies(IERC721 erc721_) public onlyOwner {
        hoodies = erc721_;
    }

    function setProphets(IERC721 erc721_) public onlyOwner {
        prophets = erc721_;
    }

    function mint(uint[] memory _tokenIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            address target = prophets.ownerOf(_tokenIds[i]);
            require(!claimed[_tokenIds[i]], "tokenId already minted");
            claimed[_tokenIds[i]] = true;
            hoodies.mint(target, 1);
        }
    }
}
