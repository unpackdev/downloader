// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
                              ..............               ascii art by community member
                        ..::....          ....::..                           rqueue#4071
                    ..::..                        ::..
                  ::..                              ..--..
                ::..                  ....::..............::::..
              ::                ..::::..                      ..::..
            ....            ::::..                                ::::
            ..        ..::..                                        ..::
          ::      ..::..                                              ....
        ....  ..::::                                                    ::
        ::  ..  ..                                                        ::
        ....    ::                                ....::::::::::..        ::
        --::......                    ..::==--::::....          ..::..    ....
      ::::  ..                  ..--..  ==@@++                      ::      ..
      ::                    ..------      ++..                        ..    ..
    ::                  ..::--------::  ::..    ::------..            ::::==++--..
  ....                ::----------------    ..**%%##****##==        --######++**##==
  ..              ::----------------..    ..####++..    --**++    ::####++::    --##==
....          ..----------------..        **##**          --##--::**##++..        --##::
..        ..--------------++==----------**####--          ..**++..::##++----::::::::****
..    ::==------------++##############%%######..            ++**    **++++++------==**##
::  ::------------++**::..............::**####..            ++**..::##..          ..++##
::....::--------++##..                  ::####::          ::****++####..          ..**++
..::  ::--==--==%%--                      **##++        ..--##++::####==          --##--
  ::..::----  ::==                        --####--..    ::**##..  ==%%##::      ::****
  ::      ::                                **####++--==####::      **%%##==--==####::
    ::    ..::..                    ....::::..--########++..          ==**######++..
      ::      ..::::::::::::::::::....      ..::::....                    ....
        ::::..                      ....::....
            ..::::::::::::::::::::....

 */

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./IERC2981.sol";

contract InvisibleFriendsSpecials is ERC1155, AccessControl {
  string public constant name = "Invisible Friends Specials";
  string public constant symbol = "INVSBLESPECIAL";

  address public royalties;

  bytes32 public constant MINTER = keccak256("MINTER");

  mapping(uint256 => string) private _uris;
  string private _contractURI;

  constructor(address _royalties) ERC1155("") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER, _msgSender());

    royalties = _royalties;
  }

  // Minting

  function mint(uint256 _id, uint256 _amount, string memory _uri, address _destination) public onlyRole(MINTER) {
    setUri(_id, _uri);
    _mint(_destination, _id, _amount, "");
  }

  function setUri(uint256 _id, string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _uris[_id] = _uri;
  }

  function uri(uint256 _id) public view virtual override returns (string memory) {
    return _uris[_id];
  }

  // Metadata

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _contractURI = _uri;
  }

  // IERC2981

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; // silence solc warning
    royaltyAmount = (_salePrice / 100) * 5;
    return (royalties, royaltyAmount);
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId
      || interfaceId == type(AccessControl).interfaceId
      || super.supportsInterface(interfaceId);
  }
}

