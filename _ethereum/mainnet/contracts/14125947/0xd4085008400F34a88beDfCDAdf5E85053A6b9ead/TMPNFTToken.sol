// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Tradable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

// !!!!!
// We are using uint16 instead of a higher type
// Because we know we are going to have a low amount of mintable tokens
// If you are going to have more than 65536 tokens, you should use a higher type

contract TMPNFTToken is ERC721Tradable, EIP712 {
  uint256 public price = 0.04369 ether;

  uint16 public reserved;
  uint16 public maxTokens;

  string private _localBaseURI;

  bool public paused = true;
  bool public isMetadataFrozen = false;
  bool public isPublicMintEnabled = false;

  address private whitelistVerifier;
  mapping(uint => bool) private whitelistNonce;
  mapping(address => uint) private mintedTokensFromAddresses;
  mapping(address => uint16) private giveawayTokens;

  bytes32 constant MINT_DATA_TYPEHASH = keccak256("MintData(address minter,uint16 amount,uint256 price,uint256 nonce)");

  constructor(
    string memory baseURI,
    uint16 tokens,
    uint16 reservedTokens,
    address _openSeaProxyRegistryAddress,
    address _whitelistVerifier
  ) ERC721Tradable("The Meta Portal NFT", "TMPNFT", _openSeaProxyRegistryAddress) EIP712("TMPNFTToken", "v1") {
    _localBaseURI = baseURI;
    maxTokens = tokens;
    reserved = reservedTokens;
    whitelistVerifier = _whitelistVerifier;
  }

  modifier isPublicMint() {
    require(isPublicMintEnabled, "TMPNFTToken: You are not allowed to mint!");

    _;
  }

  modifier isMintingNotPaused() {
    require(!paused, "Minting process is paused!");

    _;
  }

  modifier isMetadataNotFrozen() {
    require(!isMetadataFrozen, "Metadata is frozen!");

    _;
  }

  function mint(uint16 amount) public payable isPublicMint isMintingNotPaused {
    address msgSenderAddress = address(msg.sender);

    _mintValidation(amount);
    _doMint(amount);
  }

  function whitelistMint(uint16 amount, uint pricePerNFT, uint nonce, bytes calldata signature) public payable isMintingNotPaused {
    require(whitelistNonce[nonce] == false, "TMPNFTToken: Already minted!");

    address msgSenderAddress = address(msg.sender);
    bytes32 digest = _hashTypedDataV4(
      keccak256(abi.encode(
        MINT_DATA_TYPEHASH,
        msgSenderAddress,
        amount,
        pricePerNFT,
        nonce
      ))
    );
    address signer = ECDSA.recover(digest, signature);

    require(signer == whitelistVerifier, "TMPNFTToken: You are not allowed to mint!");

    whitelistNonce[nonce] = true;

    _mintValidation(amount, pricePerNFT, 4);
    _doMint(amount);
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function enablePublicMint() public onlyOwner {
    isPublicMintEnabled = true;
  }

  function disablePublicMint() public onlyOwner {
    isPublicMintEnabled = false;
  }

  function retrieveAllOwnersOfNft() public view onlyOwner returns (address[] memory) {
    uint256 supply = totalSupply();

    // create a new array called owners with length to the max supply of tokens
    // since _ownedTokens is a mapping we cannot know the length of it
    // so our best guess is to use the totalSupply
    // our worst case scenario with this is the we have 5000 people and 10000 tokens
    // and we will have duplicate adresses, but we can sort them out once we retrieve them
    address[] memory owners = new address[](supply);

    for (uint256 i = 1; i <= supply; i++) {
      owners[i - 1] = ownerOf(i);
    }

    return owners;
  }

  function giveTokensToWithoutWithdrawPattern(address to, uint16 amount) public onlyOwner {
    require(amount <= reserved, "No reserved tokens left!");

    reserved -= amount;

    uint256 currentAvailableTokenId = _getCurrentAvailableTokenId();

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, currentAvailableTokenId + i);
    }
  }

  function giveTokensTo(address to, uint16 amount) public onlyOwner {
    require(amount <= reserved, "No reserved tokens left!");

    giveawayTokens[to] = amount;
  }

  function mintTokenFromGiveaway() external {
    uint16 tokensToGiveaway = giveawayTokens[msg.sender];

    require(tokensToGiveaway > 0, "You do not have tokens given away for you!");
    require(reserved >= tokensToGiveaway, "It seems no tokens are reserved for you!");

    // remove the giveaway tokens for the user
    giveawayTokens[msg.sender] = 0;
    reserved -= tokensToGiveaway;

    uint256 currentAvailableTokenId = _getCurrentAvailableTokenId();

    for (uint256 i = 0; i < tokensToGiveaway; i++) {
      _safeMint(msg.sender, currentAvailableTokenId + i);
    }
  }

  function freezeMetadata() public onlyOwner {
    isMetadataFrozen = true;
  }

  function pauseMint() public onlyOwner {
    paused = true;
  }

  function unpauseMint() public onlyOwner {
    paused = false;
  }

  function setReserved(uint16 amount) public onlyOwner {
    reserved = amount;
  }

  function withdrawAllTo(address withdrawAccount) public onlyOwner {
    require(withdrawAccount != address(0), "Withdraw account cannot be 0x0");

    (bool os,) = payable(withdrawAccount).call{value : address(this).balance}("");
    require(os);
  }

  function maxSupply() public view override returns (uint256) {
    return uint256(maxTokens);
  }

  function setBaseURI(string memory uri) public onlyOwner isMetadataNotFrozen {
    _localBaseURI = uri;
  }

  function setWhitelistVerifier(address _verifier) external onlyOwner {
    whitelistVerifier = _verifier;
  }

  function canMintWithNonce(uint nonce) external returns (bool) {
    // if the nonce returns false then we can mint with it
    return !whitelistNonce[nonce];
  }

  function mintedTokensBy(address _minter) public view returns (uint256) {
    return mintedTokensFromAddresses[_minter];
  }

  function _baseURI() internal view override returns (string memory) {
    return _localBaseURI;
  }

  function _getCurrentAvailableTokenId() internal view returns (uint256) {
    return totalSupply() + 1;
  }

  function _mintValidation(uint16 amount) internal {
    _mintValidation(amount, price, 2);
  }

  function _mintValidation(uint16 amount, uint pricePerNft) internal {
    _mintValidation(amount, pricePerNft, 2);
  }

  function _mintValidation(uint16 amount, uint pricePerNft, uint maxCanHaveMintable) internal {
    address msgSenderAddress = address(msg.sender);
    uint256 supply = totalSupply();

    require(amount > 0, "The amount must be greater than 0");
    // Here we ensure that we wouldn't have an overflow down the line, as our max tokens is going to be less than the overflow threshold
    require(amount <= maxTokens, "You cannot mint more than the max amount of tokens!");
    require(supply + amount <= maxTokens - reserved, "Amount will exceed supply");

    uint totalPrice = pricePerNft * amount;

    require(mintedTokensBy(msgSenderAddress) + amount <= maxCanHaveMintable, 'You cannot mint more tokens!');
    require(msg.value >= totalPrice, 'Insufficient ether sent!');
  }

  function _doMint(uint16 amount) internal {
    address msgSenderAddress = address(msg.sender);
    uint256 currentAvailableTokenId = _getCurrentAvailableTokenId();

    mintedTokensFromAddresses[msgSenderAddress] += amount;

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msgSenderAddress, currentAvailableTokenId + i);
    }
  }
}
