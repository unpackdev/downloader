//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

// ╭━━━╮  ╭╮      ╭╮   ╭━━━┳╮
// ┃╭━╮┃ ╭╯╰╮     ┃┃   ┃╭━━┫┃
// ┃╰━━┳━┻╮╭╋━━┳━━┫╰━┳╮┃╰━━┫┃╭━━┳╮╭╮╭┳━━┳━┳━━╮
// ╰━━╮┃╭╮┃┃┃╭╮┃━━┫╭╮┣┫┃╭━━┫┃┃╭╮┃╰╯╰╯┃┃━┫╭┫━━┫
// ┃╰━╯┃╭╮┃╰┫╰╯┣━━┃┃┃┃┃┃┃  ┃╰┫╰╯┣╮╭╮╭┫┃━┫┃┣━━┃
// ╰━━━┻╯╰┻━┻━━┻━━┻╯╰┻╯╰╯  ╰━┻━━╯╰╯╰╯╰━━┻╯╰━━╯

import "./ERC721A.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSALibrary.sol";
import "./console.sol";

/// @title Satoshi Flowers NFT Collection Configuration
/// @author Mouradif
contract SatoshiFlowersConfig is ERC721A, AccessControl, Ownable {
  using Strings for uint256;

  /// @dev Roles for mint approval signatures
  bytes32 internal constant FREEMINT_APPROVER = keccak256("FREE");
  bytes32 internal constant PRIVATEMINT_APPROVER = keccak256("PRIVATE");

  /// @notice Maximum Supply
  uint256 public constant MAX_SUPPLY = 3933;

  /// @notice Price for public mint
  uint256 public constant PUBLIC_PRICE = 0.03 ether;

  /// @notice Price for private mint
  uint256 public constant PRESALE_PRICE = 0.025 ether;

  /// @notice Maximum mint amount per transaction in public sale
  uint256 public constant PUBLIC_MAX_MINT = 5;

  /// @notice Maximum mint amount in private sale (per wallet)
  uint256 public constant PRESALE_MAX_MINT = 3;

  /// @notice Maximum mint amount per wallet in total
  uint256 public constant TOTAL_MAX_MINT = 20;

  /// @notice Supply reserved for freemints (reserved for 6550 blocks)
  uint256 public constant FREEMINT_SUPPLY = 160;

  /// @notice Presale start block (approximately April 12th 2022 at 16:00 UTC
  uint256 public constant PRESALE_START_BLOCK = 14571680;

  /// @notice Public sale start block (approximately 1h later)
  uint256 public constant PUBLIC_START_BLOCK = PRESALE_START_BLOCK + 273;

  /// @notice End of reservation for Freemints (approximately 23h later)
  uint256 public constant FREEMINT_END_BLOCK = PRESALE_START_BLOCK + 6550;

  /// @dev Counters to enforce the supply limits
  mapping (address => uint256) internal _presaleMints;
  mapping (address => uint256) internal _totalMints;
  mapping(address => bool) internal _freeMintClaimed;
  uint256 internal _freemints;

  /// @notice Our common wallet
  address internal constant BANK = 0x571cDE5D760456eA8a5b96E93Bbf306Eb336765e;

  /// @notice Modifier to ensure the max supply won't be exceeded by a mint transaction
  modifier hasSupply(uint256 quantity) {
    require(totalSupply() + quantity <= MAX_SUPPLY, "I'm out of stock!");
    _;
  }

  /// @notice Modifier to ensure the freemint reserve won't be touched by a mint transaction
  modifier hasSupplyOutsideReserve(uint256 quantity) {
    require(
      freemintClosed() ||
      totalSupply() + quantity + FREEMINT_SUPPLY - _freemints <= MAX_SUPPLY,
      "Free mint supply reserve reached"
    );
    _;
  }

  /// @notice Modifier to ensure the message signer has a role
  modifier isApproved(bytes calldata signature, bytes32 role) {
    require(
      hasRole(
        role,
        ECDSALibrary.recover(abi.encodePacked(msg.sender), signature)
      ),
      "You have not been approved for that type of mint"
    );
    _;
  }

  /// @notice Modifier to ensure the max mint quantity isn't exceeded
  modifier isWithinMintLimit(uint256 quantity, uint256 limit) {
    require(quantity <= limit, "You can't mint that many");
    _;
  }

  /// @notice Modifier to ensure the right amount has been sent (no more, no less)
  modifier hasTheRightAmount(uint256 amount) {
    require(msg.value == amount, "You must send the right amount");
    _;
  }
  /// @notice Contract constructor. Distributes roles to signers
  constructor() ERC721A("Satoshi Flowers", "SATFLOW") {
    _grantRole(FREEMINT_APPROVER, 0xbf29EB12a73f7FCAe5Adc5dfa48859cce4bA3908);
    _grantRole(PRIVATEMINT_APPROVER, 0xaA76a7825801148B406A9b41E4bB846c8aCb4B30);
  }

  /// @notice Checks if the freemint period is over
  function freemintClosed() public view returns(bool) {
    return block.number > FREEMINT_END_BLOCK;
  }

  /// @notice Our hard earned retribution
  function transferFunds() public {
    payable(BANK).transfer(address(this).balance);
  }

  /// @notice URI to the ooken metadata
  /// @param tokenId The ID of the token to inspect
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  /// @notice Metadata are served by our API
  function _baseURI()
    internal
    pure
    override(ERC721A)
    returns (string memory)
  {
    return "https://api.satoshiflowers.art/metadata/";
  }

  /// @notice Contract level Metadata
  function contractURI()
    public
    pure
    returns (string memory)
  {
    return string(abi.encodePacked(_baseURI(), "satoshi-flowers"));
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  override(ERC721A, AccessControl)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
