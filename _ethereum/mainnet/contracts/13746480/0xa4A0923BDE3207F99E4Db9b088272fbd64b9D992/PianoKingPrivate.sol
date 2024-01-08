// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./PianoKingPrivateSplitter.sol";
import "./Clones.sol";

/**
 * @dev Contract meant for the private collection of Piano King
 */
contract PianoKingPrivate is
  ERC721,
  ERC721URIStorage,
  ERC721Burnable,
  IERC2981,
  Ownable
{
  using Counters for Counters.Counter;
  using Clones for address;

  Counters.Counter private _tokenIdCounter;
  address public minter = 0x32a5dE462B2e6f3bFeCc7d558B3ac871F0C2fbF8;
  address internal splitterImplementation;

  // Mapping each token id to its splitter contract
  mapping(uint256 => PianoKingPrivateSplitter) private idToSplitter;
  // Mapping each token id to its royalties
  mapping(uint256 => uint256) private idToRoyalties;

  uint256 public totalSupply;

  constructor() ERC721("Piano King Private", "PKP") {
    // We deploy the splitter implementation directly from the constructor
    // to make this contract the owner
    splitterImplementation = address(new PianoKingPrivateSplitter());
  }

  /**
   * @dev Modifier restricting access to only the minter
   */
  modifier onlyMinter() {
    require(msg.sender == minter, "Not minter");
    _;
  }

  /**
   * @dev Mint and send it directly to the minter
   */
  function mint(
    string memory uri,
    address creator,
    uint256 minterRoyalties,
    uint256 creatorRoyalties
  ) external onlyMinter {
    // Just call the mintFor function with the minter as the target address
    mintFor(minter, uri, creator, minterRoyalties, creatorRoyalties);
  }

  /**
   * @dev Mint and send to a given address
   */
  function mintFor(
    address to,
    string memory uri,
    address creator,
    uint256 minterRoyalties,
    uint256 creatorRoyalties
  ) public onlyMinter {
    // Get the token id to use
    uint256 tokenId = _tokenIdCounter.current();
    // Increment the token id counter for the next mint
    _tokenIdCounter.increment();
    // Safely mint the token and send it to the target address
    _safeMint(to, tokenId);
    // Associate the URI of the metadata for that given token
    _setTokenURI(tokenId, uri);
    // Store the total royalties on this contract
    idToRoyalties[tokenId] = minterRoyalties + creatorRoyalties;
    // Create a new splitter contract for this NFT to automatize
    // the division of royalties between the minter and the creator
    // We use a minimal clone proxy to save cost compared to a regular
    // deploy
    address payable splitterClone = payable(splitterImplementation.clone());
    PianoKingPrivateSplitter(splitterClone).initiliaze(
      creator,
      minter,
      minterRoyalties,
      creatorRoyalties
    );
    idToSplitter[tokenId] = PianoKingPrivateSplitter(splitterClone);
  }

  /**
   * @dev Set the address of the minter
   */
  function setMinter(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    minter = addr;
  }

  // The following functions are overrides required by Solidity.

  /**
   * @dev Override of an OpenZeppelin hook called on before any token transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    if (to == address(0)) {
      // Decrease the supply by one when a token is burnt
      totalSupply -= 1;
    } else if (from == address(0)) {
      // Increase the supply by one when a token is minted
      totalSupply += 1;
    }
    super._beforeTokenTransfer(from, to, tokenId);
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

  /**
   * @dev Get the address of the Splitter Contract associated to
   * a token
   */
  function getTokenSplitterContract(uint256 tokenId)
    external
    view
    returns (address)
  {
    // Check the token does exist
    require(_exists(tokenId), "Token does not exist");
    return address(idToSplitter[tokenId]);
  }

  /**
   * @dev Send the royalties received so for for a given token
   * to the minter and its creator
   */
  function retrieveRoyalties(uint256 tokenId) external {
    // Check the token does exist
    require(_exists(tokenId), "Token does not exist");
    // Get the splitter contract clone associated to the token
    PianoKingPrivateSplitter splitterContract = PianoKingPrivateSplitter(
      idToSplitter[tokenId]
    );
    // The sender can be either the owner of the contract, the minter or
    // the creator of the NFT
    require(
      msg.sender == owner() ||
        msg.sender == minter ||
        msg.sender == splitterContract.getCreator(),
      "Not allowed"
    );
    // Retrieve the royalties
    splitterContract.retrieveRoyalties();
  }

  /**
   * @dev Called with the sale price to determine how much royalty is owed and to whom.
   * @param tokenId - the NFT asset queried for royalty information
   * @param salePrice - the sale price of the NFT asset specified by `tokenId`
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for `salePrice`
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    // Check the token does exist
    require(_exists(tokenId), "Token does not exist");
    // The Splitter contract will receive the funds and allows to split
    // the payment between the minter and the creator
    receiver = address(idToSplitter[tokenId]);
    // We divide it by 10000 as the royalties can change from
    // 0 to 10000 representing percents with 2 decimals
    royaltyAmount = (salePrice * idToRoyalties[tokenId]) / 10000;
  }
}
