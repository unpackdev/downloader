// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./nf-token-metadata.sol";
import "./nf-token-enumerable.sol";
import "./ownable.sol";

contract MoonTotems is
  NFTokenEnumerable,
  NFTokenMetadata,
  Ownable
{
  /**
   * @dev The smallest valid token id.
   */
  uint256 public constant MIN_TOKEN_ID = 0;

  /**
   * @dev The largest valid token id.
   */
  uint256 public constant MAX_TOKEN_ID = 9457;

  /**
   * @dev Whether minting is allowed.
   */
  bool public MINT_IS_ACTIVE = false;

  /**
   * @dev The price for minting a totem.
   */
  uint256 public TOTEM_MINT_PRICE = 100000000000000000; // 0.1 ETH

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   * @param _nftBaseUri A base prefix for all token uris.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _nftBaseUri
  )
  {
    nftName = _name;
    nftSymbol = _symbol;
    nftBaseUri = _nftBaseUri;
  }

  /**
   * @dev Emits when a NFTs is minted.
   */
  event Mint(address indexed _to, uint256 indexed _tokenId);

  /**
   * @dev Emits when TOTEM_MINT_PRICE is updated.
   */
  event TotemMintPriceUpdate(address indexed _by, uint256 indexed _amount);

  /**
   * @dev Emits when MINT_IS_ACTIVE is updated.
   */
  event MintFlagUpdate(address indexed _by, bool indexed _active);


  /**
   * @dev Requirements that have to be met for minting to work.
   * @param _tokenId ID of the NFT to mint.
   */
  modifier canMint(
    uint256 _tokenId
  )
  {
    require(MINT_IS_ACTIVE, "Minting is not active");
    require(_tokenId >= MIN_TOKEN_ID, "TokenId needs to be >= MIN_TOKEN_ID");
    require(_tokenId <= MAX_TOKEN_ID, "TokenId needs to be <= MAX_TOKEN_ID");
    require(msg.value == TOTEM_MINT_PRICE, "Amount needs to be equal to TOTEM_MINT_PRICE");
    _;
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId The tokenId of the NFT to be minted by the msg.sender.
   */
  function mint(
    address _to,
    uint256 _tokenId
  )
    external
    payable
    canMint(_tokenId)
  {
    super._mint(_to, _tokenId);
    emit Mint(msg.sender, _tokenId);
  }

  /**
   * @dev Updates the price for minting a totem.
   * @param _totemMintPrice The new price in wei.
   */
  function setNewMintPrice(
    uint256 _totemMintPrice
  )
    external
    onlyOwner
  {
    TOTEM_MINT_PRICE = _totemMintPrice;
    emit TotemMintPriceUpdate(msg.sender, _totemMintPrice);
  }

  /**
   * @dev Toggle whether minting is allowed.
   */
  function flipMintFlag()
    external
    onlyOwner
  {
    MINT_IS_ACTIVE = !MINT_IS_ACTIVE;
    emit MintFlagUpdate(msg.sender, MINT_IS_ACTIVE);
  }

  /**
   * @dev Removes a NFT from the owner and allows the NFT to be minted again.
   * @param _tokenId Which NFT should get removed.
   */
  function burn(
    uint256 _tokenId
  )
    external
    canTransfer(_tokenId)
  {
    super._burn(_tokenId);
  }

  /**
   * @dev Set base URI for computing {tokenURI}.
   * @param _baseUri The new baseUri.
   */
  function setBaseUri(
    string memory _baseUri
  )
    external
    onlyOwner
  {
    super._setBaseUri(_baseUri);
  }

  /**
   * @dev Withdraw contract balance to contract owner.
   */
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
    virtual
  {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override(NFTokenMetadata, NFTokenEnumerable)
    virtual
  {
    NFTokenEnumerable._burn(_tokenId);
  }

  /**
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @dev Removes a NFT from an address.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @dev Assigns a new NFT to an address.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override(NFToken, NFTokenEnumerable)
    view
    returns (uint256)
  {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

}
