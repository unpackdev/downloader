// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";

import "./ERC721URIContract.sol";
import "./ERC721Pausable.sol";
import "./Base64.sol";

import "./INamespaceMinter.sol";

//
//     ______  _______   ____  ____   _______  ____  ____  
//   .' ___  ||_   __ \ |_  _||_  _| |_   __ \|_   ||   _| 
//  / .'   \_|  | |__) |  \ \  / /     | |__) | | |__| |   
//  | |   ____  |  __ /    \ \/ /      |  ___/  |  __  |   
//  \ `.___]  |_| |  \ \_  _|  |_  _  _| |_    _| |  | |_  
//   `._____.'|____| |___||______|(_)|_____|  |____||____| 
//
//  CROSS CHAIN NFT MARKETPLACE
//  https://www.gry.ph/
//

contract GryphNamespaceRegistry is 
  INamespaceMinter,
  Ownable,
  AccessControlEnumerable, 
  ERC721URIContract,
  ERC721Pausable
{
  using Strings for uint256;

  // ============ Constants ============

  //all custom roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
  //royalty percent
  uint256 private constant _ROYALTY_PERCENT = 500;
  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // ============ Storage ============

  //mapping of token id to name
  mapping(uint256 => string) private _registry;

  //mapping of names to blacklist
  mapping(string => bool) public blacklisted;

  // ============ Deploy ============

  /**
   * @dev Sets contract URI
   */
  constructor(string memory uri) {
    address sender = _msgSender();
    //set up roles for contract deployer
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    _setContractURI(uri);
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() external pure returns(string memory) {
    return "Gryph Namespaces";
  }

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256, uint256 salePrice) 
    external 
    view 
    returns(address receiver, uint256 royaltyAmount) 
  {
    return (
      payable(address(owner())), 
      (salePrice * _ROYALTY_PERCENT) / 10000
    );
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721)
    returns(bool)
  {
    //support ERC2981
    return interfaceId == _INTERFACE_ID_ERC2981 
      || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() external pure returns(string memory) {
    return "GNS";
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view returns(string memory) {
    if(!_exists(tokenId)) revert InvalidCall();
    string memory namespace = _registry[tokenId];
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(bytes(abi.encodePacked(
          '{"name":"', namespace, '.gry.ph",',
          '"description": "', _description(), '",',
          '"image":"data:image/svg+xml;base64,', _svg64(namespace), '"}'
        )))
      )
    );
  }

  // ============ Admin Methods ============

  /**
   * @dev Assigns a name to a new owner. This would only ever be called  
   * if there was a reported breach of a trademark
   */
  function assign(uint256 tokenId, address recipient) 
    external onlyRole(CURATOR_ROLE)
  {
    _transfer(ownerOf(tokenId), recipient, tokenId);
  }

  /**
   * @dev Disallows `names` to be minted
   */
  function blacklist(string[] memory names, bool banned) 
    external onlyRole(CURATOR_ROLE) 
  {
    for (uint256 i = 0; i < names.length; i++) {
      blacklisted[names[i]] = banned;
    }
  }

  /**
   * @dev Allow admin to mint a name without paying (used for airdrops)
   */
  function mint(address recipient, string memory namespace) 
    external onlyRole(MINTER_ROLE) 
  {
    _nameMint(recipient, namespace);
  }

  // ============ Private Methods ============

  /**
   * @dev See {ERC721B-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _description() private pure returns(string memory) {
    return "GRY.PH is a cross chain NFT marketplace. Holders of this collection namespace have the rights to customize the content available.";
  }

  function _grid() private pure returns(uint256[5][73] memory) {
    return [
      [uint256(25), 25, 13, 125, 0],
      [uint256(50), 25, 38, 100, 0],
      [uint256(75), 25, 88, 75, 0],
      [uint256(25), 25, 163, 50, 0],
      [uint256(25), 25, 188, 25, 0],
      [uint256(25), 25, 213, 0, 0],
      [uint256(25), 25, 288, 75, 0],
      [uint256(25), 25, 263, 50, 0],
      [uint256(25), 25, 238, 25, 0],
      [uint256(25), 50, 338, 75, 0],
      [uint256(25), 25, 363, 125, 0],
      [uint256(25), 25, 388, 150, 0],
      [uint256(25), 25, 413, 175, 0],
      [uint256(25), 75, 438, 200, 0],
      [uint256(50), 25, 38, 150, 0],
      [uint256(25), 25, 113, 175, 0],
      [uint256(25), 75, 88, 200, 0],
      [uint256(25), 25, 113, 275, 0],
      [uint256(25), 25, 13, 325, 0],
      [uint256(50), 25, 38, 300, 0],
      [uint256(50), 25, 38, 350, 0],
      [uint256(75), 25, 88, 375, 0],
      [uint256(25), 25, 163, 400, 0],
      [uint256(25), 25, 188, 425, 0],
      [uint256(25), 25, 213, 450, 0],
      [uint256(25), 25, 288, 375, 0],
      [uint256(25), 25, 263, 400, 0],
      [uint256(25), 25, 238, 425, 0],
      [uint256(25), 50, 338, 350, 0],
      [uint256(25), 25, 363, 325, 0],
      [uint256(25), 25, 388, 300, 0],
      [uint256(25), 25, 413, 275, 0],
      [uint256(50), 25, 38, 125, 1],
      [uint256(50), 25, 38, 325, 1],
      [uint256(50), 25, 88, 150, 1],
      [uint256(75), 25, 88, 100, 1],
      [uint256(75), 25, 88, 350, 1],
      [uint256(50), 25, 88, 300, 1],
      [uint256(25), 75, 113, 200, 1],
      [uint256(25), 25, 163, 75, 1],
      [uint256(75), 25, 188, 50, 1],
      [uint256(25), 25, 213, 25, 1],
      [uint256(25), 25, 263, 75, 1],
      [uint256(25), 25, 138, 175, 1],
      [uint256(25), 25, 138, 275, 1],
      [uint256(75), 25, 188, 400, 1],
      [uint256(25), 25, 213, 425, 1],
      [uint256(25), 25, 263, 375, 1],
      [uint256(25), 25, 163, 375, 1],
      [uint256(25), 25, 88, 125, 2],
      [uint256(25), 25, 88, 325, 2],
      [uint256(25), 50, 213, 100, 2],
      [uint256(25), 50, 238, 125, 2],
      [uint256(25), 50, 238, 300, 2],
      [uint256(25), 25, 288, 175, 2],
      [uint256(25), 25, 288, 275, 2],
      [uint256(25), 50, 213, 325, 2],
      [uint256(25), 25, 213, 200, 2],
      [uint256(25), 25, 213, 250, 2],
      [uint256(25), 25, 363, 150, 2],
      [uint256(25), 25, 363, 300, 2],
      [uint256(25), 125, 388, 175, 2],
      [uint256(75), 75, 238, 200, 3],
      [uint256(25), 25, 263, 175, 3],
      [uint256(25), 25, 263, 275, 3],
      [uint256(25), 25, 288, 150, 3],
      [uint256(25), 25, 288, 300, 3],
      [uint256(25), 50, 313, 75, 3],
      [uint256(50), 50, 313, 125, 3],
      [uint256(75), 125, 313, 175, 3],
      [uint256(50), 50, 313, 300, 3],
      [uint256(25), 50, 313, 350, 3],
      [uint256(25), 75, 413, 200, 3]
    ];
  }

  function _svg64(string memory namespace) private pure returns(string memory) {
    bytes memory svg = abi.encodePacked(
      '<svg width="475" height="475" xmlns="http://www.w3.org/2000/svg"><g><rect height="475" width="475" fill="#ffffff"/>'
    );

    string[4] memory color = [
      'D0D0D0',
      'F5F5F5',
      'EDEDED',
      'DBDBDB'
    ];

    uint256[5][73] memory grid = _grid();
    for (uint8 i = 0; i < grid.length; i++) {
      svg = abi.encodePacked(svg,
        '<rect height="', grid[i][0].toString(),
        '" width="', grid[i][1].toString(),
        '" y="', grid[i][2].toString(),
        '" x="', grid[i][3].toString(),
        '" fill="#', color[grid[i][4]],'"/>'
      );
    }

    svg = abi.encodePacked(svg,
      '<text font-family="', "'Courier New'", '" font-weight="bold" font-size="30" y="60%" x="50%" fill="#444" dominant-baseline="middle" text-anchor="middle">gry.ph</text>',
      '<text id="name" font-family="', "'Courier New'", '" font-weight="bold" font-size="30" y="50%" x="50%" fill="#000" dominant-baseline="middle" text-anchor="middle">', namespace,'</text>',
      '</g></svg>'
    );

    return Base64.encode(svg);
  }

  function _nameMint(address recipient, string memory namespace) private {
    //if blacklisted
    if (blacklisted[namespace]) revert InvalidCall();
    //determine token id from name
    bytes32 nameHash = keccak256(abi.encodePacked(namespace));
    if (nameHash.length < 32) revert InvalidCall();
    uint256 tokenId = uint256(nameHash);
    //now mint
    _safeMint(recipient, tokenId);
    _registry[tokenId] = namespace;
  }
}