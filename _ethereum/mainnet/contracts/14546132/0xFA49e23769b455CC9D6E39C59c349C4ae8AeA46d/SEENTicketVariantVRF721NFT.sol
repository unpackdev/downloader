// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

// OpenZeppelin Contracts @ version 4.3.2
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./IRandomNumberConsumer.sol";
import "./IERC2981.sol";

/**
 * @title TicketVariantVRF721NFT
 * @notice ERC-721 NFT Contract with VRF-powered offset after ticket period completion
 *
 * Key features:
 * - Uses Chainlink VRF to establish random distribution at time of "reveal"
 */
contract SEENTicketVariantVRF721NFT is ERC721, Ownable {
  using Strings for uint256;

  // Controlled state variables
  using Counters for Counters.Counter;
  Counters.Counter private _ticketIds;
  bool public isRandomnessRequested;
  bytes32 public randomNumberRequestId;
  uint256 public vrfResult;
  uint256 public randomOffset;
  mapping(address => uint256[]) public buyerToTicketIds;
  mapping(uint256 => address) public ticketIdToBuyer;
  mapping(address => uint256) public buyerToRedeemedTicketCount;

  // Configurable state variables
  string public baseURI;
  uint256 public supplyLimit;
  uint256 public start;
  uint256 public end;
  uint256 public price;
  uint256 public limitPerOrder;
  address public vrfProvider;
  address[] public payoutAddresses;
  uint16[] public payoutAddressBasisPoints;
  address public royaltyReceiver;
  uint16 public royaltyBasisPoints;

  // Events
  event Buy(address indexed buyer, uint256 amount);
  event PlacedReservation(address indexed buyer, uint256 indexed ticketId);
  event RequestedVRF(bool isRequested, bytes32 randomNumberRequestId);
  event CommittedVRF(bytes32 requestId, uint256 vrfResult, uint256 randomOffset);
  event MintedOffset(address indexed minter, uint256 indexed ticketId, uint256 indexed tokenId);
  event UpdatedPayoutScheme(address indexed updatedBy, address[] payoutAddresses, uint16[] payoutAddressBasisPoints, uint256 timestamp);

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _baseURI,
    uint256 _supplyLimit,
    uint256 _start,
    uint256 _end,
    uint256 _price,
    uint256 _limitPerOrder,
    address _vrfProvider,
    address[] memory _payoutAddresses,
    uint16[] memory _payoutAddressBasisPoints
  ) public ERC721(_tokenName, _tokenSymbol) {
    require(_payoutAddresses.length > 0, "PAYOUT_ADDRESSES_EMPTY");
    require(_payoutAddresses.length == _payoutAddressBasisPoints.length, "MISSING_BASIS_POINTS");
    randomOffset = 0; // Must be zero at time of deployment
    baseURI = _baseURI;
    supplyLimit = _supplyLimit;
    start = _start;
    end = _end;
    price = _price;
    limitPerOrder = _limitPerOrder;
    vrfProvider = _vrfProvider;
    uint256 totalBasisPoints;
    for(uint256 i = 0; i < _payoutAddresses.length; i++) {
        // _payoutAddressBasisPoints may not contain values of 0 and may not exceed 10000 (100%)
        require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000), "INVALID_BASIS_POINTS_1");
        totalBasisPoints += _payoutAddressBasisPoints[i];
    }
    // _payoutAddressBasisPoints must add up to 10000 together
    require(totalBasisPoints == 10000, "INVALID_BASIS_POINTS_2");
    payoutAddresses = _payoutAddresses;
    payoutAddressBasisPoints = _payoutAddressBasisPoints;
  }

  function buy(uint256 quantity) external payable {
    require(block.timestamp >= start, "HAS_NOT_STARTED");
    require(block.timestamp <= end, "HAS_ENDED");
    require(quantity > 0, "BELOW_MIN_QUANTITY");
    require((msg.value) == (price * quantity), "INCORRECT_ETH_AMOUNT");
    require(quantity <= limitPerOrder, "EXCEEDS_MAX_PER_TX");
    require((_ticketIds.current() + quantity) <= supplyLimit, "EXCEEDS_MAX_SUPPLY");

    // We increment first because we want our first ticket ID to have an ID of 1 instead of 0
    // (makes wrapping from max -> min slightly easier)
    for(uint256 i = 0; i < quantity; i++) {
      _ticketIds.increment();
      uint256 newTicketId = _ticketIds.current();
      buyerToTicketIds[msg.sender].push(newTicketId);
      ticketIdToBuyer[newTicketId] = msg.sender;
      emit PlacedReservation(msg.sender, newTicketId);
    }

    if(_ticketIds.current() == supplyLimit) {
      end = block.timestamp;
    }

    emit Buy(msg.sender, quantity);

  }

  function addressToTicketCount(address _address) public view returns (uint256) {
    return buyerToTicketIds[_address].length;
  }

  function mint(uint256[] memory _mintTicketIds) external {
    require(vrfResult > 0, "VRF_RESULT_NOT_SET");
    uint256[] memory ticketIdsMemory = buyerToTicketIds[msg.sender];
    require(ticketIdsMemory.length > 0, "NO_OWNED_TICKETS");
    uint256 buyerToRedeemedTicketCountMemory = buyerToRedeemedTicketCount[msg.sender];
    require(buyerToRedeemedTicketCountMemory < ticketIdsMemory.length, "ALL_OWNED_TICKETS_REDEEMED");
    uint256 ticketSupply = _ticketIds.current();
    for(uint256 i = 0; i < _mintTicketIds.length; i++) {
      require(ticketIdToBuyer[_mintTicketIds[i]] == msg.sender, "TICKET_NOT_ASSIGNED_TO_SENDER");
      // Uses the VRF-provided randomOffset to determine which metadata file is used for the requested ticketId
      uint256 offsetTokenId;
      if((_mintTicketIds[i] + randomOffset) <= ticketSupply) {
        // e.g. with a randomOffset of 2, and a ticketSupply of 10, and a ticketId of 5: offsetTokenId = 7 (5 + 2)
        offsetTokenId = _mintTicketIds[i] + randomOffset;
      } else {
        // e.g. with a randomOffset of 2, and a ticketSupply of 10, and a ticketId of 9: offsetTokenId = 1 (wraps around from 9 -> 1: (2 - (10 - 9)))
        offsetTokenId = (randomOffset - (ticketSupply - _mintTicketIds[i]));
      }
      _mint(msg.sender, offsetTokenId);
      emit MintedOffset(msg.sender, _mintTicketIds[i], offsetTokenId);
    }
    buyerToRedeemedTicketCount[msg.sender] += _mintTicketIds.length;
  }

  function tokenURI(uint256 _ticketId) public view virtual override returns (string memory) {
    require(_exists(_ticketId), "ERC721Metadata: URI query for nonexistent ticket");

    // Concatenate the ticketID along with the '.json' to the baseURI
    return string(abi.encodePacked(baseURI, _ticketId.toString(), '.json'));
  }

  function initiateRandomDistribution() external {
    require(block.timestamp > end, "HAS_NOT_ENDED");
    uint256 ticketSupply = _ticketIds.current();
    require(ticketSupply > 0, "ZERO_TICKET_SUPPLY");
    require(isRandomnessRequested == false, "VRF_ALREADY_REQUESTED");
    IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
    randomNumberRequestId = randomNumberConsumer.getRandomNumber();
    isRandomnessRequested = true;
    emit RequestedVRF(isRandomnessRequested, randomNumberRequestId);
  }

  function commitRandomDistribution() external {
    require(isRandomnessRequested == true, "VRF_NOT_REQUESTED");
    IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(vrfProvider);
    uint256 result = randomNumberConsumer.readFulfilledRandomness(randomNumberRequestId);
    require(result > 0, "VRF_RESULT_NOT_PROVIDED");
    vrfResult = result;
    randomOffset = result % _ticketIds.current();
    emit CommittedVRF(randomNumberRequestId, vrfResult, randomOffset);
  }

  function ticketId() external view returns (uint256) {
    return _ticketIds.current();
  }

  function isReservationPeriodOver() public view returns (bool) {
    return block.timestamp > end;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
      return
          interfaceId == type(IERC721).interfaceId ||
          interfaceId == type(IERC721Metadata).interfaceId ||
          interfaceId == type(IERC2981).interfaceId ||
          super.supportsInterface(interfaceId);
  }

  // Fee distribution / Ownable logic below

  function getPercentageOf(
      uint256 _amount,
      uint16 _basisPoints
  ) internal pure returns (uint256 value) {
      value = (_amount * _basisPoints) / 10000;
  }

  function distributeFees() public onlyOwner {
    uint256 feeCutsTotal;
    uint256 balance = address(this).balance;
    for(uint256 i = 0; i < payoutAddresses.length; i++) {
        uint256 feeCut;
        if(i < (payoutAddresses.length - 1)) {
            feeCut = getPercentageOf(balance, payoutAddressBasisPoints[i]);
        } else {
            feeCut = (balance - feeCutsTotal);
        }
        feeCutsTotal += feeCut;
        (bool feeCutDeliverySuccess, ) = payoutAddresses[i].call{value: feeCut}("");
        require(feeCutDeliverySuccess, "ClaimAgainstERC721::distributeFees: Fee cut delivery unsuccessful");
    }
  }
  
  function updateFeePayoutScheme(
      address[] memory _payoutAddresses,
      uint16[] memory _payoutAddressBasisPoints
  ) public onlyOwner {
      require(_payoutAddresses.length > 0, "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddresses must contain at least one entry");
      require(_payoutAddresses.length == _payoutAddressBasisPoints.length, "ClaimAgainstERC721::updateFeePayoutScheme: each payout address must have a corresponding basis point share");
      uint256 totalBasisPoints;
      for(uint256 i = 0; i < _payoutAddresses.length; i++) {
          require((_payoutAddressBasisPoints[i] > 0) && (_payoutAddressBasisPoints[i] <= 10000), "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddressBasisPoints may not contain values of 0 and may not exceed 10000 (100%)");
          totalBasisPoints += _payoutAddressBasisPoints[i];
      }
      require(totalBasisPoints == 10000, "ClaimAgainstERC721::updateFeePayoutScheme: _payoutAddressBasisPoints must add up to 10000 together");
      payoutAddresses = _payoutAddresses;
      payoutAddressBasisPoints = _payoutAddressBasisPoints;
      emit UpdatedPayoutScheme(msg.sender, _payoutAddresses, _payoutAddressBasisPoints, block.timestamp);
  }

  function adjustEnd(uint256 _endTimeUnix) external onlyOwner {
    require(isRandomnessRequested == false, "VRF_ALREADY_REQUESTED");
    require(_endTimeUnix > block.timestamp, "NEW_END_TIME_IN_PAST");
    end = _endTimeUnix;
  }

  // ERC-2981 universal royalty logic

  function updateRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyBasisPoints) external onlyOwner {
    royaltyReceiver = _royaltyReceiver;
    royaltyBasisPoints = _royaltyBasisPoints;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyReceiver;
    royaltyAmount = getPercentageOf(_salePrice, royaltyBasisPoints);
  }

}