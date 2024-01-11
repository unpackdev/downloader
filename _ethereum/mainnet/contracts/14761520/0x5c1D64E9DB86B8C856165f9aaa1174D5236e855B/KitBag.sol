// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./Strings.sol";
import "./IERC2981Royalties.sol";

contract KitBag is
  Initializable,
  ERC1155Upgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  IERC2981Royalties
{

  using Strings for uint256;

  string private baseURI;
  string private suffix;
  mapping(address => bool) public controllers;
  uint24 private _royalties;

  /**
   * instantiates contract
   * @param _uri root IPFS folder
   */
  function initialize(string memory _uri, uint256 _startingRoyalty) external initializer {
    __Ownable_init();
    __Pausable_init();
    __ERC1155_init(_uri);

    baseURI = _uri;
    setSuffix(".json");
    setRoyalties(_startingRoyalty);
  }

  /**
   * mints tokens to a specified address
   * @param to the receiver of the tokens
   * @param id the ID of the token to mint
   * @param amount the number of tokens to mint
   */
  function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
    require(controllers[_msgSender()] == true, "Only controllers can mint");
    _mint(to, id, amount, data);
  }

  /**
   * batch mints token Ids to recipients
   * @param to the recipient
   * @param ids the tokenIds
   * @param amounts the amounts
   */
  function mintBatch(
          address to,
          uint256[] memory ids,
          uint256[] memory amounts,
          bytes calldata data
          ) external {
    require(controllers[_msgSender()] == true, "Only controllers can mint");
    _mintBatch(to, ids, amounts, data);
  }

  /**
   * burns tokens from a specified address
   * @param holder the holder of the tokens
   * @param id the ID of the token to burn
   * @param amount the number of tokens to burn
   */
  function burn(address holder, uint256 id, uint256 amount) external {
    require(controllers[_msgSender()] == true, "Only controllers can burn");
    _burn(holder, id, amount);
  }

  /**
   * batch burns token Ids from the holders
   * @param holder the holder
   * @param ids the tokenIds
   * @param amounts the amounts
   */
  function burnBatch(
          address holder,
          uint256[] memory ids,
          uint256[] memory amounts
          ) external {
    require(controllers[_msgSender()] == true, "Only controllers can burn");
    _burnBatch(holder, ids, amounts);
  }

  /**
   * returns the URI of a given token
   * @param tokenId the ID of the token
   */
  function uri(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, tokenId.toString(), suffix));
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /**
   * updates the base URI
   * @param _uri the new root IPFS folder
   */
  function setURI(string memory _uri) external onlyOwner {
    baseURI = _uri;
    emit URI(uri(0), 0);
  }

  /**
   * updates the URI suffix
   * @param _suffix the new URI suffix
   */
  function setSuffix(string memory _suffix) public onlyOwner {
    suffix = _suffix;
  }

  /// @inheritdoc	ERC1155Upgradeable
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override
      returns (bool)
  {
      return
          interfaceId == type(IERC2981Royalties).interfaceId ||
          super.supportsInterface(interfaceId);
  }

  /// @dev Sets token royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function setRoyalties(uint256 value) public onlyOwner {
      require(value <= 10000, 'ERC2981Royalties: Too high');
      _royalties = uint24(value);
  }

  /// @inheritdoc	IERC2981Royalties
  function royaltyInfo(uint256, uint256 value)
      external
      view
      override
      returns (address receiver, uint256 royaltyAmount)
  {
      receiver = owner();
      royaltyAmount = (value * _royalties) / 10000;
  }

}
