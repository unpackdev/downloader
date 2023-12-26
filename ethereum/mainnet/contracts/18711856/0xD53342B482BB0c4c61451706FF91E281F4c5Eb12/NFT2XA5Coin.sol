// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeERC20.sol";

contract NFT2XA5Coin is ERC721, ERC721Enumerable, IERC721Receiver, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    event Received(address, uint);
    Counters.Counter private _tokenIdCounter;

    address payable receivingAddress = payable(address(0xa16965fEd0af325694cD85610EB0bFD28383Ab2b));
    constructor() ERC721("NFT2XA5", "NFT2XA5") { }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    
    // Contract Receives NFT
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public override returns(bytes4) {
        return this.onERC721Received.selector;
    }

    // Transfer Out ETH Tokens
    function withdraw(uint256 _amount) external onlyOwner {
        require(receivingAddress != address(0), "Invalid address");
        require(address(this).balance >= _amount, "Not enough funds");
        receivingAddress.transfer(_amount);
    }

    // Receive ERC20 Tokens.
    function depositERC20(IERC20 _token, uint256 amount) external {
        _token.transferFrom(msg.sender, address(this), amount);
    }

    // Handling of standard, non-standard ERC-20 tokens
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        require(receivingAddress != address(0), "Invalid address");
        _token.safeTransfer(receivingAddress, _amount);
    }

    // Transfer NFT
    function withdrawNFT(uint256 tokenId, address to) external onlyOwner {
         require(_exists(tokenId), "NFT does not exist");
         _safeTransfer(address(this), to, tokenId, "");
    }
    
    // Transfer Authorized NFT
    function transferNFT(uint256 tokenId, address from, address to) public onlyOwner {
    // Assume this contract has been approved to control the NFT with the given tokenId
     _safeTransfer(from, to, tokenId, '');
   }

    function safeMint(address to, string memory uri, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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
    override(ERC721, ERC721Enumerable, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
