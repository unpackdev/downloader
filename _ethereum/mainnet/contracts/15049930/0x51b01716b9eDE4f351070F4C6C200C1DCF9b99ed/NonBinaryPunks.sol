// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC165Storage.sol";
import "./IERC2981.sol";

// coded by Crypto Tester: https://cryptotester.info/ https://twitter.com/crypto_tester_

contract NonBinaryPunks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981, ERC165Storage {

  uint256 public adminMintCount;
  uint256 public airdropMintCount;
  uint256 public ownerMintCount;
  uint256 public whitelistMintCount;
  uint256 public mintCount;
  uint256 public price;
  uint256 public erc20Decimals;
  uint256 public erc20Price;
  uint256 public maxNftsPerTransaction;
  uint256 public supply;
  uint256 public disableMintTrigger;
  uint256 public royaltyFee;
  uint256 public maxOwnerMint;
  address public paymentAddress;
  address public royaltyAddress;
  bool public publicMintingEnabled;
  bool public whitelistMintingEnabled;
  bool public nativePaymentEnabled;
  bool public erc20PaymentEnabled;
  address public erc20Address;
  string public baseUrl;
  mapping(address => bool) public whitelisted;
  enum MintType { PUBLIC, WHITELIST, AIRDROP, ADMIN }

  mapping(uint256 => uint256) private tokenMatrix;
  uint256 public startFrom;
  uint256 public mintBlockSize;
  uint256 public mintBlockNr;
  uint256 public mintOffset;
  uint256 public lastMintBlockNr;
  uint256 public mintBlockReminder;

  event PublicMint(address addr, uint256 tokenId);
  event WhitelistMint(address addr, uint256 tokenId);
  event AirdropMint(address addr, uint256 tokenId);
  event AdminMint(address addr, uint256 tokenId);
  event RandomizationUpdate(uint256 mintCount, uint256 startFrom);
  event UpdateBaseUrl(string newBaseUrl);
  event UpdateTokenURI(uint256 id, string newTokenURI);
  event RemoveFromWhitelist(address addr);
  event UintPropertyChange(string param, uint256 value);
  event BoolPropertyChange(string param, bool value);
  event AddressPropertyChange(string param, address value);

  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor() ERC721("Non-Binary Punks", "NBP") {
    adminMintCount = 0;
    airdropMintCount = 0;
    ownerMintCount = 0;
    whitelistMintCount = 0;
    mintCount = 0;
    price = 1 * 10**18;
    erc20Decimals = 6;
    erc20Price = 10 * 10**erc20Decimals;
    maxNftsPerTransaction = 20;
    supply = 10000;
    disableMintTrigger = 10000;
    royaltyFee = 6;
    maxOwnerMint = 300;
    paymentAddress = address(0);
    royaltyAddress = address(0);
    erc20Address = address(0);
    publicMintingEnabled = false;
    whitelistMintingEnabled = false;
    nativePaymentEnabled = true;
    erc20PaymentEnabled = true;
    baseUrl = "https://ipfs.io/ipfs/bafybeifek7tboasgmwnsj5ytnktl3eecdadg7vwoeur4bamdfyge3xvolu/";
    startFrom = 0;
    mintBlockSize = 200;
    mintBlockNr = 1;
    mintOffset = 0;
    setLastMintBlockNrAndReminder();

    // ERC721 interface
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    // Royalties interface
    _registerInterface(_INTERFACE_ID_ERC2981);
  }

  function whitelistMint(uint256 quantity) external payable {
    require(whitelistMintingEnabled, "Whitelist minting is disabled");
    require(whitelisted[msg.sender], "Your address is not whitelisted");
    _publicMint(quantity, MintType.WHITELIST);
  }

  function erc20WhitelistMint(IERC20 token, uint256 amount, uint256 quantity) external {
    require(whitelistMintingEnabled, "Whitelist minting is disabled");
    require(whitelisted[msg.sender], "Your address is not whitelisted");
    _erc20Mint(token, amount, quantity, MintType.WHITELIST);
  }  

  function publicMint(uint256 quantity) external payable {
    require(!whitelistMintingEnabled, "Only whitelisted addresses can mint at the moment");
    require(publicMintingEnabled, "Public minting is disabled");
    _publicMint(quantity, MintType.PUBLIC);
  }

  function erc20PublicMint(IERC20 token, uint256 amount, uint256 quantity) external {
    require(!whitelistMintingEnabled, "Only whitelisted addresses can mint at the moment");
    require(publicMintingEnabled, "Public minting is disabled");
    _erc20Mint(token, amount, quantity, MintType.PUBLIC);
  }

  function _erc20Mint(IERC20 token, uint256 amount, uint256 quantity, MintType mintType) private {
    require(erc20PaymentEnabled, "Paying in ERC20 token is disabled");
    require(address(token) == erc20Address, "You are using the wrong ERC20 token");
    require(amount == erc20Price * quantity, "You are not sending the necessary amount");
    _doMint(quantity, msg.sender, mintType);
    token.transferFrom(msg.sender, paymentAddress, amount);
  }

  function _publicMint(uint256 quantity, MintType mintType) private {
    require(nativePaymentEnabled, "Paying in native coin is disabled");
    require(msg.value == price * quantity, "You are not sending the necessary amount");
    require(mintCount + quantity <= disableMintTrigger, "You are trying to mint more NFTs than allowed in the disableMintTrigger property");
    _doMint(quantity, msg.sender, mintType);
    payable(paymentAddress).transfer(msg.value);
  }

  function adminMint(uint256 quantity, address to) external onlyOwner {
    _adminMint(quantity, to, MintType.ADMIN);
  }

  function batchAirdrop(address [] calldata addresses) external onlyOwner {
    require(addresses.length <= maxNftsPerTransaction, "You are trying to mint more NFTs then allowed in the maxNftsPerTransaction property");
    for (uint256 i = 0; i < addresses.length; i++) {
      _adminMint(1, addresses[i], MintType.AIRDROP);
    }
  }

  function airdropMint(uint256 quantity, address to) external onlyOwner {
    _adminMint(quantity, to, MintType.AIRDROP);
  }

  function _adminMint(uint256 quantity, address to, MintType mintType) private onlyOwner {
    require(ownerMintCount + quantity <= maxOwnerMint, "You are trying to mint more NFTs than allowed in the maxOwnerMint property");
    _doMint(quantity, to, mintType);
  }

  function specificMint(uint256 tokenId, address to) external onlyOwner {
    uint256 maxIndex = mintBlockNr * mintBlockSize - mintCount - mintOffset;
    if (mintBlockNr == lastMintBlockNr + 1) {
      maxIndex = supply - mintCount;
    }
    tokenMatrix[tokenId] = maxIndex - 1;
    _mint(to, tokenId);
    mintCount++;
    adminMintCount++;
    ownerMintCount++;
    emit AdminMint(to, tokenId);
  }

  function getNextRandomTokenId() private returns (uint256) {
    uint256 maxIndex = mintBlockNr * mintBlockSize - mintCount - mintOffset;
    if (mintBlockNr == lastMintBlockNr + 1) {
      maxIndex = supply - mintCount;
    }
    uint256 random = uint256(
      keccak256(
        abi.encodePacked(
          msg.sender,
          block.coinbase,
          block.difficulty,
          block.gaslimit,
          block.timestamp
        )
      )
    ) % maxIndex;

    uint256 randomNr = 0;
    if (tokenMatrix[random] == 0) {
      randomNr = random;
    } else {
      randomNr = tokenMatrix[random];
    }

    if (tokenMatrix[maxIndex - 1] == 0) {
      tokenMatrix[random] = maxIndex - 1;
    } else {
      tokenMatrix[random] = tokenMatrix[maxIndex - 1];
    }

    return randomNr + startFrom;
  }

  function handleMintBlock() private {
    if (mintCount % mintBlockSize == 0) {
      mintBlockNr++;
      startFrom = (mintBlockNr - 1) * mintBlockSize;
      emit RandomizationUpdate(mintCount, startFrom);
      for (uint256 i = 0; i < mintBlockSize; i++){
        tokenMatrix[i] = 0;
      }
    }
  }

  function changeMintBlock(uint256 _mintBlockNr) external onlyOwner {
    mintBlockNr = _mintBlockNr;
    startFrom = (mintBlockNr - 1) * mintBlockSize;
  }

  function _doMint(uint256 quantity, address to, MintType mintType) private {
    require(mintCount + quantity <= supply, "You are trying to mint more NFTs than the maximum supply");
    require(quantity <= maxNftsPerTransaction, "You are trying to mint more NFTs then allowed in the maxNftsPerTransaction property");
    for (uint256 i = 0; i < quantity; i++) {
      uint256 tokenId = getNextRandomTokenId();
      _mint(to, tokenId);
      _setTokenURI(tokenId, _endOfURI(tokenId));
      mintCount++;
      handleMintBlock();

      if (mintType == MintType.PUBLIC) {
        emit PublicMint(to, tokenId);
      } else if (mintType == MintType.WHITELIST) {
        whitelistMintCount++;
        emit WhitelistMint(to, tokenId);
      } else if (mintType == MintType.ADMIN) {
        emit AdminMint(to, tokenId);
      } else if (mintType == MintType.AIRDROP) {
        emit AirdropMint(to, tokenId);
      }

      if (mintType == MintType.ADMIN) {
        adminMintCount++;
        ownerMintCount++;
      }

      if (mintType == MintType.AIRDROP) {
        airdropMintCount++;
        ownerMintCount++;
      }

      if ((mintCount == supply) || ((mintType == MintType.PUBLIC || mintType == MintType.WHITELIST) && mintCount == disableMintTrigger)) {
        publicMintingEnabled = false;
        emit BoolPropertyChange("publicMintingEnabled", publicMintingEnabled);
        break;
      }
    }
  }

  function setLastMintBlockNrAndReminder() public onlyOwner {
    lastMintBlockNr = supply / mintBlockSize;
    mintBlockReminder = supply % mintBlockSize;
  }

  function changePublicMintingStatus(bool value) external onlyOwner {
    publicMintingEnabled = value;
    emit BoolPropertyChange("publicMintingEnabled", publicMintingEnabled);
  }

  function changeWhitelistMintingStatus(bool value) external onlyOwner {
    whitelistMintingEnabled = value;
    emit BoolPropertyChange("whitelistMintingEnabled", whitelistMintingEnabled);
  }

  function changeNativePaymentStatus(bool value) external onlyOwner {
    nativePaymentEnabled = value;
    emit BoolPropertyChange("nativePaymentEnabled", nativePaymentEnabled);
  }

  function changeErc20PaymentStatus(bool value) external onlyOwner {
    erc20PaymentEnabled = value;
    emit BoolPropertyChange("erc20PaymentEnabled", erc20PaymentEnabled);
  }

  function addToWhitelist(address addr) external onlyOwner {
    whitelisted[addr] = true;
  }

  function removeFromWhitelist(address addr) external onlyOwner {
    whitelisted[addr] = false;
    emit RemoveFromWhitelist(addr);
  }

  function addWhitelistBatch(address [] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelisted[addresses[i]] = true;
    }
  }

  function removeWhitelistBatch(address [] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelisted[addresses[i]] = false;
    }
  }

  function setMaxOwnerMint(uint256 value) external onlyOwner {
    maxOwnerMint = value;
    emit UintPropertyChange("maxOwnerMint", value);
  }

  function setMaxNftsPerTransaction(uint256 value) external onlyOwner {
    maxNftsPerTransaction = value;
    emit UintPropertyChange("maxNftsPerTransaction", value);
  }

  function setSupply(uint256 value) external onlyOwner {
    require(value >= mintCount, "supply must be >= mintCount");
    supply = value;
    setLastMintBlockNrAndReminder();
    emit UintPropertyChange("supply", value);
  }

  function setMintBlockSize(uint256 value) external onlyOwner {
    mintBlockSize = value;
    emit UintPropertyChange("mintBlockSize", value);
  }

  function setMintOffset(uint256 value) external onlyOwner {
    mintOffset = value;
    emit UintPropertyChange("mintOffset", value);
  }

  function setDisableMintTrigger(uint256 value) external onlyOwner {
    disableMintTrigger = value;
    emit UintPropertyChange("disableMintTrigger", value);
  }

  function setPrice(uint256 priceInEth) external onlyOwner {
    price = priceInEth * 10**18;
    emit UintPropertyChange("price", price);
  }

  function setPriceInWei(uint256 priceInWei) external onlyOwner {
    price = priceInWei;
    emit UintPropertyChange("price", price);
  }

  function setErc20Price(uint256 priceInCoin) external onlyOwner {
    erc20Price = priceInCoin * 10**erc20Decimals;
    emit UintPropertyChange("erc20Price", erc20Price);
  }

  function setErc20PriceWithDecimals(uint256 value) external onlyOwner {
    erc20Price = value;
    emit UintPropertyChange("erc20Price", value);
  }

  function setErc20Decimals(uint256 value) external onlyOwner {
    erc20Decimals = value;
    emit UintPropertyChange("erc20Decimals", value);
  }

  function setErc20Address(address addr) external onlyOwner {
    erc20Address = addr;
    emit AddressPropertyChange("erc20Address", addr);
  }

  function setPaymentAddress(address addr) external onlyOwner {
    paymentAddress = addr;
    emit AddressPropertyChange("paymentAddress", addr);
  }

  function setRoyaltyAddress(address addr) external onlyOwner {
    royaltyAddress = addr;
    emit AddressPropertyChange("royaltyAddress", addr);
  }

  function setRoyaltyFee(uint256 feePercent) external onlyOwner {
    royaltyFee = feePercent;
    emit UintPropertyChange("royaltyFee", feePercent);
  }

  function setBaseUrl(string calldata url) external onlyOwner {
    baseUrl = url;
    emit UpdateBaseUrl(url);
  }

  function setTokenURI(uint256 id, string calldata dotJson) external onlyOwner {
    _setTokenURI(id, dotJson);
    emit UpdateTokenURI(id, dotJson);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseUrl;
  }

  function _uint2str(uint256 nr) internal pure returns (string memory str) {
    if (nr == 0) {
      return "0";
    }
    uint256 j = nr;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = nr;
    while (j != 0) {
      bstr[--k] = bytes1(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }

  function _endOfURI(uint256 nr) internal pure returns (string memory jsonString) {
    string memory number = _uint2str(nr);
    string memory dotJson = ".json";
    jsonString = string(abi.encodePacked(number, dotJson));
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function royaltyInfo(uint256, uint256 salePrice) external view override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyAddress;
    royaltyAmount = salePrice * royaltyFee / 100;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC165Storage, IERC165) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function sweepEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function sweepErc20(IERC20 token) external onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  receive() external payable {}

  fallback() external payable {}
}
