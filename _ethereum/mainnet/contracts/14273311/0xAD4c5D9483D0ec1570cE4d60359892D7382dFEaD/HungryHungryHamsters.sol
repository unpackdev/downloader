import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
 * @title HungryHungryHamsters contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HungryHungryHamsters is ERC721Enumerable, Ownable
{
  using SafeMath for uint256;

  string private constant HHH_PROVENANCE =                    "f243840ebf045f8e8e243abf889449a685b26b29a15a0c050791e17603274a8b";

  uint256 private constant WHITELIST_HAMSTER_PRICE =          0.0075 ether;

  uint256 private constant HAMSTER_PRICE =                    0.01 ether;

  uint256 private constant WHITELIST_HAMSTER_BALANCE_LIMIT =  3;

  uint256 private constant HAMSTER_PURCHASE_LIMIT =           10;

  uint256 private constant HAMSTER_RESERVE_AMOUNT =           10;

  uint256 private constant MAX_HAMSTERS =                     10000;

  uint256 private presaleStartTimestamp = 0;                                                      //Uninitialized

  uint256 private saleStartTimestamp = 0;                                                         //Uninitialized

  string private baseURI = "ipfs://bafybeigyedd6vxth54eb3ahdwjowuak7hivn2to7alahlirlcwe2gygnlq/"; //Unrevealed URI

  uint256 private lastMintIndex = 0;

  uint256 private lastMintAddressHash = 0;

  bool private saleIsActive = false;

  address[] private whitelist;

  constructor() ERC721("HungryHungryHamsters", "HHH") {}

  /*
   * Overloaded function
   */
  function _baseURI() internal view virtual override returns (string memory)
  {
    return baseURI;
  }

  /*
   * Checks if given address is in presale
   */
  function isWhitelisted(address userAddress) public view returns (bool)
  {
    for(uint256 i = 0; i < whitelist.length; i++)
    {
      if(whitelist[i] == userAddress)
      {
        return true;
      }
    }

    return false;
  }

  /*
   * Mints one hamster with random tokenID initialization
   */
  function mintHamster() private
  {
    uint256 mintIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, lastMintAddressHash, lastMintIndex))) % MAX_HAMSTERS;
    while(_exists(mintIndex))
    {
      mintIndex++;
    }

    lastMintAddressHash = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
    lastMintIndex = mintIndex;

    _safeMint(msg.sender, mintIndex);
  }

  /*
   * Mints Hamster(s)
   */
  function mintHamsters(uint256 numberOfTokens) public payable
  {
    require(saleIsActive, "Sale must be unpaused to mint Hamster(s)");
    require(block.timestamp > presaleStartTimestamp, "Wait until presale or open sale");
    require(numberOfTokens <= HAMSTER_PURCHASE_LIMIT, "Cannot mint that many Hamsters");
    require(totalSupply().add(numberOfTokens) <= MAX_HAMSTERS, "Purchase would exceed max supply of Hamsters");
    if(block.timestamp <= saleStartTimestamp)
    {
      /*
       * During Presale
       */
      require(isWhitelisted(msg.sender), "You are not in the presale");
      uint256 ownerHamsterBalance = balanceOf(msg.sender);
      require(numberOfTokens <= (WHITELIST_HAMSTER_BALANCE_LIMIT - ownerHamsterBalance), "Cannot mint that many Hamsters");
      require(WHITELIST_HAMSTER_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
    }
    else
    {
      /*
       * During Open Sale
       */
      require(HAMSTER_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
    }

    for(uint256 i = 0; i < numberOfTokens; i++)
    {
      mintHamster();
    }
  }

  /*
   * Set some Hamsters aside
   */
  function reserveHamsters() public onlyOwner
  {
    require(totalSupply().add(HAMSTER_RESERVE_AMOUNT) <= MAX_HAMSTERS, "Reservation would exceed max supply of Hamsters");

    for(uint256 i = 0; i < HAMSTER_RESERVE_AMOUNT; i++)
    {
      mintHamster();
    }
  }

  /*
   * Allows owner to withdraw balance on smart contract
   */
  function withdraw() public payable onlyOwner
  {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");
    (bool success, ) = (msg.sender).call{value: balance}("");
    require(success, "Transfer failed.");
  }

  /*
   * Sets baseURI
   */
  function setBaseURI(string memory newBaseURI) public onlyOwner
  {
    baseURI = newBaseURI;
  }

  /*
   * Sets presale and sale start timestamp
   */
  function setPresaleStartAndSaleStartTimestamps(uint256 newPresaleStartTimestamp, uint256 newSaleStartTimestamp) public onlyOwner
  {
    presaleStartTimestamp = newPresaleStartTimestamp;
    saleStartTimestamp = newSaleStartTimestamp;
  }

  /*
   * Pause sale if active, make active if paused
   */
  function flipSaleState() public onlyOwner
  {
    saleIsActive = !saleIsActive;
  }

  /*
   * Sets the presale addresses
   */
  function setWhitelist(address[] calldata newWhitelist) public onlyOwner
  {
    delete whitelist;
    whitelist = newWhitelist;
  }
}
