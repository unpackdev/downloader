// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "./AFTERLIF3.sol";

contract $AFTERLIF3 is AFTERLIF3 {
    constructor(string memory _name, string memory _symbol, string memory _initBaseURI) AFTERLIF3(_name, _symbol, _initBaseURI) {}

    function $_currentId() external view returns (uint256) {
        return _currentId;
    }

    function $merkleRootHash() external view returns (bytes32) {
        return merkleRootHash;
    }

    function $_mintQty(uint256 _mintAmount,address _receiver) external {
        return super._mintQty(_mintAmount,_receiver);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_validateTxn(bytes32[] calldata proof,address _user) external view returns (bool) {
        return super._validateTxn(proof,_user);
    }

    function $_merkleVerify(bytes32[] calldata proof,bytes32 hashedLeaf) external view returns (bool) {
        return super._merkleVerify(proof,hashedLeaf);
    }

    function $_hashLeaf(address _user) external pure returns (bytes32) {
        return super._hashLeaf(_user);
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_safeTransfer(address from,address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeTransfer(from,to,tokenId,_data);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function $_safeMint(address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeMint(to,tokenId,_data);
    }

    function $_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function $_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function $_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function $_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function $_afterTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._afterTokenTransfer(from,to,tokenId);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}
