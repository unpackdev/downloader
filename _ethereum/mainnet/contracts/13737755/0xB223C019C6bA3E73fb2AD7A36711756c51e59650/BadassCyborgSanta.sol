// contracts/BadassCyborgSanta.sol
// SPDX-License-Identifier: None

/// @author BadassComet of The Badass Cyborg Santa NFT Collection Team

pragma solidity ^0.8.9;

import "./ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";


contract BadassCyborgSanta is ERC721PresetMinterPauserAutoIdUpgradeable, EIP712Upgradeable
{

  uint256 public saleStartTime;

  uint256 public maxSupply;

  uint256 public tokenPrice;

  uint256 public lotteryFee;

  uint256 public winner;

  bool public winnerPicked;

  bytes32 public DOMAIN_SEPARATOR;

  address payable private treasury;

  string private _baseTokenURI;

  string private _contractURI;

  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter private _tokenIdTracker;

  event BaseURIChanged(string newBaseURI);

  event SaleStartUpdated(uint256 startTime, uint256 tokenPrice, uint256 lotteryFee);

  event ContractUriUpdated(string contractMetaURI);

  event WinnerPicked(uint256 winner);

  event PrizeCollected(uint256 amount,address winner);

  function initialize(
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    string memory contractMetaURI,
    uint256 _maxSupply,
    address payable _treasury
  ) public virtual initializer {

    ERC721PresetMinterPauserAutoIdUpgradeable.initialize(name, symbol, baseTokenURI);

    EIP712Upgradeable.__EIP712_init(name, '1'); // hardcoded version 1

    // contract implements the EIP 712 domain separator
    DOMAIN_SEPARATOR = _domainSeparatorV4();

    maxSupply = _maxSupply;

    treasury = _treasury;

    _baseTokenURI = baseTokenURI;

   _contractURI = contractMetaURI;
  }

  /**
   * @dev Restricted to members of the DEFAULT_ADMIN_ROLE role.
  */
  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "caller must have the `DEFAULT_ADMIN_ROLE`");
    _;
  }

  /**
   * @dev configure stat
   * - startTime  -  unix timestamp of sale start moment
   * - _tokenPrice  - minting const
   * - _lotteryFee  - included in minting const
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
  */
  function setSaleStart(uint256 startTime,uint256 _tokenPrice,uint256 _lotteryFee) external onlyAdmin {

     // persist saleStartTime
    saleStartTime = startTime;

    // persist tokenPrice
    tokenPrice = _tokenPrice;

    // persist lotteryFee
    lotteryFee = _lotteryFee;

    // emit SaleStartUpdated event
    emit SaleStartUpdated(startTime, _tokenPrice, _lotteryFee);
  }

  /**
   * @dev setContractURI
   *  updated contractURI value
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
  */
  function setContractURI(string calldata contractMetaURI) external onlyAdmin {

    // persist _contractURI
    _contractURI = contractMetaURI;

    // emit ContractUriUpdated event
    emit ContractUriUpdated(contractMetaURI);
  }

  /**
   * @dev reveal nft's
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
   */
  function revealNFT(string calldata baseTokenURI) external onlyAdmin {

    // persist new baseTokenURI
    _baseTokenURI = baseTokenURI;

    // emit BaseURIChanged event
    emit BaseURIChanged(baseTokenURI);
  }

  /**
   * @dev preSaleMint
   *  used to mint tokens before tokenSale has started
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
   * - the caller must pay count * lotteryFee
   */
  function preSaleMint(address to, uint256 count) external payable onlyAdmin {

    // lotteryFee must be set via function setSaleStart(startTime,_tokenPrice,_lotteryFee)
    require(lotteryFee > 0, "lotteryFee not configured");

    // Gas optimization
    uint256 _currentTokenId = _tokenIdTracker.current();

    // check if max supply will not exceed
    require(_currentTokenId + count <= maxSupply, "max supply exceeded");

    // preSale tokens must also pay lotteryFee to keep the lottery fair
    require(msg.value >= count * lotteryFee, "incorrect lotteryFee");

    // mint tokens for to address
    for (uint256 ind = 0; ind < count; ind++) {
        _safeMint(to, _currentTokenId + ind);
        _tokenIdTracker.increment();
    }
  }

  /**
   * @dev pickWinner
   * called once to pick winner
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
  */
  function pickWinner() external onlyAdmin
  {
    // prevent winner from being picked twice
    require(!winnerPicked, "Winning nft already picked");

    // pick a random winning number
    uint256 winningNumber = random() % _tokenIdTracker.current();

    // persist winning number
    winner = winningNumber;

    // set winnerPicked = true so it can only be picked once
    winnerPicked = true;

    // emit WinnerPicked event
    emit WinnerPicked(winningNumber);
  }

  /**
   * @dev random
   * generates an unpridictable random number wich will be used to pick a winner
   *
   * Requirements:
   * - the caller must have the `DEFAULT_ADMIN_ROLE`.
  */
  function random() private view returns(uint){
    return uint(keccak256(abi.encode(block.difficulty, block.number, _tokenIdTracker.current())));
  }

  /**
   * @dev mintToken
   *  used to mint tokens during tokenSale
   *
   * Requirements:
   * - the caller must pay tokenPrice
   */
  function mintToken() external payable {

    // Make sure sale has been set up
    require(saleStartTime > 0, "sale not configured");

    // check if sale startTime has passed
    require(block.timestamp >= saleStartTime, "sale not started");

    // Gas optimization
    uint256 _currentTokenId = _tokenIdTracker.current();

    // check if max supply will not exceed
    require(_currentTokenId + 1 <= maxSupply, "max supply exceeded");

    // check if minters fee is enough
    require(msg.value >= tokenPrice, "incorrect Ether value");

    // Subtract - leave lotteryFee behind and redirected the rest to treasury.
    treasury.transfer(msg.value - lotteryFee);

    // mint token for msg.sender
    _mint(msg.sender, _currentTokenId);

    // increase token counter
    _tokenIdTracker.increment();
  }

  /**
   * @dev collectPrize,
   * called by user holding winning nft
   *
   * Requirements:
   * - the caller must be ownerOf(winner).
  */
  function collectPrize() external
  {
    // require a winner already picked
    require(winnerPicked, "Winner not picked yet");

    // the caller must be ownerOf(winner)
    require(msg.sender == ERC721Upgradeable.ownerOf(winner), "must be owner of winning nft");

    // contract must hold balance to extract
    require(address(this).balance > 0, "No balance left to withdraw");

    // wrap winners address as payable so we can use the tranfer function on it
    address payable winnerAddress = payable(msg.sender);

    // Gas optimization
    uint256 prize = address(this).balance;

    // transfer the full balance to the single winner
    winnerAddress.transfer(prize);

    // emit PrizeCollected event
    emit PrizeCollected(prize, msg.sender);
  }

  /**
   * @dev returns uri where contract parameters can be found
  */
  function contractURI() public view virtual returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev returns _baseURI used to build tokenUri
  */
  function _baseURI() internal view virtual override(ERC721PresetMinterPauserAutoIdUpgradeable) returns (string memory) {
    return _baseTokenURI;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721PresetMinterPauserAutoIdUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721PresetMinterPauserAutoIdUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
