// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./SafeERC20.sol";

abstract contract IERC721 {
    function mint(address to, uint quantity) external virtual;

    function ownerOf(uint tokenId) external view virtual returns (address);

    function balanceOf(address holder) external view virtual returns (uint);
}

contract MinterParadigm is Ownable {
    using SafeERC20 for IERC20;
    IERC721 public erc721;
    IERC721 public paradigmNFT;

    mapping(uint => bool) public claimed;

    constructor(IERC721 _erc721, IERC721 _paradigmNFT) {
        erc721 = _erc721;
        paradigmNFT = _paradigmNFT;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setParadigm(IERC721 _newAddress) public onlyOwner {
        paradigmNFT = _newAddress;
    }

    function mint(uint[] memory _tokenIds) public {
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(paradigmNFT.ownerOf(_tokenIds[i]) == msg.sender, "not owner of tokenId");
            require(claimed[_tokenIds[i]] == false, "tokenId already claimed");
            claimed[_tokenIds[i]] = true;
        }
        erc721.mint(msg.sender, _tokenIds.length);
    }
}
