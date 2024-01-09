// SPDX-License-Identifier: MIT
// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity ^0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

contract CapsuleHouseElixir is ERC1155, Ownable {
    using Strings for uint256;
    
    address private portraitContractAddress;
    string private baseURI;
    string private _tokenBaseURI;

    uint256 public totalSwappableBackgroundElixirs;
    uint256 public totalAnimationElixirs;

    uint256 public maxSwappableBackgroundElixirs;
    uint256 public maxAnimationElixirs;

    constructor(string memory _baseURI, uint256 _maxSwappableBackgroundElixirs, uint256 _maxAnimationElixirs) ERC1155(_baseURI) {
        baseURI = _baseURI;
        maxSwappableBackgroundElixirs = _maxSwappableBackgroundElixirs;
        maxAnimationElixirs = _maxAnimationElixirs;
    }

    function setPortraitContractAddress(address _portraitContractAddress)
        external
        onlyOwner
    {
        portraitContractAddress = _portraitContractAddress;
    }

    function burn(uint256 typeId, address burnTokenAddress) external 
    {
        require(msg.sender == portraitContractAddress, "Invalid burner address.");
        _burn(burnTokenAddress, typeId, 1);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mintSwappableBackgroundElixirs(uint256 numElixirs) external onlyOwner {
        require(totalSwappableBackgroundElixirs + numElixirs <= maxSwappableBackgroundElixirs, "Cannot mint more.");

        totalSwappableBackgroundElixirs += numElixirs;
        _mint(owner(), 1, numElixirs, "");
    }

    function mintAnimationElixirs(uint256 numElixirs) external onlyOwner {
        require(totalAnimationElixirs + numElixirs <= maxAnimationElixirs, "Cannot mint more.");

        totalAnimationElixirs += numElixirs;
        _mint(owner(), 2, numElixirs, "");
    }

    function tokenURI(uint256 typeId)
        public
        view
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}