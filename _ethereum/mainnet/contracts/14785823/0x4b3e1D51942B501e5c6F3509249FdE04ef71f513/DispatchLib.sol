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

import "./IERC721Dispatcher.sol";
import "./BytesLib.sol";
import "./Context.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

/// @title DispatchLib
/// @notice Utility library for ERC721Dispatcher
/// @author 0xAnimist (kanon.art)
library DispatchLib {

  bytes4 public constant _METHOD_ID_BORROW = bytes4(keccak256("borrow(address,uint256,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED = bytes4(keccak256("borrowReserved(address,uint256,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs)

  bytes4 public constant _METHOD_ID_BORROW_WITH_721_PASS = bytes4(keccak256("borrowWith721Pass(address,uint256,uint256,address)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC721Contract)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED_WITH_721_PASS = bytes4(keccak256("borrowReservedWith721Pass(address,uint256,uint256,address)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC721Contract)

  bytes4 public constant _METHOD_ID_BORROW_WITH_1155_PASS = bytes4(keccak256("borrowWith1155Pass(address,uint256,uint256,address,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC1155Contract, ERC1155TokenId)

  bytes4 public constant _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS = bytes4(keccak256("borrowReservedWith1155Pass(address,uint256,uint256,address,uint256)"));//(currency, feeInWeiPerSec, maxDurationInSecs, ERC1155Contract, ERC1155TokenId)

  function validateMethodId(bytes4 methodId) public pure returns (bool valid) {
    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      valid = true;
    }
  }

  function validateRequestFormat(bytes memory _term, bytes4[] memory _servedMethodIds) public pure returns (bool valid) {
    bytes4 methodId = bytes4(_term);
    for(uint256 i = 0; i < _servedMethodIds.length; i++){
      if(_servedMethodIds[i] == methodId){//methodId is served
        if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED){
          return _term.length == 88;
        }else if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS){
          return _term.length == 108;
        }else if(methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
          return _term.length == 140;
        }
      }
    }
  }

  function isReserveRequest(bytes4 methodId) public pure returns (bool reserveRequest) {
    if(methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      reserveRequest = true;
    }
  }

  function getDuration(bytes memory _terms) public pure returns (uint256 duration) {
    if(validateMethodId(bytes4(_terms))){
      return BytesLib.toUint256(_terms, 56);
    }
  }

  function isReservedMethodId(bytes4 _methodId) public pure returns (bool reservedMethodId) {
    if(_methodId == _METHOD_ID_BORROW_RESERVED || _methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || _methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      return true;
    }
    return false;
  }


  function isCurrencyDiff(bytes memory _newTerms, bytes memory _oldTerms) public pure returns (bool diff) {
    diff = BytesLib.toAddress(_newTerms, 4) != BytesLib.toAddress(_oldTerms, 4);
  }

  function getBorrowTerms(bytes[] memory _terms) public pure returns (bool success, address currency, uint256 feeInWeiPerSec, uint256 maxDurationInSecs){
    (bool borrowTermsSet, uint256 i) = getTermIndexByMethodId(_terms, _METHOD_ID_BORROW);
    if(borrowTermsSet){
      (currency, feeInWeiPerSec, maxDurationInSecs) = unpackBorrowTerms(_terms[i]);
      success = true;
    }
  }

  function getTermIndexByMethodId(bytes[] memory _terms, bytes4 _type) public pure returns (bool success, uint256 index) {
    for(uint256 i = 0; i < _terms.length; i++){
      if(bytes4(_terms[i]) == _type){
        return (true, i);
      }
    }
  }

  function unpackMethodId(bytes memory _term) public pure returns (bytes4 methodId) {
    require(_term.length >= 4, "no methodId");
    return bytes4(_term);
  }

  function requiresPass(bytes memory _term) public pure returns (bool required, bool is721) {
    bytes4 methodId = unpackMethodId(_term);
    if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS){
      required = true;
      is721 = true;
    }else if(methodId == _METHOD_ID_BORROW_WITH_1155_PASS || methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS){
      required = true;
      is721 = false;
    }
  }

  function termsApproved(bytes memory _approvedTerms, bytes memory _requestedTerms) public pure returns (bool approved) {
    return BytesLib.equal(_approvedTerms, _requestedTerms);
  }

  function validateTerms(bool settableCurrency, address defaultCurrency, bytes[] memory _terms, bytes4[] memory _servedMethodIds) public pure returns (bool valid) {
    address firstCurrency = BytesLib.toAddress(_terms[0], 4);

    for(uint256 i = 0; i < _terms.length; i++){
      //determines if it served and if the terms well-formatted
      validateRequestFormat(_terms[i], _servedMethodIds);

      //validate currencies
      address currency = BytesLib.toAddress(_terms[i], 4);
      if((currency != firstCurrency && settableCurrency && i > 0) || (currency != defaultCurrency && !settableCurrency)){
        return false;//cannot have multiple currencies
      }
    }

    return true;
  }

  function unpackPass(bytes memory _term) public pure returns (bool passRequired, bool is721, bool hasId, address passContract, uint256 passId) {
    (passRequired, is721) = requiresPass(_term);
    if(passRequired){
      passContract = unpackPassContractTerms(_term);
      if(!is721){
        passId = unpackPassIdTerms(_term);
        hasId = true;
      }
    }
  }

  function unpackPassIdTerms(bytes memory _term) public pure returns (uint256 passId) {
    return BytesLib.toUint256(_term, 108);
  }

  function unpackPassContractTerms(bytes memory _term) public pure returns (address passContract) {
    return BytesLib.toAddress(_term, 88);
  }

  function unpackBorrowTerms(bytes memory _term) public pure returns (address currency, uint256 feeInWeiPerSec, uint256 maxDurationInSecs) {
    return (BytesLib.toAddress(_term, 4), BytesLib.toUint256(_term, 24), BytesLib.toUint256(_term, 56));
  }

  function validateReservation(address _from, bytes memory _requestTerms, bytes[] memory _allApprovedTerms) public pure returns (bool valid, address currency, uint256 fee, uint256 durationInSecs){

    (bool validTerms, bytes4 methodId, address currency_, uint256 fee_, uint256 durationInSecs_) = validateRequestedBorrowTerms(_requestTerms, _allApprovedTerms);

    bool isReservedMethod = isReservedMethodId(methodId);

    bool validPass = true;//validatePass(_from, methodId, _requestTerms, _allApprovedTerms);

    return (true == validPass == validTerms == isReservedMethod, currency_, fee_, durationInSecs_);
  }

  function validateRequest(address _payee, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public view returns (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) {
    //paid is true if prepaid (eg as with reservation)
    bool validTerms;
    (validTerms, methodId, currency, fee, durationInSecs) = validateRequestedBorrowTerms(_requestedTerms, _allApprovedTerms);

    bool validPass = true;

    if(methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS){
      validPass = validatePass(_payee, methodId, _requestedTerms, _allApprovedTerms);
    }

    valid = (true == validTerms == validPass);
  }

  function isApprovedPassContract(address _requestedPassContract, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool approved) {
    for(uint256 i = 0; i < _allApprovedTerms.length; i++){
      if(bytes4(_allApprovedTerms[i]) == bytes4(_requestedTerms)){
        if(_requestedPassContract == unpackPassContractTerms(_allApprovedTerms[i])){
          return true;
        }
      }
    }
  }

  function isApprovedPassId(uint256 _requestedPassId, bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool approved) {
    for(uint256 i = 0; i < _allApprovedTerms.length; i++){
      if(bytes4(_allApprovedTerms[i]) == bytes4(_requestedTerms)){
        if(_requestedPassId == unpackPassIdTerms(_allApprovedTerms[i])){
          return true;
        }
      }
    }
  }

  function validatePass(address _passHolder, bytes4 _methodId, bytes memory _requestTerms, bytes[] memory _allApprovedTerms) public view returns (bool valid){
    address requestedPassContract = unpackPassContractTerms(_requestTerms);

    if(!isApprovedPassContract(requestedPassContract, _requestTerms, _allApprovedTerms)){
      return false;
    }

    if(_methodId == _METHOD_ID_BORROW_RESERVED_WITH_721_PASS || _methodId == _METHOD_ID_BORROW_WITH_721_PASS){
      if(IERC721(requestedPassContract).balanceOf(_passHolder) < 1){
        return false;
      }
    }else if(_methodId == _METHOD_ID_BORROW_RESERVED_WITH_1155_PASS || _methodId == _METHOD_ID_BORROW_WITH_1155_PASS){
      uint256 requestedPassId = unpackPassIdTerms(_requestTerms);

      if(!isApprovedPassId(requestedPassId, _requestTerms, _allApprovedTerms)){
        return false;
      }

      if(IERC1155(requestedPassContract).balanceOf(_passHolder, requestedPassId) < 1){
        return false;
      }
    }
    return true;
  }

  function validateRequestedBorrowTerms(bytes memory _requestedTerms, bytes[] memory _allApprovedTerms) public pure returns (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) {
    methodId = bytes4(_requestedTerms);

    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_RESERVED || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS){

      for(uint256 i = 0; i < _allApprovedTerms.length; i++){
        if(bytes4(_allApprovedTerms[i]) == methodId){
          (address approvedCurrency, uint256 approvedFeeInWeiPerSec, uint256 approvedMaxDurationInSecs) = unpackBorrowTerms(_allApprovedTerms[i]);

          (address requestedCurrency, uint requestedTotalFeeInWei, uint256 requestedDurationInSecs) = unpackBorrowTerms(_requestedTerms);

          require(requestedCurrency == approvedCurrency, "RequestLib: request currency invalid");

          fee = requestedDurationInSecs * approvedFeeInWeiPerSec;
          require(requestedTotalFeeInWei >= fee, "RequestLib: requested fee insufficient for requested duration");

          require(requestedDurationInSecs <= approvedMaxDurationInSecs, "RequestLib: requested duration exceeds max");

          valid = true;
          currency = approvedCurrency;
          durationInSecs = requestedDurationInSecs;
          break;
        }
      }
    //}else if(request == _METHOD_ID_BORROWTO){

    //}
    }
  }

  function isPaymentOutstanding(bytes memory _requestedTerms) public pure returns (bool outstanding) {
    bytes4 methodId = bytes4(_requestedTerms);
    if(methodId == _METHOD_ID_BORROW || methodId == _METHOD_ID_BORROW_WITH_721_PASS || methodId == _METHOD_ID_BORROW_WITH_1155_PASS) {
      return true;
    }
  }

  /// @dev Checks if a time window is already reserved in an
  /// array of reservations ordered by ascending start times
  function isReserved(uint256 _endTime, uint256[] memory _startTimes, bytes[] memory _terms) public pure returns (bool reserved, uint256 nextIndex) {
    uint256[] memory endTimes = new uint256[](_startTimes.length);

    for(uint256 i = 0; i < _startTimes.length; i++){
      endTimes[i] = _startTimes[i] + getDuration(_terms[i]) -1;
    }

    //insert reservation
    for(uint256 i = 0; i <= _startTimes.length; i++){
      nextIndex = i;
      if(i == _startTimes.length){
        return (false, i);
      }

      if(endTimes[i] > _endTime){
        if(_startTimes[i] > _endTime){
          break;
        }else{
          return (true, 0);
        }
      }
    }
    reserved = false;
  }

  function reservedFor(uint256 _time, address[] memory _reservees, uint256[] memory _startTimes, bytes[] memory _terms) public pure returns (bool reserved, uint256 index, uint256 endTime) {
    for(uint256 i = 0; i < _startTimes.length; i++){
      if(_startTimes[i] <= _time){
        endTime = _startTimes[i] + getDuration(_terms[i]);
        if(_time <= endTime){
          reserved = true;
          index = i;
        }
      }
    }
  }

}
