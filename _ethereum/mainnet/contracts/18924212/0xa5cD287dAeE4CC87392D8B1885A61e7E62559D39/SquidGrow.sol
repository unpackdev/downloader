// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ****************/
//
// 88 88
// 88 88
// 88 88
// 88 88,dPPYba,
// 88 88P'    "8a
// 88 88       d8
// 88 88b,   ,a8"
// 8Y 8Y"Ybbd8"'
//
// ****************/

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SquidGrow is ERC721, ERC721Enumerable, Ownable {
    string private baseTokenURI;
    uint256 private _nextTokenId = 0;
    uint private constant maxSupply = 426;

    constructor()
        ERC721("Squidgrow The Challenge", "SQUIDGROW")
        Ownable(msg.sender)
    {
        baseTokenURI = "ipfs://QmY87jVPWtRLdmh6QW8EwDetLmbUrDWGdotyvy91BtzG68/";
    }

    function setBaseUri(string calldata newBase) external onlyOwner {
        baseTokenURI = newBase;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function mintReserve(address[] calldata to) public onlyOwner {
        require(
            maxSupply >= to.length + _nextTokenId,
            "Qty Not Available For Mint"
        );
        for (uint i = 0; i < to.length; ) {
            safeMint(to[i]);

            unchecked {
                i++;
            }
        }
    }

    function safeMint(address to) internal {
        _nextTokenId = _nextTokenId + 1;
        _safeMint(to, _nextTokenId);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ICE
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);

        tokenContract.transfer(msg.sender, _amount);
    }

    // ICE
    function withdrawAll(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(to, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
