//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./IApeNFT.sol";
import "./INFTDrip.sol";

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./BabelGenesisMetadataImplementation.sol";
import "./BabelConstant.sol";

contract BabelGenesisImplementation is BabelConstant, ERC721Upgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, IApeNFT {

  using SafeMathUpgradeable for uint256;
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint256 public nextId;

  address public burner;
  address public marketContract;
  address public babelGenesisDrip;  // Contract that drips governance token to user
  address public babelGenesisMetadata; // This contract is not really needed to be linked
  address public babelToken;

  string public contractURI;

  modifier onlyMarket() {
    require(msg.sender == marketContract, "sender is not market");
    _;
  }

  modifier onlyNFTOwner(uint256 id) {
    require(msg.sender == ownerOf(id), "Caller is not the owner of NFT");
    _;
  }

  function initialize(string memory _name, string memory _symbol, address _drip, address _metadata, address _babel) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();

    burner = msg.sender;
    babelGenesisDrip = _drip;
    babelGenesisMetadata = _metadata;
    babelToken = _babel;

    // 7 reserved apes for activities
    _safeMint(msg.sender, 98);
    _safeMint(msg.sender, 97);
    _safeMint(msg.sender, 96);
    _safeMint(msg.sender, 95);
    _safeMint(msg.sender, 94);
    _safeMint(msg.sender, 93);
    _safeMint(msg.sender, 92);

    // 0x0ape, this is counted outside of the 98 Genesis Apes
    _safeMint(msg.sender, 0);

    // the "nextId" should always be either invalid or taken
    nextId = 92;
  }

  function setBurner(address _newBurner) public onlyOwner {
    burner = _newBurner;
  }

  /*
    burner is used to update or atomically burn an NFT here and mint another NFT on other contracts.
    burner can only burn the NFTs it owns.
  */
  function burn(uint256 tokenId) public override onlyNFTOwner(tokenId) {
    require(msg.sender == burner, "only the burner can burn NFTs");
    INFTDrip(babelGenesisDrip).updateAllRewards(burner);
    super.burn(tokenId);
  }

  // Sets the contract that can mint this NFT
  function setMarket(address _newMarket) public onlyOwner {
    marketContract = _newMarket;
  }

  function setDrip(address _newDrip) public onlyOwner {
    babelGenesisDrip = _newDrip;
  }

  function withdrawTo(address payable target) public onlyOwner {
    (target).call{value: address(this).balance}("");
  }

  // Give the owner the ability to transfer ERC20 out of the contract
  function withdrawERC20To(address payable target, address token, uint256 amount) public onlyOwner{
    IERC20Upgradeable(token).safeTransfer(target, amount);
  }

  // Rejects minting with specified id.
  // The distribution of Genesis Apes are randomized, thus it doesn't
  // make sense to specify it.
  function mintSpecific(address, uint256) public onlyMarket payable override {
    revert("This NFT doesn't support specified mint.");
  }

  function quoteSpecific(uint256) public view override returns (uint256) {
    revert("This NFT doesn't support specified mint.");
  }

  // Market transfers the received ether to this contract
  function mintBatch(address target, uint256 num) public onlyMarket payable override {
    require(num > 0, "Should be buying more than one");
    require(num < nextId, "Trying to buy more than available");
    require(num <= MAX_ONE_BUY, "Trying to buy too many in one order");
    uint256 startId = nextId - num;
    require(msg.value == quote(num), "payment does not match");
    require(block.timestamp > SALE_TIMESTAMP, "Sale hasn't started yet");

    for(uint256 i = 0 ; i < num ; i++) {
      _safeMint(target, startId.add(i));
    }
    IERC20Upgradeable(babelToken).transfer(target, num.mul(BabelGenesisMetadataImplementation(babelGenesisMetadata).NAME_CHANGE_PRICE()));
    nextId = startId;

    BabelGenesisMetadataImplementation(babelGenesisMetadata).checkUpdateStartingIndexBlock(
      (totalSupply() >= MAX_GENESIS) // true if sold out
    );
  }

  function quote(uint256 num) public view override returns(uint256) {
    require(num <= 2, "cannot buy more than 2 items");
    require(num > 0, "cannot quote 0 purchase");
    require(nextId > num, "quote: Sold out");

    if(nextId.sub(num) == 1) {  // if the purchase touches the special #1
      if(num == 2)
        return 7.5 ether;
      else
        return 7 ether;
    } else {
      return 0.5 ether * num;
    }
  }

  function validOrder(address, uint256 num) public view override returns(bool) {
    return
      (nextId > num) // Not sold out yet
        && (MAX_ONE_BUY >= num);      // cannot buy more than MAX_ONE_BUY in one tx.
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return BabelGenesisMetadataImplementation(babelGenesisMetadata).tokenURI(tokenId);
  }

  // overriding _mint should reflect on _safeMint as well
  function _mint(address to, uint256 tokenId) internal virtual override {
    INFTDrip(babelGenesisDrip).updateAllRewards(to);
    super._mint(to, tokenId);
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    // transfer is staking as `to`, withdrawing as `from`
    INFTDrip(babelGenesisDrip).updateAllRewards(to);
    INFTDrip(babelGenesisDrip).updateAllRewards(from);
    super._transfer(from, to, tokenId);
  }

  function setContractURI(string memory _contractURI) onlyOwner public {
    contractURI = _contractURI;
  }
}