/*

'##::::'##::'#######::'##::::'##::'######::'########:::::'#######::'########::::'########:'########:'##::: ##::'######:::'##::::'##:
 ##:::: ##:'##.... ##: ##:::: ##:'##... ##: ##.....:::::'##.... ##: ##.....:::::... ##..:: ##.....:: ###:: ##:'##... ##:: ##:::: ##:
 ##:::: ##: ##:::: ##: ##:::: ##: ##:::..:: ##:::::::::: ##:::: ##: ##::::::::::::: ##:::: ##::::::: ####: ##: ##:::..::: ##:::: ##:
 #########: ##:::: ##: ##:::: ##:. ######:: ######:::::: ##:::: ##: ######::::::::: ##:::: ######::: ## ## ##: ##::'####: ##:::: ##:
 ##.... ##: ##:::: ##: ##:::: ##::..... ##: ##...::::::: ##:::: ##: ##...:::::::::: ##:::: ##...:::: ##. ####: ##::: ##:: ##:::: ##:
 ##:::: ##: ##:::: ##: ##:::: ##:'##::: ##: ##:::::::::: ##:::: ##: ##::::::::::::: ##:::: ##::::::: ##:. ###: ##::: ##:: ##:::: ##:
 ##:::: ##:. #######::. #######::. ######:: ########::::. #######:: ##::::::::::::: ##:::: ########: ##::. ##:. ######:::. #######::
..:::::..:::.......::::.......::::......:::........::::::.......:::..::::::::::::::..:::::........::..::::..:::......:::::.......:::

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract TheHouseOfTengu is ERC1155, ERC1155Burnable, ERC1155Supply, Ownable, Pausable, ReentrancyGuard {
  using Strings for uint256;

  address payable public immutable PAYABLE_ADDRESS;
  address public immutable the0n1ForceAddress;
  address public immutable theHaunted5Address;

  string public baseURI;

  uint256 public saleStartTimestamp;

  uint256 internal MINTABLE_TOKEN_START = 1;
  uint256 internal CHALLENGE_TOKEN_START = 50;
  uint256 internal MAX_TOKEN_COUNT = 56;
  uint256 internal SUPPLY_PER_MINTABLE_TOKEN = 30;
  uint256 internal SUPPLY_PER_CHALLENGE_TOKEN = 30;

  uint256[] internal mintableTokenCount = [30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30];
  uint256 internal randomSeed;

  uint256 public constant earlyMintPrice = 50000000000000000; // 0.05 ETH
  uint256 public constant publicMintPrice = 70000000000000000; // 0.07 ETH
  uint256 public walletLimit = 20;
  mapping(address => uint256) public earlyTokensMinted;
  mapping(address => uint256) public publicTokensMinted;

  constructor(
    string memory _baseURI,
    uint256 _saleStartTimestamp,
    uint256 _randomSeed,
    address _payableAddress,
    address _the0n1ForceAddress,
    address _theHaunted5Address
  ) ERC1155(_baseURI) {
    baseURI = _baseURI;
    saleStartTimestamp = _saleStartTimestamp;
    randomSeed = _randomSeed;
    PAYABLE_ADDRESS = payable(_payableAddress);
    the0n1ForceAddress = _the0n1ForceAddress;
    theHaunted5Address = _theHaunted5Address;
  }

  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

  function totalMinted() public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 1; i <= MAX_TOKEN_COUNT; i++) {
      total += totalSupply(i);
    }
    return total;
  }

  function totalMintableMinted() public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = MINTABLE_TOKEN_START; i < CHALLENGE_TOKEN_START; i++) {
      total += totalSupply(i);
    }
    return total;
  }

  /* Early Minting */

  bool public earlyMintingActive = true;

  function toggleEarlyMintingActive() public onlyOwner {
    earlyMintingActive = !earlyMintingActive;
  }

  /* Minting */

  function mint(uint256 _quantity, uint256 _hauntedTokenHeld) public payable whenNotPaused nonReentrant {
    require(block.timestamp >= saleStartTimestamp, "Sale has not started yet");
    require(_quantity <= 20, "Transaction limit is 20");

    if (earlyMintingActive) {
      require(earlyMintPrice * _quantity <= msg.value, "Not enough ETH");
      require(is0n1Holder() || holdsHauntedToken(_hauntedTokenHeld) || isHaunted5Holder(), "Must hold 0N1 or Haunted 5");
    } else {
      require(publicMintPrice * _quantity <= msg.value, "Not enough ETH");
    }

    if (walletLimit > 0) {
      if (earlyMintingActive) {
        require(earlyTokensMinted[msg.sender] + _quantity <= walletLimit, "Cannot exceed your wallet limit");
        earlyTokensMinted[msg.sender] += _quantity;
      } else {
        require(publicTokensMinted[msg.sender] + _quantity <= walletLimit, "Cannot exceed your wallet limit");
        publicTokensMinted[msg.sender] += _quantity;
      }
    }

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 seed = uint256(keccak256(abi.encodePacked(i, block.difficulty, block.timestamp, block.coinbase, msg.sender, randomSeed)));
      uint256 tokenIndex = seed % mintableSupply();
      uint256 tokenId = tokenIdAtIndex(tokenIndex) + MINTABLE_TOKEN_START;

      mintInternal(msg.sender, tokenId, 1);
    }
  }

  function ownerMint(address _to, uint256 _tokenId, uint256 _quantity) public onlyOwner {
    mintInternal(_to, _tokenId, _quantity);
  }

  function batchOwnerMint(address[] memory _addresses, uint256[] memory _tokenIds) public onlyOwner {
    require(_addresses.length == _tokenIds.length);

    for (uint256 i = 0; i < _addresses.length; i++) {
      mintInternal(_addresses[i], _tokenIds[i], 1);
    }
  }

  function firstM1nt(address _to, uint256 _startTokenId) public onlyOwner {
    require(_startTokenId > 0 && _startTokenId <= 7, "Offset too high");

    mintInternal(_to, _startTokenId, 1);
    mintInternal(_to, _startTokenId + 7, 1);
    mintInternal(_to, _startTokenId + 14, 1);
    mintInternal(_to, _startTokenId + 21, 1);
    mintInternal(_to, _startTokenId + 28, 1);
    mintInternal(_to, _startTokenId + 35, 1);
    mintInternal(_to, _startTokenId + 42, 1);
  }

  function mintInternal(address _account, uint256 _tokenId, uint256 _quantity) internal {
    require(_tokenId > 0 && _tokenId <= MAX_TOKEN_COUNT, "Not a valid token");
    if (_tokenId < CHALLENGE_TOKEN_START) { // mintable token
      require(totalSupply(_tokenId) + _quantity <= SUPPLY_PER_MINTABLE_TOKEN, "Not enough left");
    } else { // challenge token
      require(totalSupply(_tokenId) + _quantity <= SUPPLY_PER_CHALLENGE_TOKEN, "Not enough left");
    }

    if (_tokenId >= MINTABLE_TOKEN_START && _tokenId < CHALLENGE_TOKEN_START) {
      uint256 tokenIndex = _tokenId - MINTABLE_TOKEN_START;
      require(mintableTokenCount[tokenIndex] >= _quantity, "TokenId not mintable");

      mintableTokenCount[tokenIndex] -= _quantity;
    }

    _mint(_account, _tokenId, _quantity, "");
  }

  function tokenIdAtIndex(uint256 _index) internal view returns (uint256) {
    for(uint256 i = 0; i < mintableTokenCount.length; i++ ) {
      if (_index < mintableTokenCount[i]) {
        return i;
      }
      _index -= mintableTokenCount[i];
    }
    return 0;
  }

  function mintableSupply() public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < mintableTokenCount.length; i++) {
      total += mintableTokenCount[i];
    }
    return total;
  }

  function is0n1Holder() internal view returns (bool) {
    return IERC721(the0n1ForceAddress).balanceOf(msg.sender) > 0;
  }

  function isHaunted5Holder() internal view returns (bool) {
    for (uint256 i = 0; i < 77; i++) {
      uint256 tokenId = 77 - i;
      if (ERC1155(theHaunted5Address).balanceOf(msg.sender, tokenId) > 0) {
        return true;
      }
    }
    return false;
  }

  function holdsHauntedToken(uint256 _tokenId) internal view returns (bool) {
    if (_tokenId == 0) {
      return false;
    }

    return ERC1155(theHaunted5Address).balanceOf(msg.sender, _tokenId) > 0;
  }

  /* Owner Functions */

  function pauseSale() public onlyOwner {
    _pause();
  }

  function unpauseSale() public onlyOwner {
    _unpause();
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setWalletLimit(uint256 _walletLimit) public onlyOwner {
    walletLimit = _walletLimit;
  }

  function withdraw() public onlyOwner {
    Address.sendValue(PAYABLE_ADDRESS, address(this).balance);
  }

  receive() external payable {}

  /* Overrides */

  function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mint(account, id, amount, data);
  }

  function _mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
    super._mintBatch(account, ids, amounts, data);
  }

  function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Supply) {
    super._burn(account, id, amount);
  }

  function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal override(ERC1155, ERC1155Supply) {
    super._burnBatch(account, ids, amounts);
  }
}

/* Contract by: _            _       _             _
   ____        | |          (_)     | |           | |
  / __ \   ___ | |__   _ __  _  ___ | |__    ___  | |
 / / _` | / __|| '_ \ | '__|| |/ __|| '_ \  / _ \ | |
| | (_| || (__ | | | || |   | |\__ \| | | || (_) || |
 \ \__,_| \___||_| |_||_|   |_||___/|_| |_| \___/ |_|
  \____/  */
