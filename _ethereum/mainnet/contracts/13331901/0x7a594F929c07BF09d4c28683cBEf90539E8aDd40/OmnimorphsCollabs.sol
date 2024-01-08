// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OmnimorphsCollabs is ERC1155, Ownable {
    using ECDSA for bytes32;

    string public message = "The Omnimorphs are here.";

    mapping(uint => string) private _tokenURIs;

    mapping(uint => uint) private _supply;

    mapping(uint => uint) private _maxSupply;

    mapping(uint => bytes[]) private _signatures;

    constructor(string memory initialURI) ERC1155(initialURI) {}

    // ONLY OWNER

    function setSignatures(uint id, bytes[] memory signatures) external onlyOwner {
        _signatures[id] = signatures;
    }

    function setMaxSupply(uint id, uint newMaxSupply) external onlyOwner {
        require(_maxSupply[id] == 0, "Cannot reset max supply once it was set");

        _maxSupply[id] = newMaxSupply;
    }

    function setURI(uint id, string memory newURI) external onlyOwner {
        _setURI(id, newURI);
    }

    function mint(address to, uint id, uint amount) external onlyOwner {
        require(_supply[id] + amount <= _maxSupply[id], "Max supply exceeded");

        _mintTokens(to, id, amount);
    }

    function mintForList(address[] calldata addresses, uint id, uint amount) external onlyOwner {
        require(_supply[id] + (addresses.length * amount) <= _maxSupply[id], "Max supply exceeded");

        for (uint i = 0; i < addresses.length; i++) {
            _mintTokens(addresses[i], id, amount);
        }
    }

    // INTERNAL

    function _setURI(uint id, string memory newURI) private {
        _tokenURIs[id] = newURI;
    }

    function _mintTokens(address to, uint id, uint amount) private {
        _supply[id] += amount;
        _mint(to, id, amount, "0x");
    }

    // PUBLIC

    function uri(uint id) public view override returns(string memory) {
        return _tokenURIs[id];
    }

    function getMaxSupply(uint id) public view returns(uint) {
        return _maxSupply[id];
    }

    function getSupply(uint id) public view returns(uint) {
        return _supply[id];
    }

    function getSignerByIndex(uint id, uint index) public view returns(address) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(address(this), id, message))
            )
        ).recover(_signatures[id][index]);
    }

    function getNumberOfSigners(uint id) public view returns(uint) {
        return _signatures[id].length;
    }
}
