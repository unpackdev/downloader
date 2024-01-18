// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Ownable.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
    error ReadOnlyNFT();
    error NotOwnerOfToken();
    error URIQueryForNonexistentToken();
interface IOnChainBirds {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

contract TokenBoundOCB is IERC721Metadata, Ownable {
    

    IOnChainBirds public onChainBirds = IOnChainBirds(0xBE82b9533Ddf0ACaDdcAa6aF38830ff4B919482C);
    string public baseURI = 'https://raw.githubusercontent.com/OnChainBirds/tbmetadata/main/';
    
    constructor() {
        emit Transfer(address(0), onChainBirds.ownerOf(0), 0);
    }

    function name() external pure returns (string memory) {
        return 'OCB Tokenbound';
    }

    function symbol() external pure returns (string memory) {
        return 'OCBT';
    }

    function claim(uint256 tokenId) external {
        emit Transfer(address(0), onChainBirds.ownerOf(tokenId), tokenId);
    }

    function batchClaim(uint256[] calldata tokenIds) external {
        unchecked {
            for(uint256 i; i<tokenIds.length;++i) {
                emit Transfer(address(0), onChainBirds.ownerOf(tokenIds[i]), tokenIds[i]);
            }
        }
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (tokenId>=10000) revert URIQueryForNonexistentToken();
        return string.concat(baseURI, Strings.toString(tokenId));
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return onChainBirds.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return onChainBirds.ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function safeTransferFrom(address,address,uint256) external pure {
        revert ReadOnlyNFT();
    }

    function safeTransferFrom(address,address,uint256,bytes calldata) external pure {
        revert ReadOnlyNFT();
    }

    function transferFrom(address,address,uint256) external pure {
        revert ReadOnlyNFT();
    }

    function approve(address, uint256) external pure {
        revert ReadOnlyNFT();
    }

    function getApproved(uint256) external pure returns (address operator) {
        return address(0);
    }

    function setApprovalForAll(address, bool) external pure {
        revert ReadOnlyNFT();
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

}
