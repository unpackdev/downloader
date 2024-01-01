// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuard.sol";

import "./IDecaCollection.sol";
import "./IDecaCollectionFactory.sol";
import "./IRoleAuthority.sol";

/**
 * @title DecaCollection implementation contract.
 * @notice Used in the DecaCollectionFactory to create Deca collections.
 * @dev This is to be deployed behind a proxy.
 * @author 0x-jj, j6i
 */
contract DecaCollection is Initializable, ReentrancyGuard, IDecaCollection, ERC721Upgradeable, OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

  /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The basis points for the royalty percentage for the collection
   */
  uint256 internal constant BASIS_POINTS = 10000;

  /**
   * @notice The royalty percentage for the collection, in basis points
   */
  uint256 public royaltyBps;

  /**
   * @notice The address of the factory contract that created this collection.
   */
  address public factory;

  /**
   * @notice The primary creator for the collection
   * @dev Used for admin functionality such as freezing the contract implementation or setting token URI
   */
  address public creator;

  /**
   * @notice The address of the central role authority to determine higher admin roles such as minting
   */
  IRoleAuthority public roleAuthority;

  /**
   * @notice address(this) is the default treasury address, but it can be overridden.
   * @dev Expected to be of type IRoyaltySplitter, but not essential or enforced.
   * @dev If treasury is address(0), then the royalty will be sent to this contract.
   */
  address public treasury;

  /**
   * @notice A store of static token URIs to use instead of the central metadata resolver
   */
  mapping(uint256 => string) private _tokenURIs;

  /**
   * @notice A store of the mint timestamps for each token, to be used for determining whether a token has been minted before
   */
  mapping(uint256 => uint256) public mintTimestamps;

  /**
   * @notice A store of the recipients and their respective shares of the split
   */
  Recipient[] private _recipients;

  /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Requires that the msg.sender has the minter role or is the creator.
   */
  modifier onlyMinterOrCreator() {
    if (msg.sender != creator && !roleAuthority.is721Minter(msg.sender)) revert OnlyMinterOrCreator();
    _;
  }

  /**
   * @dev Requires that the msg.sender is the creator of the collection.
   */
  modifier onlyCreator() {
    if (msg.sender != creator) revert OnlyCreator();
    _;
  }

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Initializer called after contract creation.
   * @dev Can only be called once.
   * @param factory_ The factory address.
   * @param creator_ The address of the creator of the collection.
   * @param roleAuthority_ The address of the contract that determines whether an address has admin roles.
   * @param name_ The name for the created collection.
   * @param symbol_ The symbol for the collection.
   * @param recipients The royalty recipients for the collection's secondary market royalties
   */
  function initialize(
    address factory_,
    address creator_,
    address roleAuthority_,
    string calldata name_,
    string calldata symbol_,
    Recipient[] calldata recipients
  ) external initializer {
    __ERC721_init(name_, symbol_);
    __Ownable_init();
    factory = factory_;
    creator = creator_;
    roleAuthority = IRoleAuthority(roleAuthority_);
    royaltyBps = 500;
    _transferOwnership(creator);
    _setRecipients(recipients);
  }

  /**
   * @notice Mints a new token to the given address.
   * @dev Can only be called by an address with the DECA_721_MINTER role, or the creator.
   * @param to The address to send the token to.
   * @param tokenId The tokenId of the token.
   */
  function mint(address to, uint256 tokenId) external onlyMinterOrCreator {
    mintTimestamps[tokenId] = block.timestamp;
    _mint(to, tokenId);
  }

  /**
   * @notice Sets a static token URI for a given token.
   *         Intended to be used to set decentralized metadata for tokens.
   * @dev Can only be called by the creator of the collection.
   * @param tokenId The tokenId of the token.
   * @param tokenURI_ The token URI to set.
   */
  function setTokenUri(uint256 tokenId, string calldata tokenURI_) external onlyCreator {
    if (!_exists(tokenId)) revert InvalidTokenId();

    _tokenURIs[tokenId] = tokenURI_;
    emit TokenUriSet(tokenId, tokenURI_);
  }

  /**
   * @notice Sets the treasury address which receives secondary market royalties for the contract.
   * @dev Expected to be of type IRoyaltySplitter, but not essential or enforced.
   * @param treasury_ The new treasury address
   */
  function setTreasuryAddress(address treasury_) external onlyCreator {
    treasury = treasury_;
    emit TreasuryUpdated(treasury_);
  }

  /**
   * @notice Sets the royalty percentage in basis points for the contract.
   * @param royaltyBps_ The new royalty percentage
   */
  function setRoyaltyBps(uint256 royaltyBps_) external onlyCreator {
    royaltyBps = royaltyBps_;
    emit RoyaltyBpsUpdated(royaltyBps_);
  }

  /**
   * @dev Set the splitter recipients. Total bps must total 10000.
   * @param recipients The new recipients
   */
  function setRecipients(Recipient[] calldata recipients) external onlyCreator {
    _setRecipients(recipients);
  }

  /**
   * @notice Allows any ETH stored by the contract to be split among recipients.
   * @dev Normally ETH is forwarded as it comes in, but a balance in this contract
   * is possible if it was sent before the contract was created or if self destruct was used.
   */
  function splitETH() external nonReentrant {
    _splitETH(address(this).balance);
  }

  /**
   * @notice Anyone can call this function to split all available tokens at the provided address between the recipients.
   * @dev This contract is built to split ETH payments. The ability to attempt to split ERC20 tokens is here
   * just in case tokens were also sent so that they don't get locked forever in the contract.
   * @param erc20Contract The ERC20 contract to split
   */
  function splitERC20Tokens(IERC20Upgradeable erc20Contract) external nonReentrant {
    if (!_splitERC20Tokens(erc20Contract)) revert ERC20SplitFailed();
  }

  /**
   * @notice Burns a token
   * @param tokenId The tokenId to burn
   */
  function burn(uint256 tokenId) external {
    if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotTokenOwnerOrApproved();

    _burn(tokenId);
  }

  /**
   * @notice Forwards any ETH received to the recipients in this split.
   * @dev Each recipient increases the gas required to split
   * and contract recipients may significantly increase the gas required.
   */
  receive() external payable {
    _splitETH(msg.value);
  }

  /*//////////////////////////////////////////////////////////////
                                 EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the EIP2981 royalty info for a given token.
   * @dev The treasury is expected to be an IRoyaltySplitter contract, so that the Royalty Registry engine
   * can then be used to read an array of end recipients and their respective royalty shares.
   * See https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/RoyaltyEngineV1.sol#L170-L195
   * @param _salePrice The sale price of the token.
   */
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (treasury != address(0) ? treasury : address(this), (_salePrice * royaltyBps) / 10000);
  }

  /**
   * @dev Get the splitter recipients;
   * @return The recipients
   */
  function getRecipients() external view returns (Recipient[] memory) {
    return _recipients;
  }

  /**
   * @notice Returns whether a token exists (has been minted and not burned)
   * @param tokenId The tokenId to burn
   * @return Whether the token exists
   */
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /*//////////////////////////////////////////////////////////////
                                 PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Returns the token URI for a given token. If a static token URI has been set, it will return that.
   * @param tokenId The tokenId to burn
   * @return tokenUri The token URI
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert InvalidTokenId();

    string memory _tokenURI = _tokenURIs[tokenId];
    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    }
    return IDecaCollectionFactory(factory).tokenUri(address(this), tokenId);
  }

  /**
   * @notice Returns whether this contract implements a given interface
   * @param interfaceId The interface ID to check for support
   * @return Whether the interface is supported
   */
  function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable) returns (bool) {
    return interfaceId == type(IDecaCollection).interfaceId || super.supportsInterface(interfaceId);
  }

  /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Split ETH between recipients
   * @param value The amount of ETH to split
   */
  function _splitETH(uint256 value) internal {
    if (value > 0) {
      uint256 totalSent;
      uint256 amountToSend;
      unchecked {
        for (uint256 i = _recipients.length - 1; i > 0; i--) {
          Recipient memory recipient = _recipients[i];
          amountToSend = (value * recipient.bps) / BASIS_POINTS;
          totalSent += amountToSend;
          (bool success, ) = recipient.recipient.call{value: amountToSend}("");
          if (!success) revert EthTransferFailed();
          emit ETHTransferred(recipient.recipient, amountToSend);
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = value - totalSent;
      }
      (bool success2, ) = _recipients[0].recipient.call{value: amountToSend}("");
      if (!success2) revert EthTransferFailed();
      emit ETHTransferred(_recipients[0].recipient, amountToSend);
    }
  }

  /**
   * @dev Split ERC20 tokens between recipients
   * @param erc20Contract The ERC20 contract to split
   * @return success Whether the split was successful
   */
  function _splitERC20Tokens(IERC20Upgradeable erc20Contract) internal returns (bool) {
    try erc20Contract.balanceOf(address(this)) returns (uint256 balance) {
      if (balance == 0) {
        return false;
      }
      uint256 amountToSend;
      uint256 totalSent;
      unchecked {
        for (uint256 i = _recipients.length - 1; i > 0; i--) {
          Recipient memory recipient = _recipients[i];
          bool success;
          (success, amountToSend) = balance.tryMul(recipient.bps);

          amountToSend /= BASIS_POINTS;
          totalSent += amountToSend;
          try erc20Contract.transfer(recipient.recipient, amountToSend) {
            emit ERC20Transferred(address(erc20Contract), recipient.recipient, amountToSend);
          } catch {
            return false;
          }
        }
        // Favor the 1st recipient if there are any rounding issues
        amountToSend = balance - totalSent;
      }
      try erc20Contract.transfer(_recipients[0].recipient, amountToSend) {
        emit ERC20Transferred(address(erc20Contract), _recipients[0].recipient, amountToSend);
      } catch {
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  /*//////////////////////////////////////////////////////////////
                                 PRIVATE
    //////////////////////////////////////////////////////////////*/

  /**
   * @dev Set the splitter recipients. Total bps must total 10000.
   * @param recipients The new recipients
   */
  function _setRecipients(Recipient[] calldata recipients) private {
    delete _recipients;
    if (recipients.length == 0) {
      return;
    }
    uint256 totalBPS;
    for (uint256 i; i < recipients.length; ++i) {
      totalBPS += recipients[i].bps;
      _recipients.push(recipients[i]);
    }
    if (totalBPS != BASIS_POINTS) revert TotalBpsMustBe10000();
  }
}
