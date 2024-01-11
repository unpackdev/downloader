// SPDX-License-Identifier: UNLICENSED

// lccclkN........WOlccclOW....W0occccccclOW......WKoldON......NkccccxXWNkccccccccccxN.......N0dlcccccckN....W0occcccccc
// dccccdX........NxccccoKW....W0occccccclOW......WKocclkN.....NkccccxX.NkccccccccccxN......NOlcccccccckN....W0occcccccc
// klccco0W.......KdccccxN..WNX0OkkkkkkkkkKW.WX000Okoccco0W....NkccccxXWWKkxolodxkkk0WWX00000OkkkkkkkkkKW.WNX0Okkkkkkkkk
// 0occcckN......WOlccclOW.N0dllxN...........NklcccodlcccxX....NkccccxXW..WNxlld0NW...WOlcccdKW..........N0xllxXW.......
// XxccccdK......NkccccoKWWOlccckN...........Nkccccdkocccl0W...NklcccxX....NxccclOW...WOlcccdX..........W0occcxN........
// WOlcccl0W.....KdccccxXWNxcccckN...........NkccccdKklcccxX...NkccccxX....NxccccxN...WOlcccdX..........NkccccxN........
// WKocccckN....WOlccclOW.N0xxxxk0KKKKKKKKN..NkccccxXKdccclOWWWNkccccxX....NxccccxN...WOlcccdX..........W0xxxdk0KKKKKKKK
// .XxccccdK....NxccccoKW..WWWWW0ollllllloOW.NkccccxXNOlcccdKWWNkccccxX....NxccccxN...WOlcccdK...........WWWWW0ollllllll
// .WOlccclOW...KdccccxN.......W0occccccclOW.NkccccxXWXdccclONNNkccccxX....NxccccxN...WOlcccdX...............W0occcccccc
// .WKoccccxN..WOlccclOW..WX0000OkxxxxxxxkKW.NkccccxX.WOlcccdkKNkccccxX....NxccccxN...WOlcccdX..........WX0000Okxxxxxxxx
// ..NxccccdKW.NkccccoK...NxccclxNWWWWWW.....NkccccxX.WXxcccllkKklcccxX....NxccccxN...WOlcccdX..........NklcccxXWWWWWWWW
// ..WOlccclOWWKdccccxX...NkccccxN...........NkccccxX..W0lccccoOxlcccxX....NklcccxN...WOlcccdX..........WklcccxX........
// ...KdccccxNWOlccclON...WKxlccxN...........NkccccxX...XxcccclddlcccxX....WXxlccxN...WOlcccdX...........XxlccxN........
// ...NxccccoKXxccccoKW....WN0kxkKXXXXXXXXN..NkccccxX...W0occccldddddON.WNXXK0xold0XNWW0xdddk0KXXXXXXXXNWWN0kxkKXXXXXXXX
// ...WOlccclk0dccccxX........WW0olllllllo0W.NkccccxX....NkcccclONWWWW..NOllllllccllkN.WWWWWXxlllllllllOW...WW0dllllllll
// ...WKdccccdxoccclOW.........W0occccccclOW.NkccccxX....WXxlcclOW......NkccccccccccxN......WKdlccccccckN....W0occcccccc
// ....Nxcccclolccco0W.........W0occccccclOW.NkccccxX.....WXkdooOW......NkccccccccccxN.......WXkolccccckN....W0occcccccc
// ███╗   ███╗ █████╗ ██████╗ ███████╗    ██╗    ██╗██╗████████╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝    ██║    ██║██║╚══██╔══╝██║  ██║    ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗      ██║ █╗ ██║██║   ██║   ███████║    ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝      ██║███╗██║██║   ██║   ██╔══██║    ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗    ╚███╔███╔╝██║   ██║   ██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝     ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.13;

error ExceedsMaxPerWallet();
error InsufficientPayment();
error TokensAlreadyClaimed();
error TransferRestricted();
error TransferAddressNotSet();

import "./AccessControl.sol";
import "./Claimable.sol";
import "./EIP712Common.sol";
import "./Toggleable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

import "./Base64.sol";
import "./Utils.sol";

