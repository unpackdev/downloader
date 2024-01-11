// contracts/ChurchEggs.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";

contract ChurchEggs is 
    Context,
    AccessControlEnumerable,
    ERC721Enumerable
 {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BLESSINGS_ROLE = keccak256("BLESSINGS_ROLE");

  string private _baseTokenURI;

  mapping(address => uint256) public userBlessings;
  uint256 public totalBlessings;

  /* Events */
  event BlessEggs(address user, uint256 amount);
  event EggBlessingsTransfered(address from, address to, uint256 amount);

  constructor(address minter) ERC721("ChurchEggs", "EGG") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Add default admin role
    _setupRole(MINTER_ROLE, minter);
    _baseTokenURI = 'https://church-dao.org/nfts/eggs/metadata/';
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._afterTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      uint256 balance = balanceOf(from);
      if (userBlessings[from] > 0) {
        uint256 delta = userBlessings[from] - (balance * userBlessings[from] / (balance + 1));
        userBlessings[from] -= delta;
        userBlessings[to] += delta;

        emit EggBlessingsTransfered(from, to, delta);
      }
    }
  }

  function blessEggs(address user, uint256 amount) external onlyRole(BLESSINGS_ROLE) {
    totalBlessings += amount * balanceOf(user);
    userBlessings[user] += amount * balanceOf(user);

    emit BlessEggs(msg.sender, amount);
  }

  function mintEgg(address to, uint256 tokenId) public virtual onlyRole(MINTER_ROLE) {
    _mint(to, tokenId);
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function setBaseURI(string calldata to) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _baseTokenURI = to;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(AccessControlEnumerable, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

}




