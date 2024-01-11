// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

contract YmirERC721 is ERC721, ERC721URIStorage, AccessControlEnumerable {
  using Counters for Counters.Counter;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  Counters.Counter public tokenIdCounter;
  
  event Received(address contractAddress, address sender, uint256 amount);

  event Withdraw(address sender, uint256 amount);

  constructor(
    string memory _name,
    string memory _symbol,
    address _creator
  ) ERC721(_name, _symbol) {
    _grantRole(DEFAULT_ADMIN_ROLE, _creator);
    _grantRole(MINTER_ROLE, _creator);
  }

  function safeMint(address to, string memory uri)
    public
    onlyRole(MINTER_ROLE)
  {
    uint256 tokenId = tokenIdCounter.current();
    tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  // The following functions are overrides required by Solidity.

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
    override(ERC721, AccessControlEnumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether to withdraw");
    payable(msg.sender).transfer(balance);
    emit Withdraw(address(this), balance);
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  receive() external payable {
    emit Received(address(this), msg.sender, msg.value);
  }

  fallback() external payable {}
}
