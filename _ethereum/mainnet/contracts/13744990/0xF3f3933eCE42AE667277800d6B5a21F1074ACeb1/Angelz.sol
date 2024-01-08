// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.10;

import "Strings.sol";
import "MerkleProof.sol";
import "ERC721Enum.sol";
import "Grace.sol";
import "IAngelz.sol";
import "ISanctuary.sol";

contract Angelz is IAngelz, ERC721Enum {
  using Strings for uint256;
  // mint price
  uint256 public constant MINT_PRICE = .0543 ether;
  // max number of tokens that can be minted - 30,616
  uint256 public immutable MAX_TOKENS;
  // number of tokens pay with eth - 25% of MAX_TOKENS
  uint256 public PAID_TOKENS;
  // number of tokens have been minted so far
  uint16 public minted;
  string public baseURI;
  bytes32 private rootWL;
  string internal constant baseExtension = ".json";
  bool public pauseMint = true;
  bool public pausePreMint = true;
  address public immutable owner;
  uint256 public freeMint = 500;

  address private constant addressOne =
    0xD70Ee431F074Fb835132ddE35255F8274A51D90b;
  address private constant addressTwo =
    0x13542174BA72e443450926Ea7fC15ED6D66491e0;
  address private constant addressThree =
    0xcC187E04A67c5601693dB7F25E4309D066512a24;

  // mapping from tokenId to a struct containing the token's traits
  mapping(uint256 => AngelHuman) public tokenTraits;
  // reference to the Sanctuary for choosing random Angel thieves
  ISanctuary public sanctuary;
  // reference to $GRACE for burning on mint
  GRACE public grace;

  /**
   * instantiates contract and rarity tables
   */
  constructor(address _grace, string memory _initBaseURI)
    ERC721P("AngelzGame", "AG")
  {
    owner = msg.sender;
    grace = GRACE(_grace);
    setBaseURI(_initBaseURI);
    MAX_TOKENS = 30616;
    PAID_TOKENS = MAX_TOKENS / 4;
  }

  modifier mintOpen() {
    require(!pauseMint, "PauseMint");
    _;
  }

  modifier preMintOpen() {
    require(!pausePreMint, "PausePreMint");
    _;
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  function _onlyOwner() private view {
    require(msg.sender == owner, "onlyOwner");
  }

  /** EXTERNAL */

  /**
   * mint a token - 90% Human, 10% Angel
   * The first 25% are 0.0543 eth, the remaining cost $GRACE
   */
  function mint(uint256 amount, bool stake) external payable mintOpen {
    require(tx.origin == msg.sender, "Only EOA");
    require(minted + amount <= MAX_TOKENS, "Allminted");
    require(amount > 0 && amount <= 10, "nomorethan10");
    if (minted < PAID_TOKENS) {
      if (minted < freeMint) {
        require(amount <= 2, "freelimit2pertx");
        require(msg.value == 0, "bruh its free");
      } else {
        require(minted + amount <= PAID_TOKENS, "Allonsaleminted");
        require(msg.value >= amount * MINT_PRICE, "notenougheth");
      }
    } else {
      require(msg.value == 0, "payinGRACE");
    }

    uint256 totalGraceTokenCost = 0;
    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
    uint256 seed;
    for (uint256 i = 0; i < amount; i++) {
      seed = random(minted);
      generate(minted, seed);
      address recipient = selectRecipient(seed);
      if (!stake || recipient != _msgSender()) {
        _safeMint(recipient, minted);
      } else {
        _safeMint(address(sanctuary), minted);
        tokenIds[i] = minted;
      }
      minted++;
      totalGraceTokenCost += mintCost(minted);
    }

    if (totalGraceTokenCost > 0) grace.burn(_msgSender(), totalGraceTokenCost);
    if (stake) sanctuary.addManyToSanctuaryAndHeaven(_msgSender(), tokenIds);
  }

  function preMint(
    uint256 amount,
    bool stake,
    bytes32[] calldata proof,
    uint256 _number
  ) external payable preMintOpen {
    require(tx.origin == msg.sender, "Only EOA");
    uint16 eligibilitySender = isEligible(proof, _number);
    if (eligibilitySender == 0) {
      revert("notWL");
    }
    require(minted + amount <= PAID_TOKENS, "Allminted");
    require(amount > 0 && amount <= 10, "nomorethan10");
    if (minted < freeMint) {
      require(amount <= 2, "freelimit2pertx");
      require(msg.value == 0, "bruh its free");
    } else {
      require(msg.value >= amount * MINT_PRICE, "notenougheth");
    }

    uint16[] memory tokenIds = stake ? new uint16[](amount) : new uint16[](0);
    uint256 seed;
    for (uint256 i = 0; i < amount; i++) {
      seed = random(minted);
      generate(minted, seed);
      address recipient = selectRecipient(seed);
      if (!stake || recipient != _msgSender()) {
        _safeMint(recipient, minted);
      } else {
        _safeMint(address(sanctuary), minted);
        tokenIds[i] = minted;
      }
      minted++;
    }
    if (stake) sanctuary.addManyToSanctuaryAndHeaven(_msgSender(), tokenIds);
  }

  /**
   * the first 25% are 0.0543 ETH
   * the next 25% are 10000 $GRACE
   * the next 25% are 20000 $GRACE
   * the final 25% are 40000 $GRACE
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS) return 0;
    if (tokenId <= (MAX_TOKENS * 2) / 4) return 10000 ether;
    if (tokenId <= (MAX_TOKENS * 3) / 4) return 20000 ether;
    return 40000 ether;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // Hardcode the Sanctuary's approval so that users don't have to waste gas approving
    if (_msgSender() != address(sanctuary))
      require(
        _isApprovedOrOwner(_msgSender(), tokenId),
        "Not owner nor approved"
      );
    _transfer(from, to, tokenId);
  }

  /** INTERNAL */

  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  /**
   * generates traits for a specific token, checking to make sure it's unique
   * @param tokenId the id of the token to generate traits for
   * @param seed a pseudorandom 256 bit number to derive traits from
   * @return t - a struct of traits for the given token ID
   */
  function generate(uint256 tokenId, uint256 seed)
    internal
    returns (AngelHuman memory t)
  {
    t = selectTraits(seed);
    tokenTraits[tokenId] = t;
    return t;
  }

  function selectTraits(uint256 seed)
    internal
    view
    returns (AngelHuman memory t)
  {
    t.human = (seed & 0xFFFF) % 10 != 0;
    seed >>= 16;
    if (t.human) {
      t.angelicIndex = 0;
      return t;
    }

    uint16 randomAngelicValue = uint16(seed & 0xFFFF) % 10;
    if (randomAngelicValue == 0) {
      t.angelicIndex = 8;
    } else if (randomAngelicValue == 1 || randomAngelicValue == 2) {
      t.angelicIndex = 7;
    } else if (
      randomAngelicValue == 3 ||
      randomAngelicValue == 4 ||
      randomAngelicValue == 5
    ) {
      t.angelicIndex = 6;
    } else {
      t.angelicIndex = 5;
    }
  }

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 75% have a 10% chance to be given to a random staked angel
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Angel thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = sanctuary.randomAngelOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /**
   * generates a pseudorandom number
   * @param seed a value ensure different outcomes for different sources in the same block
   * @return a pseudorandom value
   */
  function random(uint256 seed) internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
          )
        )
      );
  }

  /** READ */

  function isEligible(bytes32[] calldata proof, uint256 _number)
    public
    view
    returns (uint16 eligibility)
  {
    bytes32 leaf = keccak256(abi.encodePacked(_number, msg.sender));
    if (MerkleProof.verify(proof, rootWL, leaf)) return 1;
    return 0;
  }

  function getTokenTraits(uint256 tokenId)
    external
    view
    override
    returns (AngelHuman memory)
  {
    return tokenTraits[tokenId];
  }

  function getPaidTokens() external view override returns (uint256) {
    return PAID_TOKENS;
  }

  /** ADMIN */

  /**
   * called after deployment so that the contract can get random angel thieves
   * @param _sanctuary the address of the Sanctuary
   */
  function setSanctuary(address _sanctuary) external onlyOwner {
    sanctuary = ISanctuary(_sanctuary);
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setRoot(bytes32 _rootWL) external onlyOwner {
    rootWL = _rootWL;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(addressOne, (balance * 30) / 100);
    _withdraw(addressTwo, (balance * 30) / 100);
    _withdraw(addressThree, (balance * 30) / 100);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }

  /**
   * updates the number of tokens for sale
   */
  function setPaidTokens(uint256 _paidTokens) external onlyOwner {
    PAID_TOKENS = _paidTokens;
  }

  function setNumFreeMint(uint256 _freeMint) external onlyOwner {
    freeMint = _freeMint;
  }

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    if (_setPauseMint) {
      pauseMint = true;
    } else {
      pauseMint = false;
    }
  }

  function setPausePreMint(bool _setPausePreMint) external onlyOwner {
    if (_setPausePreMint) {
      pausePreMint = true;
    } else {
      pausePreMint = false;
    }
  }

  /** RENDER */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "DNE");

    string memory currentBaseURI = _baseURI();

    return (
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : ""
    );
  }
}
