// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./IProxyMint.sol";
import "./IMoonSkulls.sol";

contract ApepSkulls is ERC721A,ERC721AQueryable, IMoonSkulls, Ownable {

    string public baseURI;

    address public proxyMintAddress;

    IProxyMint private proxyMint;

    constructor(string memory initBaseURI, address _proxyMintAddress) ERC721A("ApepSkulls NFT", "ASkulls") {
        baseURI = initBaseURI;
        proxyMintAddress = _proxyMintAddress;
        proxyMint = IProxyMint(proxyMintAddress);
    }

    function setProxyMintAddress(address _proxyMintAddress) public onlyOwner{
        proxyMintAddress = _proxyMintAddress;
        proxyMint = IProxyMint(proxyMintAddress);
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setURI(string memory newBaseURI) external virtual onlyOwner{
        baseURI = newBaseURI;
    }

    function mint(address minter,uint256 quantity) external override(IMoonSkulls) {
        require(proxyMintAddress == msg.sender, "Ownable: caller is not the owner");
        _safeMint(minter, quantity);
    }

    function numberMinted(address minter) external override(IMoonSkulls) view returns (uint256){
        return _numberMinted(minter);
    }

    function nextTokenId() external override(IMoonSkulls) view returns (uint256) {
        return _nextTokenId();
    }

    function mTotalSupply() external override(IMoonSkulls) view returns (uint256) {
        return totalSupply();
    }

    function mOwnerOf(uint256 tokenId) external override(IMoonSkulls) view returns (address) {
        return ownerOf(tokenId);
    }

    function mTokensOfOwner(address owner) external override(IMoonSkulls) view returns (uint256[] memory) {
        return tokensOfOwner(owner);
    }

    function _beforeTokenTransfers(address,address,uint256 startTokenId,uint256) internal view override {
        require(!proxyMint.isStake(startTokenId), "Cannot transfer stake tokens");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(!proxyMint.hasStake(msg.sender), "Cannot approve staked address");
        super.setApprovalForAll(operator, approved);
    }

    // function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //     proxyMint.mTransferFrom(from,to);
    //     safeTransferFrom(from,to,tokenId);
    // }
    //如果需要向合约里转币或NFT 需要实现此onERC721Received函数，防止别人转错到合约里。
    // function onERC721Received( address, address, uint256, bytes calldata) external override pure returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }

    function burn (uint256[] calldata tokenIds) external onlyOwner{
        for (uint256 i=0; i<tokenIds.length; i++) {
            _burn(tokenIds[i] , true);
        }
    }
}