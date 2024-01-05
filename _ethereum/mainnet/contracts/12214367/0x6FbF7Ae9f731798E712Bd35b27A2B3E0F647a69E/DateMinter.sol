pragma solidity ^0.7.5;
pragma abicoder v2;

import "./LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./MixinOwnable.sol";
import "./LibDateMath.sol";

contract DateMinter is Ownable {
  using LibSafeMath for uint256;
  using LibDateMath for int256;

  struct _DateToken {
    int256 timestamp;
    uint256 generation;
    bool isValid; // set if the value is set, to distinguish from the real (0,0) value - ie, epoch at gen 0.
  }

  uint256 public tokenType;
  uint256 public batchOrderLimit;

  // generation-specific variables
  uint256 public curMaxSupplyLimit;
  uint256 public curGeneration;
  int256 public curDateRangeStartTimestamp;
  int256 public curDateRangeEndTimestamp;

  // some other admin toggles
  bool public allowFutureDates;
  bool public saleStarted;
  int256 public oldestTimestamp;

  // referral program variables;
  mapping(string => uint256) public referralCodeMapping; // make this a mapping to make it easily searchable if something exists
  mapping(string => uint256) public referralCodeToAmount;

  ERC1155Mintable public mintableErc1155;

  address payable public treasury;

  string[] public claimedDateStrings;

  mapping(uint256 => _DateToken) public tokenIdToTimestamp;
  mapping(string => uint256) public dateStringToTokenId; // we need this because there are multiple timestamps to a date

  // we keep a helpful mapping of number of tokens per generation so it's easier to count
  mapping(uint256 => uint256) public generationToTokenCount;

  // count of reserved tokens that we can issue for platform supporters
  uint256 public constant reservedTokenCountCap = 30;
  uint256 public currentReservedTokenCount;
 
  constructor(
    address _mintableErc1155,
    address payable _treasury,
    uint256 _tokenType,
    uint256 _curMaxSupplyLimit,    // 3650
    uint256 _curGeneration,        // 0
    uint256 _batchOrderLimit,      // 20
    bool _allowFutureDates,        // false
    int256 _oldestTimestamp,       // some unix timestamp
    string[] memory _initialReferralCodes // ["some", "referral", "codes"]
  ) {
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
    treasury = _treasury;
    tokenType = _tokenType;
    curMaxSupplyLimit = _curMaxSupplyLimit;
    curGeneration = _curGeneration;
    batchOrderLimit = _batchOrderLimit;
    allowFutureDates = _allowFutureDates;
    oldestTimestamp = _oldestTimestamp;

    for (uint i = 0; i < _initialReferralCodes.length; i++) {
      string memory code = _initialReferralCodes[i];
      if (referralCodeMapping[code] == 0) {
        referralCodeMapping[code] = 1;
      }
    }
  }

  event UpdatedRegistry(
      uint256 tokenId,
      int256 timestamp
  );

  /**
  * @dev Returns the total supply of minted date tokens
  */
  function totalSupply() public view returns (uint256) {
    return mintableErc1155.maxIndex(tokenType);
  }

  /**
  * @dev Gets the price. Currently we assume that the price curve just follows one pattern of flat then linearly increasing.
  */
  function getPrice() public view returns (uint256) {
    uint256 curTokenCount = generationToTokenCount[curGeneration];
    require(curTokenCount < curMaxSupplyLimit, "Sale has already ended");

    if (curTokenCount >= 3640) {
        return 1000000000000000000; // 3640 - 3649 1 ETH
    } else if (curTokenCount >= 3000) {
        return 500000000000000000; // 3000 - 3639 0.50 ETH
    } else if (curTokenCount >= 2500) {
        return 320000000000000000; // 2500  - 2999 0.32 ETH
    } else if (curTokenCount >= 2000) {
        return 160000000000000000; // 2000 - 2499 0.16 ETH
    } else if (curTokenCount >= 1500) {
        return 80000000000000000; // 1500 - 1999 0.08 ETH
    } else if (curTokenCount >= 1000) {
        return 40000000000000000; // 1000 - 1499 0.04 ETH
    } else {
        return 30000000000000000; // 0 - 999 0.03 ETH 
    }
  }

  /**
  * @dev Nice helper function to get the date string from the token ID
  */
  function getDateStringFromTokenId(uint256 _tokenId) public view returns (string memory) {
    _DateToken memory dt = tokenIdToTimestamp[_tokenId];
    require(dt.isValid, "tokenId must exist in mapping");
    return dt.timestamp.getDateAsString();
  }

  /**
  * @dev Nice helper function to get the date string from any timestamp
  */
  function getDateStringFromTimestamp(int256 _timestamp) public view returns (string memory) {
    return _timestamp.getDateAsString();
  }

  /**
  * @dev Get date format
  */
  function getDateFormat() public pure returns (string memory) {
    return "MM/DD/YYYY";
  }

  /**
  * @dev Returns all claimed date strings as an array
  */
  function getAllClaimedDateStrings() public view returns (string[] memory) {
    return claimedDateStrings;
  }

  /**
  * @dev Return original timestamps that a given address owns. Leverages nfTokensOf but returns the hashtags instead of the token IDs
  */
  function timestampsOf(address _address) public view returns (_DateToken[] memory) {
    uint256[] memory tokenIds = mintableErc1155.nfTokensOf(_address);
    _DateToken[] memory timestamps = new _DateToken[](tokenIds.length);
    for(uint i=0; i<tokenIds.length; i++){
      timestamps[i] = tokenIdToTimestamp[tokenIds[i]];
    }
    return timestamps;
  }

  /**
  * @dev Set address of treasury - the address that will receive all payments
  */
  function setTreasury(address payable _treasury) external onlyOwner() {
    treasury = _treasury;
  }

  /**
  * @dev Set current max supply. This means the max supply of the current round.
  */
  function setCurMaxSupply(uint256 _curMaxSupplyLimit) external onlyOwner() {
    curMaxSupplyLimit = _curMaxSupplyLimit;
  }

  /**
  * @dev Set current generation.
  */
  function setCurGeneration(uint256 _curGeneration) external onlyOwner() {
    curGeneration = _curGeneration;
  }

  /**
  * @dev Set saleStarted boolean to start or end sale
  */
  function setSaleStarted(bool _saleStarted) external onlyOwner() {
    saleStarted = _saleStarted;
  }

  /**
  * @dev Set allowFutureDates boolean to allow for future dates to be minted
  */
  function setAllowFutureDates(bool _allowFutureDates) external onlyOwner() {
    allowFutureDates = _allowFutureDates;
  }

  /**
  * @dev Set oldestTimestamp to set a floor for the oldest date you can mint
  */
  function setOldestTimestamp(int256 _oldestTimestamp) external onlyOwner() {
    oldestTimestamp = _oldestTimestamp;
  }

  /**
  * @dev Add more referral codes as necessary
  */
  function addReferralCodes(string[] memory _codes) external onlyOwner() {
    // check if code already exists
    for (uint i = 0; i < _codes.length; i++) {
      string memory code = _codes[i];
      if (referralCodeMapping[code] == 0) {
        referralCodeMapping[code] = 1;
      }
    }
  }

  /**
  * @dev Reserve up to 30 dates for platform supporters.
  */
  function reserveTokens(int256[] memory _timestamps) external onlyOwner() {
    require(currentReservedTokenCount.safeAdd(_timestamps.length) <= reservedTokenCountCap, "Exceeds reservedTokenCountCap");
    for (uint i = 0; i < _timestamps.length; i++) {
      int256 dateTimestamp = _timestamps[i];

      // check if not minted
      string memory dateString = getDateStringFromTimestamp(dateTimestamp);
      if (dateStringToTokenId[dateString] != 0) {
        continue;
      }

      // check whether this timestamp is allowed
      if (!allowFutureDates && int256(block.timestamp) < dateTimestamp) {
        continue;
      }

      // check whether this timestamp is before our oldest timestamp limit
      if (dateTimestamp < oldestTimestamp) {
        continue;
      }

      // mint NFT (ERC1155Mintable)
      address[] memory dsts = new address[](1);
      dsts[0] = _msgSender();
      uint256 index = mintableErc1155.maxIndex(tokenType) + 1;
      uint256 tokenId  = tokenType | index;
      mintableErc1155.mintNonFungible(tokenType, dsts);

      // store mapping in this contract for bookkeeping
      _DateToken memory dt;
      dt.timestamp = dateTimestamp;
      dt.generation = curGeneration;
      dt.isValid = true;

      tokenIdToTimestamp[tokenId] = dt;
      generationToTokenCount[curGeneration] += 1;

      // store string mapping too
      dateStringToTokenId[dateString] = tokenId;

      claimedDateStrings.push(dateString);

      emit UpdatedRegistry(tokenId, dateTimestamp);

      currentReservedTokenCount += 1;
    }
  }

  /**
  * @dev Mint a given date (input is a timestamp).
  *      Note that referralCode can be an empty string if minted without a code
  */
  function mint(address _dst, int256[] memory _dateTimestamps, string memory referralCode) public payable {
    require(saleStarted, "Sale has not started yet");
    uint256 curTokenCount = generationToTokenCount[curGeneration];
    require(curTokenCount < curMaxSupplyLimit, "Sale has already ended");

    uint numberOfDates = _dateTimestamps.length;
    require(numberOfDates > 0, "numberOfDates cannot be 0");
    require(numberOfDates <= batchOrderLimit, "You may not buy more than the batch limit at once");
    require(totalSupply().safeAdd(numberOfDates) <= curMaxSupplyLimit, "Exceeds curMaxSupplyLimit");
    require(getPrice().safeMul(numberOfDates) <= msg.value, "Ether value sent is not correct");

    // set price upfront before minting - we will need to use this to calculate refunds
    uint256 pricePerDate = getPrice();
    uint mintedCount = 0;

    for (uint i = 0; i < numberOfDates; i++) {
      int256 dateTimestamp = _dateTimestamps[i];

      // check if not minted
      string memory dateString = getDateStringFromTimestamp(dateTimestamp);
      if (dateStringToTokenId[dateString] != 0) {
        continue;
      }

      // check whether this timestamp is allowed
      if (!allowFutureDates && int256(block.timestamp) < dateTimestamp) {
        continue;
      }

      // check whether this timestamp is before our oldest timestamp limit
      if (dateTimestamp < oldestTimestamp) {
        continue;
      }

      // mint NFT (ERC1155Mintable)
      address[] memory dsts = new address[](1);
      dsts[0] = _dst;
      uint256 index = mintableErc1155.maxIndex(tokenType) + 1;
      uint256 tokenId  = tokenType | index;
      mintableErc1155.mintNonFungible(tokenType, dsts);

      // store mapping in this contract for bookkeeping
      _DateToken memory dt;
      dt.timestamp = dateTimestamp;
      dt.generation = curGeneration;
      dt.isValid = true;

      tokenIdToTimestamp[tokenId] = dt;
      generationToTokenCount[curGeneration] += 1;

      // store string mapping too
      dateStringToTokenId[dateString] = tokenId;
      mintedCount++;

      claimedDateStrings.push(dateString);

      emit UpdatedRegistry(tokenId, dateTimestamp);
    }

    // funds transfer
    uint256 actualTotalPrice = pricePerDate.safeMul(mintedCount);
    treasury.transfer(actualTotalPrice);
    msg.sender.transfer(msg.value.safeSub(actualTotalPrice));

    // add tx amount to referer
    bytes memory referralCodeInBytes = bytes(referralCode); // make string into bytes to test for lengtth
    if (referralCodeInBytes.length != 0 && referralCodeMapping[referralCode] == 1) {
      referralCodeToAmount[referralCode] += actualTotalPrice;
    }
  }
}