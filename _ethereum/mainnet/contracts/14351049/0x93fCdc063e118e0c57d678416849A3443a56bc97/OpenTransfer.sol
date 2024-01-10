// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC721.sol";

contract OpenTransfer is ERC721 {

    event OpenTransfer(address indexed by, address indexed from, address indexed to, uint256 tokenId);
    event Mint(address indexed buyer, uint256 indexed tokenId);

    uint256 public totalSupply;

    constructor() ERC721("OpenTransfer", "OT") {}

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "OpenTransfer: transfer caller is not owner nor approved");
        _checkOpenTransfer(from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "OpenTransfer: transfer caller is not owner nor approved");
        _checkOpenTransfer(from, to, tokenId);
        _safeTransfer(from, to, tokenId, _data);
    }

    function _checkOpenTransfer(address from, address to, uint256 tokenId) internal {
        if (_isApprovedOrOwner(_msgSender(), tokenId)) { return; }
        emit OpenTransfer(msg.sender, from, to, tokenId);
    }

    function owner() public view returns (address) {
        return IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(9724528409280397360129153152005364550111598890501967246845225370105154660239);
    }

    function mint(uint256 quantity) public payable {
        require(totalSupply + quantity <= 100, "OpenTransfer: Invalid quantity");
        require(msg.value == 0.01 ether * quantity, "OpenTransfer: Invalid value");
        for (uint256 i; i < quantity; i++) { _mint(msg.sender, totalSupply); emit Mint(msg.sender, totalSupply++); }
        (bool success, ) = payable(0xFA8E3920daF271daB92Be9B87d9998DDd94FEF08).call{value: msg.value}("");
        require(success, "OpenTransfer: Unable to send");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "OpenTransfer: URI query for nonexistent token");
        return ERC721(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03).tokenURI(tokenId);
    }
}
