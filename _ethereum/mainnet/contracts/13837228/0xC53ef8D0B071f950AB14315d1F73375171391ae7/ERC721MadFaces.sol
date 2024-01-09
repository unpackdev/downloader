// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ECDSA.sol";

/*
                                        Authors: madjin.eth
                                            year: 2021

                ███╗░░░███╗░█████╗░██████╗░███████╗░█████╗░░█████╗░███████╗░██████╗
                ████╗░████║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
                ██╔████╔██║███████║██║░░██║█████╗░░███████║██║░░╚═╝█████╗░░╚█████╗░
                ██║╚██╔╝██║██╔══██║██║░░██║██╔══╝░░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗
                ██║░╚═╝░██║██║░░██║██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝
                ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

*/


abstract contract ERC721MadFaces is ERC721Enumerable, Ownable, ReentrancyGuard {

    using ECDSA for bytes32;

    string private _currentBaseURI;

    bool public locked = false;
    uint256 public constant MAX_SUPPLY = 3333;

    address private _signer;
    mapping(string => bool) private _usedNonces;

    string private _contractURI;

    modifier not_locked(){
        require(!locked, 'Contract has been lock forever, action not permitted');
        _;
    }

    modifier validHash(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity){

        require(!_usedNonces[nonce], "Hash is already used");
        require(_checkSigner(hash, signature), "Wrong Signer");
        require(_hashTransaction(_msgSender(), tokenQuantity, nonce) == hash, "Hash mismatched");
        _;
        _usedNonces[nonce] = true;
    }

    function _hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce)))
        );
    }

    function _checkSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
        return _signer == hash.recover(signature);
    }

    function setSignerAddress(address signerAddress) external onlyOwner {
        _signer = signerAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner not_locked {
        _currentBaseURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    //!\ Irreversible, lock contract forever /!\
    function setLocked() external onlyOwner {
        locked = true;
    }
}