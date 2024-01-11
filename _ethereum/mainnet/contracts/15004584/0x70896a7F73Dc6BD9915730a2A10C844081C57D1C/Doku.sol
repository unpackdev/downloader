// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./PRBMathUD60x18.sol";
import "./ERC721AQueryable.sol";
import "./IERC721A.sol";

/**
 * @title Doku
 * @dev ERC721 contract for Doku - a truly decentralized NFT avatar.
 *
 * Free to claim. Royalties go to holders. Claim up to 20 per tx. 20 max per address.
 *
 * Royalties will be deposited into this contract and can be claimed by holders. Each Doku = 1/10,000 of available ETH, or ERC20 tokens.
 *
 * Owning a Doku grants you full commercial rights to that Doku.
 *
 * CryptoPunks were nearly the perfect NFT avatar project. It is a historic project,
 * but the actions of Larva Labs jeopardized the collection. Now the fate of the collection
 * is in the hands of Yuga Labs and any action they take jeopardizes the collection. There
 * is no centralized entity behind Doku, nor should there be. Doku is decentralized art owned
 * by the people.
 *
 * This collection was inspired by Satoshi Nakamoto. Creators claim 1,000. Smart contract ownership will
 * be revoked after minting.
 *
 * We are Doku.
 */
contract Doku is Context, ERC721AQueryable, ReentrancyGuard, Ownable {
  using PRBMathUD60x18 for uint256;

  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  string private _baseUri;
  uint256 private _totalEthClaimed;
  uint256 public MAX_SUPPLY = 10_000;

  // Storing IPFS image folder CID on-chain for verification purposes.
  string public IPFS_IMAGE_FOLDER_CID =
    "QmfRBT1sbacjYnobXuiBNTdrKe8SQAGdDxGxxNzb7suFbo";

  mapping(uint256 => uint256) private _rewardDebt;
  mapping(address => mapping(uint256 => uint256)) private _erc20RewardDebt;
  mapping(address => uint256) private _erc20TotalClaimed;

  constructor(string memory baseUri) ERC721A("Doku", "DOKU") {
    _baseUri = baseUri;
    _mintERC2309(_msgSender(), 1000);
  }

  /**
   * @dev Internal function for owner to set base URI
   */
  function setBaseUri(string memory baseUri) public onlyOwner {
    _baseUri = baseUri;
  }

  /**
   * @dev Internal function to return base URI for tokenURI function
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : "";
  }

  /**
   * @dev public function to mint a new Doku NFT
   */
  function mint(uint256 amount) public nonReentrant {
    require(_totalMinted() + amount <= MAX_SUPPLY, "Cannot mint amount");
    require(amount > 0, "Amount must be gt 0");
    require(amount <= 20, "Cannot mint for than 20 at a time");
    require(_numberMinted(_msgSender()) + amount <= 20, "20 per wallet");
    _mint(_msgSender(), amount);
  }

  /**
   * @dev Public function that can be used to calculate the pending ETH payment for a given NFT ID
   */
  function calculatePendingPayment(uint256 nftId)
    public
    view
    returns (uint256)
  {
    return
      (address(this).balance + _totalEthClaimed - _rewardDebt[nftId]).div(
        MAX_SUPPLY * 10**18
      );
  }

  /**
   * @dev Public function that can be used to calculate the pending ERC20 payment for a given NFT ID
   */
  function calculatePendingPayment(IERC20 erc20, uint256 nftId)
    public
    nonReentrant
    returns (uint256)
  {
    return
      (erc20.balanceOf(address(this)) +
        _erc20TotalClaimed[address(erc20)] -
        _erc20RewardDebt[address(erc20)][nftId]).div(MAX_SUPPLY * 10**18);
  }

  /**
   * @dev Internal function to claim ETH for a given NFT ID
   */
  function _claim(uint256 nftId) private {
    uint256 payment = calculatePendingPayment(nftId);
    require(payment > 0, "Nothing to claim");
    uint256 preBalance = address(this).balance;
    _rewardDebt[nftId] += preBalance;
    _totalEthClaimed += payment;
    address ownerAddr = ownerOf(nftId);
    Address.sendValue(payable(ownerAddr), payment);
    emit PaymentReleased(ownerAddr, payment);
  }

  /**
   * @dev Public function to claim ETH for a given NFT ID. Note 1 Doku = 1 Doku for the purpose of claiming.
   * While a Doku may look more desirable and have higher trait rarity, when it comes to claiming they are all the same.
   * 1 Doku = 1 / 10,000 of available payment
   */
  function claim(uint256 nftId) public nonReentrant {
    _claim(nftId);
  }

  /**
   * @dev Internal function to claim ERC20 token for a given NFT ID
   */
  function _claim(IERC20 erc20, uint256 nftId) private {
    uint256 payment = calculatePendingPayment(erc20, nftId);
    require(payment > 0, "Nothing to claim");
    uint256 preBalance = erc20.balanceOf(address(this));
    _erc20RewardDebt[address(erc20)][nftId] += preBalance;
    _erc20TotalClaimed[address(erc20)] += payment;
    address ownerAddr = ownerOf(nftId);
    erc20.transfer(ownerAddr, payment);
    emit ERC20PaymentReleased(erc20, ownerAddr, payment);
  }

  /**
   * @dev Public function to claim ERC20 token for a given NFT ID
   */
  function claim(IERC20 erc20, uint256 nftId) public nonReentrant {
    _claim(erc20, nftId);
  }

  /**
   * @dev Public function to claim ETH for a list of NFT IDs
   */
  function claimMany(uint256[] memory nftIds) public nonReentrant {
    for (uint256 i = 0; i < nftIds.length; i++) {
      _claim(nftIds[i]);
    }
  }

  /**
   * @dev Public function to claim ERC20 tokens for a list of NFT IDs
   */
  function claimMany(IERC20 erc20, uint256[] memory nftIds) public {
    for (uint256 i = 0; i < nftIds.length; i++) {
      _claim(erc20, nftIds[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  /**
   * @dev Function to send arbitrary data
   */
  function message(bytes calldata data) public onlyOwner {}
}
