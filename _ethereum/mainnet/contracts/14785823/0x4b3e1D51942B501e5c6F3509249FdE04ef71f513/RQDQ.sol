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

import "./ERC721Dispatcher.sol";
import "./IReservationBook.sol";

/**
 * @title RQDQ
 * @dev ERC721Dispatcher for ERC721Delegable tokens.
 * @author 0xAnimist (kanon.art)
 */
contract RQDQ is ERC721Dispatcher {

  IReservationBook private reservationBook;

  bool public initialized = false;

  // Basic terms
  struct TermBase {
    address currency;
    uint256 fee;
    uint256 durationInSecs;
  }

  /**
   * @dev Initializes the contract by setting a `name` and `symbol`for the token collection and initializes admin and platformFeeRecipient to contract deployer.
   */
  constructor(address _defaultCurrency, address _ERC721DispatcherURI) ERC721("RQDQ", "sDQ") {
    admin = _msgSender();
    platformFeeRecipient = _msgSender();
    defaultCurrency = _defaultCurrency;
    _SERVED_METHOD_IDs = [
      DispatchLib._METHOD_ID_BORROW,
      DispatchLib._METHOD_ID_BORROW_RESERVED,
      DispatchLib._METHOD_ID_BORROW_WITH_721_PASS,
      DispatchLib._METHOD_ID_BORROW_RESERVED_WITH_721_PASS,
      DispatchLib._METHOD_ID_BORROW_WITH_1155_PASS,
      DispatchLib._METHOD_ID_BORROW_RESERVED_WITH_1155_PASS
    ];
    ERC721DispatcherURI = _ERC721DispatcherURI;
  }

  function initialize(address _reservationBook) external {
    require(_msgSender() == admin, "only admin");
    reservationBook = IReservationBook(_reservationBook);
    initialized = true;
  }

  function setDefaultMaxReservations(uint256 _defaultMaxReservations) external {
    require(_msgSender() == admin, "only admin");
    reservationBook.setDefaultMaxReservations(_defaultMaxReservations);
  }

  function setMaxReservations(uint256 _maxReservations, uint256 _tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "only owner");
    uint256[] memory tokenId = new uint256[](1);
    tokenId[0] = _tokenId;
    uint256[] memory maxReservations = new uint256[](1);
    maxReservations[0] = _maxReservations;
    reservationBook.setMaxReservations(maxReservations, tokenId);
  }

  function depositWithMaxReservations(address[] memory _RQContract, uint256[] memory _RQTokenId, bytes[][] memory _terms, uint256[] memory _maxReservations, bytes calldata _data) public virtual returns (uint256[] memory tokenIds) {
    tokenIds = ERC721Dispatcher.deposit(_RQContract, _RQTokenId, _terms, _data);
    reservationBook.setMaxReservations(_maxReservations, tokenIds);
  }

  function getReservationBook() external view returns (address) {
    require(initialized, "not init");
    return address(reservationBook);
  }

  /**
   * @dev Hook that allows for withdrawing withheld fees accrued outside of this contract.
   */
  function _refundAltWithholding(address _currency, uint256 _tokenId) internal virtual override {
    /* Hook */
    reservationBook.purgeExpired(_tokenId);
    reservationBook.refundFutureReservations(_currency, _tokenId);
  }

  function _claimAltFeesAccrued(address _currency, uint256 _tokenId) internal virtual override returns (bool success, uint256 alternateFeesClaimedInWei){
    uint256 openingBalance= _getThisBalance(_currency);

    (success, alternateFeesClaimedInWei) = reservationBook.claimFeesAccrued(_currency, _tokenId);

    uint256 currentBalance = _getThisBalance(_currency);
    success = success && ((currentBalance - openingBalance) == alternateFeesClaimedInWei);
  }

  function _getThisBalance(address _currency) internal view returns (uint256 balance){
    if(_currency == address(0)){//ETH
      balance = address(this).balance;
    }else{//ERC20
      balance = IERC20(_currency).balanceOf(address(this));
    }
  }

  function _processAltRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal virtual override returns (bool) {
    //pass _payee in case requires a pass that _payee must hold
    (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) = DispatchLib.validateRequest(_payee, _requestedTerms, _deposits[_tokenId].terms);
    require(valid, "inv alt req");

    if(DispatchLib.isReserveRequest(methodId)){//attempting to claim a reservation
      require(reservationBook.validateReservation(_to, _tokenId, _requestedTerms), "inv alt res");

      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;
    }else if(methodId == DispatchLib._METHOD_ID_BORROW_WITH_721_PASS || methodId == DispatchLib._METHOD_ID_BORROW_WITH_1155_PASS){
      require(DispatchLib.validatePass(_payee, methodId, _requestedTerms, _deposits[_tokenId].terms), "inv pass");

      require(isAvailable(_tokenId), "alt not avail");

      //process payment and update accounting
      _receivePayment(_payee, currency, fee);
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = fee;

      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;
    }else{
      return false;
    }
    return true;
  }
}
