// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./IReservationBook.sol";
import "./IERC721Dispatcher.sol";
import "./DispatchLib.sol";
import "./IERC20.sol";

/**
 * @title ReservationBook
 * @dev ReservationBook contract for use with ERC721Dispatcher.
 * @author 0xAnimist (kanon.art)
 */
contract ReservationBook is IReservationBook {

  // ERC721Dispatcher
  address public dispatcherAddress;

  // The dispatcher
  IERC721Dispatcher private dispatcher;

  // Basic terms
  struct TermBase {
    address payee;
    address reservee;
    address currency;
    uint256 fee;
    uint256 durationInSecs;
  }

  // Stores reservation information
  struct Reservations {
    uint256 startingIndex;
    uint256 maxReservations;
    uint256[] startTimes;
    uint256[] feesAccruedInWei;
    address[] reservees;
    address[] payees;
    bytes[] terms;
  }

  // Mapping from token ID to reservations
  mapping(uint256 => Reservations) internal _reservations;

  // Temporary buffer for processing refunds
  mapping(uint256 => address) private _refundRecipientsBuffer;

  // Temporary buffer for processing refunds
  mapping(address => uint256) private _refundAmountBuffer;

  // Default maxiumum reservations per token
  uint256 defaultMaxReservations = 20;

  modifier onlyDispatcher() {
    require(msg.sender == dispatcherAddress, "only dispatcher");
    _;
  }

  /**
   * @dev Constructor.
   */
  constructor(address _dispatcherAddress) {
    dispatcherAddress = _dispatcherAddress;
    dispatcher = IERC721Dispatcher(_dispatcherAddress);
  }

  /**
   * @dev See {IReservationBook-setDefaultMaxReservations}.
   */
  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external virtual override onlyDispatcher {
    defaultMaxReservations = _defaultMaxReservations;
  }

  /**
   * @dev See {IReservationBook-setMaxReservations}.
   */
  function setMaxReservations(uint256[] memory _maxReservations, uint256[] memory _tokenIds) external virtual override onlyDispatcher {
    require(_tokenIds.length == _maxReservations.length, "must be same length");
    for(uint256 i = 0; i < _tokenIds.length; i++){
      _reservations[_tokenIds[i]].maxReservations = _maxReservations[i];
    }
  }

  /**
   * @dev See {IReservationBook-getMaxReservations}.
   */
  function getMaxReservations(uint256 _tokenId) external virtual override view returns (uint256 maxReservations) {
    return _reservations[_tokenId].maxReservations;
  }

  /**
   * @dev See {IReservationBook-reserve}.
   */
  function reserve(address _reservee, address _RQContract, uint256 _RQTokenId, uint256 _startTime, bytes memory _requestTerms, bytes calldata _data) external payable virtual override returns (bool success) {
    (bool tokenExists, uint256 tokenId) = dispatcher.getTokenIdByDeposit(_RQContract, _RQTokenId);
    require(tokenExists, "no such tokenId");
    require(_startTime >= block.timestamp, "past");

    uint256 reservationsRemaining = purgeExpired(tokenId);

    require(reservationsRemaining > 0, "reservations full");

    //confirm terms are acceptable
    bool valid;
    TermBase memory termBase;
    (valid, termBase.currency, termBase.fee, termBase.durationInSecs) = DispatchLib.validateReservation(msg.sender, _requestTerms, dispatcher.getTerms(tokenId));
    require(valid, "inv");

    //confirm the reservation window is available
    (bool reserved, uint256 insertHere) = isReserved(_startTime, _startTime + termBase.durationInSecs - 1, tokenId);
    require(!reserved, "already reserved at this time");
    require(dispatcher.getNextAvailable(tokenId) <= _startTime, "not avail");

    //process pre-payment
    _processPayment(msg.sender, termBase.currency, termBase.fee);

    termBase.reservee = _reservee;
    termBase.payee = msg.sender;

    success = _insertReservation(termBase, _startTime, insertHere, tokenId, _requestTerms);

    if(success){
      emit Reserved(termBase.payee, termBase.reservee, _startTime, tokenId, _requestTerms, _data);
    }
  }

  /**
   * @dev Proceeses payment.
   */
  function _processPayment(address _payee, address _currency, uint256 _fee) internal {
    if(_fee > 0){
      //collect withholding
      if(_currency != address(0)){//pay in ERC20
        IERC20(_currency).transferFrom(_payee, address(this), _fee);
      }else{//pay in ETH
        require(msg.value >= _fee, "more ETH");
      }
    }
  }

  /**
   * @dev See {IReservationBook-refundFutureReservations}.
   */
  function refundFutureReservations(address _currency, uint256 _tokenId) external {
    uint256 totalRecipients = 0;

    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].feesAccruedInWei.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);

      if(endTime >= block.timestamp){
        for(uint256 j = 0; j <= totalRecipients; j++){
          if(_refundRecipientsBuffer[j] == _reservations[_tokenId].payees[i]){
            break;
          }else{
            if(j == totalRecipients){
              _refundRecipientsBuffer[totalRecipients] = _reservations[_tokenId].payees[i];
              totalRecipients++;
              break;
            }
          }
        }
        //require(false, "add to buffer");
        _refundAmountBuffer[_reservations[_tokenId].payees[i]] += _reservations[_tokenId].feesAccruedInWei[i];

      }
    }
    _processRefunds(_currency, totalRecipients);
  }

  /**
   * @dev Processes refunds to recipients, paying with `_currency` currency.
   */
  function _processRefunds(address _currency, uint256 _totalRecipients) internal {
    //require(false, "_processRefunds");
    for(uint256 i = 0; i < _totalRecipients; i++){
      //require(false, "_processRefunds for");
      _pay(_currency, _refundRecipientsBuffer[i], _refundAmountBuffer[_refundRecipientsBuffer[i]]);

      delete _refundAmountBuffer[_refundRecipientsBuffer[i]];
      delete _refundRecipientsBuffer[i];
    }
  }

  /**
   * @dev See {IReservationBook-claimFeesAccrued}.
   */
  function claimFeesAccrued(address _currency, uint256 _tokenId) external onlyDispatcher returns (bool success, uint256 feesClaimedInWei){
    uint256 feesToPayInWei = 0;
    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].feesAccruedInWei.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);
      if(block.timestamp > endTime){
        feesToPayInWei += _reservations[_tokenId].feesAccruedInWei[i];
        _clearReservation(i, _tokenId);
      }
    }

    return _pay(_currency, dispatcherAddress, feesToPayInWei);
  }

  /**
   * @dev Clears reservation at `_i` index on `_tokenId` token.
   */
  function _clearReservation(uint256 _i, uint256 _tokenId) internal {
    delete _reservations[_tokenId].startTimes[_i];
    delete _reservations[_tokenId].feesAccruedInWei[_i];
    delete _reservations[_tokenId].payees[_i];
    delete _reservations[_tokenId].reservees[_i];
    delete _reservations[_tokenId].terms[_i];
  }

  /**
   * @dev Pays out `_amountInWei` amount in wei of `_currency` currency to `_recipient` recipient.
   */
  function _pay(address _currency, address _recipient, uint256 _amountInWei) internal returns (bool success, uint256 paidInWei){
    if(_currency == address(0)){//ETH is the currency
      (success,) = _recipient.call{value: _amountInWei}("");
    }else{//currency is an ERC20
      try IERC20(_currency).transfer(_recipient, _amountInWei) returns (bool transferred){
        success = transferred;
      } catch {}
    }
    paidInWei = _amountInWei;
  }

  /**
   * @dev See {IERC721DispatcherReservable-isReserved}.
   */
  function isReserved(uint256 _startTime, uint256 _endTime, uint256 _tokenId) public view virtual override returns (bool reserved, uint256 nextIndex) {
    return DispatchLib.isReserved(_endTime, _reservations[_tokenId].startTimes, _reservations[_tokenId].terms);
  }

  /**
   * @dev Inserts new reservation into the _reservations[_tokenId] mapping.
   */
  function _insertReservation(TermBase memory _termBase, uint256 _startTime, uint256 insertHere, uint256 _tokenId, bytes memory _terms) internal returns (bool success){
    uint256 totalReservations = _reservations[_tokenId].reservees.length;
    //add to end if inserting after last reservation
    if(totalReservations == insertHere){
      _reservations[_tokenId].payees.push(_termBase.payee);
      _reservations[_tokenId].reservees.push(_termBase.reservee);
      _reservations[_tokenId].startTimes.push(_startTime);
      _reservations[_tokenId].terms.push(_terms);
      _reservations[_tokenId].feesAccruedInWei.push(_termBase.fee);
      return true;
    }

    //make room for new reservation
    for(uint256 i = insertHere; i < totalReservations+1; i++){
      _reservations[_tokenId].payees[i+1] = _reservations[_tokenId].payees[i];
      _reservations[_tokenId].reservees[i+1] = _reservations[_tokenId].reservees[i];
      _reservations[_tokenId].startTimes[i+1] = _reservations[_tokenId].startTimes[i];
      _reservations[_tokenId].terms[i+1] = _reservations[_tokenId].terms[i];
      _reservations[_tokenId].feesAccruedInWei[i+1] = _reservations[_tokenId].feesAccruedInWei[i];
    }

    //insert new reservation
    _reservations[_tokenId].payees[insertHere] = _termBase.payee;
    _reservations[_tokenId].reservees[insertHere] = _termBase.reservee;
    _reservations[_tokenId].startTimes[insertHere] = _startTime;
    _reservations[_tokenId].terms[insertHere] = _terms;
    _reservations[_tokenId].feesAccruedInWei[insertHere] = _termBase.fee;

    return true;
  }

  /**
   * @dev See {IERC721DispatcherReservable-getReservations}.
   */
  function getReservations(uint256 _tokenId) external view virtual override returns (address[] memory reservees, uint256[] memory startTimes, bytes[] memory terms) {
    uint256 length = _reservations[_tokenId].reservees.length - _reservations[_tokenId].startingIndex;
    reservees = new address[](length);
    startTimes = new uint256[](length);
    terms = new bytes[](length);

    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].reservees.length; i++){
      uint256 j = i - _reservations[_tokenId].startingIndex;
      reservees[j] = _reservations[_tokenId].reservees[i];
      startTimes[j] = _reservations[_tokenId].startTimes[i];
      terms[j] = _reservations[_tokenId].terms[i];
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-reservedFor}.
   */
  function reservedFor(uint256 _time, uint256 _tokenId) public view virtual override returns (address reservee, uint256 startTime, uint256 endTime, uint256 termsIndex) {
    bool reserved;
    (reserved, termsIndex, endTime) = DispatchLib.reservedFor(_time, _reservations[_tokenId].reservees, _reservations[_tokenId].startTimes, _reservations[_tokenId].terms);

    if(reserved){
      reservee = _reservations[_tokenId].reservees[termsIndex];
      startTime = _reservations[_tokenId].startTimes[termsIndex];
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-validateReservation}.
   */
  function validateReservation(address _reservee, uint256 _tokenId, bytes memory _requestedTerms) external view returns (bool valid) {
    (address reservee,,, uint256 termsIndex) = reservedFor(block.timestamp, _tokenId);
    if(reservee != _reservee){
      return false;
    }

    //confirm terms match the reservation terms
    if(DispatchLib.termsApproved(_reservations[_tokenId].terms[termsIndex], _requestedTerms)) {
      return true;
    }
  }

  /**
   * @dev See {IERC721DispatcherReservable-purgeExpired}.
   */
  function purgeExpired(uint256 _tokenId) public returns (uint256 reservationsRemaining){
    uint256 startingIndex = _reservations[_tokenId].startingIndex;
    for(uint256 i = _reservations[_tokenId].startingIndex; i < _reservations[_tokenId].reservees.length; i++){
      uint256 endTime = _reservations[_tokenId].startTimes[i] + DispatchLib.getDuration(_reservations[_tokenId].terms[i]);
      if(block.timestamp > endTime){//reservation at index i has expired
        startingIndex = i+1;
      }else{
        break;
      }
    }
    _reservations[_tokenId].startingIndex = startingIndex;

    uint256 currentTotal = _reservations[_tokenId].reservees.length - startingIndex;
    return _reservations[_tokenId].maxReservations - currentTotal;
  }
}
