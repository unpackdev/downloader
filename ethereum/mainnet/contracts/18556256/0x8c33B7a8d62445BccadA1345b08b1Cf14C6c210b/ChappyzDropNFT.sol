// SPDX-License-Identifier: Proprietary

pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

import "./Claimable.sol";

contract ChappyzDropNFT is 
  ERC721A,
  ERC2981,
  AccessControl,
  Ownable,
  Claimable
{

  string private baseUri;

  string private contractUri;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _contractUri,
    string memory _baseUri,
    address _feeAddress,
    uint96 _feeNumerator
  )
    ERC721A(_name, _symbol) 
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setDefaultRoyalty(_feeAddress, _feeNumerator);

    contractUri = _contractUri;
    baseUri = _baseUri;
  }

  /* ------------ Public Operations ------------ */
  function contractURI()
    public
    view
    returns (string memory)
  {
    return contractUri;
  }

  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(AccessControl, ERC721A, ERC2981)
    returns (bool) 
  {
    return
      AccessControl.supportsInterface(interfaceId)
        || ERC2981.supportsInterface(interfaceId)
        || ERC721A.supportsInterface(interfaceId);
  }

  /* ------------ Management Operations ------------ */
  function setContractURI(
    string calldata _contractUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    contractUri = _contractUri;
  }

  function setBaseURI(
    string calldata _baseUri
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _baseUri;
  }

  function setDefaultRoyalty(
    address _receiver,
    uint96 _feeNumerator
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function deleteDefaultRoyalty()
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _deleteDefaultRoyalty();
  }

  /**
  * @dev Withdraws the erc20 tokens or native coins from this contract.
  */
  function claimValues(address _token, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimValues(_token, _to);
  }

  /**
    * @dev Withdraw ERC721 or ERC1155 deposited for this contract
    * @param _token address of the claimed ERC721 token.
    * @param _to address of the tokens receiver.
    */
  function claimNFTs(address _token, uint256 _tokenId, address _to)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _claimNFTs(_token, _tokenId, _to);
  }

  function mint(
    address[] calldata _to,
    uint256 _quantity
  )
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    for(uint256 i = 0; i < _to.length; i++) {
      _safeMint(_to[i], _quantity);
    }
  }

  /* ------------ Internal Operations/Modifiers ------------ */
  function _startTokenId()
    internal
    pure
    override
    returns (uint256)
  {
    return 1;
  }

  function _baseURI() 
    internal 
    view 
    override 
    returns (string memory)
  {
    return baseUri;
  }

}