contract Venice is ERC721A, ERC721AQueryable, Ownable, AccessControl, Toggleable, EIP712Common, Claimable {

  uint256 public PRICE;
  uint256 public WHITELIST_PRICE;
  uint256 public MAX_PER_WALLET;

  PaymentSplitter private _splitter;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _assetUri,
    address[] memory _payees,
    uint256[] memory _shares,
    uint256 _tokenPrice) ERC721A(_tokenName, _tokenSymbol) {
    PRICE = _tokenPrice;
    WHITELIST_PRICE = _tokenPrice;
    MAX_PER_WALLET = 1;

    _splitter = new PaymentSplitter(_payees, _shares);
  }


  /** MINTING **/

  function mint(uint256 _count) external payable noContracts requireActiveSale {
    if(msg.value < PRICE * _count) revert InsufficientPayment();
    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);

    payable(_splitter).transfer(msg.value);
  }

  function whitelistMint(uint256 _count, bytes calldata _signature) external payable requiresWhitelist(_signature) noContracts requireActiveWhitelist {
    if(msg.value < WHITELIST_PRICE * _count) revert InsufficientPayment();
    if(_numberMinted(msg.sender) + _count > MAX_PER_WALLET) revert ExceedsMaxPerWallet();

    _mint(msg.sender, _count);

    payable(_splitter).transfer(msg.value);
  }

  function ownerMint(uint256 _count, address _recipient) external onlyOwner() {
    _mint(_recipient, _count);
  }

  /** ADMIN **/

  function setPrice(uint256 _tokenPrice) external onlyOwner {
    PRICE = _tokenPrice;
  }

  function setWhitelistPrice(uint256 _tokenPrice) external onlyOwner {
    WHITELIST_PRICE = _tokenPrice;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    MAX_PER_WALLET = _maxPerWallet;
  }

  // Burn function to be used by admins if tokenholder breaches terms of use
  function burn(uint256 _tokenId) external onlyOwner {
    _burn(_tokenId, false);
  }

  /** MINTING LIMITS **/


  function allowedMintCount(address _minter) public view returns (uint256) {
    return MAX_PER_WALLET - _numberMinted(_minter);
  }

  /** Whitelist **/

  function checkWhitelist(bytes calldata _signature) public view requiresWhitelist(_signature) returns (bool) {
    return true;
  }

  /** Claiming **/

  function claimTokens(uint256 _count, bytes calldata _signature) external payable requireActiveClaiming requiresClaim(_signature, _count) noContracts {
    if (hasUnclaimedTokens(msg.sender)) {
      updateClaimCount(msg.sender, _count);
    } else {
      revert TokensAlreadyClaimed();
    }

    _mint(msg.sender, _count);
  }

  /** URI HANDLING **/

  string private animationURI = "ipfs://QmSs1noMFV7ARSNeby5iUuNQVNgDbbSQsPPbFPMe1yih4a";
  string private imageURI = "ipfs://QmdZfb55suPbujN89i43a6kUeWi4A5dagQrqwfdK7x35oA";
  string private tokenName = "Genesis Pass";
  string private tokenDescription = "";

  function getImageURI() public view returns (string memory) {
    return imageURI;
  }

  function getAnimationURI() public view returns (string memory) {
    return animationURI;
  }

  function getTokenName() public view returns (string memory) {
    return tokenName;
  }

  function getTokenDescription() public view returns (string memory) {
    return tokenDescription;
  }

  function setTokenName(string memory _tokenName) external onlyOwner {
    tokenName = _tokenName;
  }

  function setTokenDescription(string memory _tokenDescription) external onlyOwner {
    tokenDescription = _tokenDescription;
  }

  function setImageURI(string memory _imageURI) external onlyOwner {
    imageURI = _imageURI;
  }

  function setAnimationURI(string memory _animationURI) external onlyOwner {
    animationURI = _animationURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return imageURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name": "', 
                tokenName,
                '", "description": "',
                tokenDescription,
                '", "image":"',
                imageURI,
                '", "animation_url":"',
                animationURI,
                '", "attributes": [ { "trait_type": "Expiration Date", "display_type": "date", "value": "',
                Utils.uintToString(_ownershipOf(tokenId).startTimestamp + 365 days),
                '"}]}'
              )
            )
          )
        )
      );
  }

  /** TRANSFERS **/
  address private transferAddress;

  bool public transfersActive = false;

  function flipTransferState() external onlyOwner {
    transfersActive = !transfersActive;
  }

  function setTransferAddress(address _transferAddress) public onlyOwner {
    transferAddress = _transferAddress;
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override(ERC721A, IERC721) {
    if(!transfersActive && transferAddress == address(0)) revert TransferAddressNotSet();
    if(!transfersActive && (msg.sender != transferAddress)) revert TransferRestricted();

    super.safeTransferFrom(from, to, tokenId, _data);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721A, IERC721) {
    if(!transfersActive && transferAddress == address(0)) revert TransferAddressNotSet();
    if(!transfersActive && (msg.sender != transferAddress)) revert TransferRestricted();

    super.safeTransferFrom(from, to, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721A, IERC721) {
    if(!transfersActive && transferAddress == address(0)) revert TransferAddressNotSet();
    if(!transfersActive && (msg.sender != transferAddress)) revert TransferRestricted();

    super.transferFrom(from, to, tokenId);
  }

  /** PAYOUT **/

  function release(address payable _account) public virtual onlyOwner {
    _splitter.release(_account);
  }
}
