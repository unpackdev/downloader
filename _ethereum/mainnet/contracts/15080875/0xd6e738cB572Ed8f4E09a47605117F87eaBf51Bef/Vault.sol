//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error ArraysDontMatch();
import "./Ownable.sol";
import "./IERC721Receiver.sol";


contract CelestialsVault is  Ownable {
    ERC721Like public celestials;


    function setCelestials(address celestialsAddress) external onlyOwner {
        celestials = ERC721Like(celestialsAddress);
    }
    function airdrop(address[] calldata accounts, uint[] calldata tokenIds) external onlyOwner{
        if(accounts.length  != tokenIds.length) revert ArraysDontMatch();
        for(uint i; i <accounts.length; i++){
            celestials.transferFrom(address(this), accounts[i], tokenIds[i]);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external  returns (bytes4) {
        return ERC721Like.onERC721Received.selector;
    }
}


interface ERC721Like {
    // function balanceOf(address holder_) external view returns (uint256);

    // function ownerOf(uint256 id_) external view returns (address);

    // function walletOfOwner(address _owner) external view returns (uint256[] calldata);

    // function tokensOfOwner(address owner) external view returns (uint256[] memory);

    // function isApprovedForAll(address operator_, address address_) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}