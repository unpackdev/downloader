// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC2981.sol";

/*
 * Art by skymagic.eth
*/
contract SkyMagic is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    address private _royaltiesReceiver;
    uint256 private _royaltiesPercentage;
    string private _baseTokenURI;
    
    constructor(address initRoyaltiesReceiver, uint256 initRoyaltiesPercentage, string memory initBaseURI) ERC721("Sky Magic", "SKY") {
        _royaltiesReceiver = initRoyaltiesReceiver;
        _royaltiesPercentage = initRoyaltiesPercentage;
        _baseTokenURI = initBaseURI;
    }

    function safeMint(address to, uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }
    
    function royaltiesPercentage() external view returns(uint256) {
        return _royaltiesPercentage;
    }

    function setRoyaltiesPercentage(uint256 newRoyaltiesPercentage)
    external onlyOwner {
        require(newRoyaltiesPercentage != _royaltiesPercentage); 
        _royaltiesPercentage = newRoyaltiesPercentage;
    }
    
    function royaltyInfo(uint256, uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * _royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function withdrawERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function withdraw721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}
