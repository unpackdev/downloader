// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

abstract contract MonsterBlockCoreERC721 is ERC721, ERC721Burnable, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ReentrancyGuard {
  string public baseURI;
  address internal withdrawContract;
  address internal giveWellAddress;
  address internal charityWalletAddress;

  function strConcat(string memory _a, string memory _b) internal pure returns(string memory) {
    return string(abi.encodePacked(bytes(_a), bytes(_b)));
  }

  function pauseSale() public onlyOwner {
    _pause();
  }

  function unpauseSale() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
  }

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function withdraw() public onlyOwner {
    // 10% to GiveWell Maximum Impact Fund
    Address.sendValue(payable(giveWellAddress), address(this).balance / 10);
    // 5% to Charity Wallet
    Address.sendValue(payable(charityWalletAddress), address(this).balance * 5 / 90);
    // Remainder to withdrawal contract
    Address.sendValue(payable(withdrawContract), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

  receive() external payable {}
}
