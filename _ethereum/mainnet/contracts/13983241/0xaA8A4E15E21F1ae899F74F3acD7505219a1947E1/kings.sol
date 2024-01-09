// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.2;
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Kings is ERC721, ERC721URIStorage, Ownable {
    string private _baseURIPrefix = "ipfs://QmYWJ4sAzzfBeKJ5RWXaA4aq4pszK9dSgPwFQA5bPbzYZR/";
    bool private uriLocked;
    constructor() ERC721("YouTuber Kings", "KINGS") {
    _safeMint(msg.sender, 1);
    }
    function _baseURI() internal view override returns(string memory) {
        return _baseURIPrefix;
    }
    function changeBaseURI(string memory baseURIPrefix) public onlyOwner {
        require(!uriLocked, "Not happening.");
        _baseURIPrefix = baseURIPrefix;
    }
        function lockURI() public onlyOwner {
        uriLocked=true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns(bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns(string memory)
    {
        return super.tokenURI(tokenId);
    }
}