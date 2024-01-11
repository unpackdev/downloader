// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract DoasisGenesisPass is ERC721A, Ownable, AccessControl, ReentrancyGuard {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() ERC721A("D.OASIS Genesis Pass", "DOASIS") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(address to, uint256 quantity)
    external
    payable
    onlyRole(MINTER_ROLE)
  {
    _safeMint(to, quantity);
  }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _baseTokenURI = baseURI;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return _ownershipOf(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721A)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}
