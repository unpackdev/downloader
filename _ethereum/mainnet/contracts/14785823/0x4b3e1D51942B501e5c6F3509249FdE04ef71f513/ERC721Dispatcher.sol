// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC721Metadata.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./ERC165Checker.sol";
import "./IERC721Delegable.sol";
import "./BytesLib.sol";
import "./DispatchLib.sol";
import "./BasisPoints.sol";
import "./IERC721Dispatcher.sol";

interface IERC721DispatcherURI {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title ERC721Dispatcher
 * @dev Abstract Dispatcher contract that allows fee splitting.
 * @author 0xAnimist (kanon.art)
 */
abstract contract ERC721Dispatcher is IERC721Dispatcher, IERC721Receiver, ERC721Enumerable, IERC2981, Ownable, ReentrancyGuard {

  // Contract administrator
  address public admin;

  // Address of contract that renders tokenURI
  address public ERC721DispatcherURI;

  // ERC165 interface ID for ERC2981
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // Array of method IDs served by this contract
  bytes4[] public _SERVED_METHOD_IDs;

  // Stores information for deposited delegate tokens
  struct Deposit {
    bool valid;
    address RQContract;
    uint256 RQTokenId;
    uint256 nextAvailable;
    uint256 withholdingInWei;
    uint256 feesAccruedInWei;
    bytes[] terms;
    address[] recipients;
    uint256[] sharesInBp;
  }

  // Mapping from token ID to Deposited delegate token and its source delegable token
  mapping(uint256 => Deposit) internal _deposits;

  // Mapping from source delegable token to token ID
  mapping(address => mapping(uint256 => uint256)) internal _tokenIdsByDeposit;

  // Counter of total deposits, does not decrement on withdraw
  uint256 internal totalDeposits = 1;

  // Default RQDQ platform fee
  uint256 public defaultPlatformFeeInBp = 500;//5%

  // Recipient of RQDQ platform fee
  address public platformFeeRecipient;

  // Default RQDQ royalty fee
  uint256 public defaultRoyaltyInBp = 1000;//10%

  // Allows depositors to set currencies != defaultCurrency
  bool public settableCurrency = false;

  // Default platform currency
  address public defaultCurrency;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
      return interfaceId == type(IERC721Dispatcher).interfaceId || interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(ERC721Enumerable).interfaceId || interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Sets contract administrator.
   */
  function setAdmin(address _admin) external {
    require(_msgSender() == admin, "only admin can set");
    admin = _admin;
  }

  /**
   * @dev Sets platform parameters.
   */
  function setPlatformParams(address _platformFeeRecipient, uint256 _defaultPlatformFeeInBp, uint256 _defaultRoyaltyInBp, bool _settableCurrency, address _defaultCurrency) external {
    require(_msgSender() == admin, "only admin can set");
    platformFeeRecipient = _platformFeeRecipient;
    defaultPlatformFeeInBp = _defaultPlatformFeeInBp;
    defaultRoyaltyInBp = _defaultRoyaltyInBp;
    defaultCurrency = _defaultCurrency;
    settableCurrency = _settableCurrency;
  }

  /**
   * @dev See {IERC2981-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address receiver, uint256 royaltyAmount) {
    try IERC2981(_deposits[tokenId].RQContract).royaltyInfo(_deposits[tokenId].RQTokenId, salePrice) returns (address _receiver, uint256 _royaltyAmount) {
      return (_receiver, _royaltyAmount);
    } catch {
      return (address(0), 0);
    }
  }


/*TODO: attaches additional RQs to already staked DQ

  function attachToStaked(address[] memory _RQContracts, uint256[] memory _RQTokenIds, bytes[][] memory _terms, uint256 tokenId) public virtual override returns (uint256) {
    require(ownerOf(tokenId) == _msgSender(), "only owner can attach");

    (address delegateContract, uint256 delegateTokenId) = IERC721Delegable(_RQContract[0]).getDelegateToken(_RQTokenId[0]);

  }
  */

  /**
   * @dev See {IERC721Dispatcher-getServedMethodIds}.
   */
  function getServedMethodIds() external view returns (bytes4[] memory methodIds) {
    return _SERVED_METHOD_IDs;
  }

  /**
   * @dev Sets recipients of fees accrued for `_tokenId` token and their relative share.
   * @param _recipients array of recipient addresses
   * @param _sharesInBp relative share in basis points
   * @param _tokenId token
   */
  function setFeeRecipients(address[] memory _recipients, uint256[] memory _sharesInBp, uint256 _tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "only sDQ can set");
    require(_recipients.length == _sharesInBp.length, "one recipient per share");

    uint256 shareTotalInBp;
    for(uint256 i = 0; i < _sharesInBp.length; i++){
      shareTotalInBp += _sharesInBp[i];
    }
    require(shareTotalInBp <= (BasisPoints.BASE - defaultPlatformFeeInBp - defaultRoyaltyInBp), "over 100");

    _deposits[_tokenId].recipients = _recipients;
    _deposits[_tokenId].sharesInBp = _sharesInBp;
  }

  /**
   * @dev See {IERC721Dispatcher-deposit}.
   */
  function deposit(address[] memory _RQContract, uint256[] memory _RQTokenId, bytes[][] memory _terms, bytes calldata _data) public virtual override returns (uint256[] memory tokenIds) {
    tokenIds = new uint256[](_RQContract.length);

    //stake the delegate token; it is the same for all RQs
    (address delegateContract, uint256 delegateTokenId) = IERC721Delegable(_RQContract[0]).getDelegateToken(_RQTokenId[0]);

    tokenIds[0] = _singleDeposit(_RQContract[0], _RQTokenId[0], _terms[0], _data);

    for(uint256 i = 1; i < _RQContract.length; i++){
      (address iDelegateContract, uint256 iDelegateTokenId) = IERC721Delegable(_RQContract[i]).getDelegateToken(_RQTokenId[i]);

      require((iDelegateContract == delegateContract) && (iDelegateTokenId == delegateTokenId), "not same delegate");

      tokenIds[i] = _singleDeposit(_RQContract[i], _RQTokenId[i], _terms[i], _data);
    }

    IERC721(delegateContract).safeTransferFrom(_msgSender(), address(this), delegateTokenId, _data);

    require(IERC721(delegateContract).ownerOf(delegateTokenId) == address(this), "delegate not trans");
  }

  /**
   * @dev Deposits a single delegate token for a single ERC721Delegable token.
   */
  function _singleDeposit(address _RQContract, uint256 _RQTokenId, bytes[] memory _terms, bytes calldata _data) internal virtual returns (uint256 tokenId){
    require(
      address(0) != IERC721Delegable(_RQContract).ownerOf(_RQTokenId),
       "RQ token not minted"
     );
    require(DispatchLib.validateTerms(settableCurrency, defaultCurrency, _terms, _SERVED_METHOD_IDs), "inv terms");

    //record the deposit
    tokenId = totalDeposits++;
    _deposits[tokenId].valid = true;
    _deposits[tokenId].RQContract = _RQContract;
    _deposits[tokenId].RQTokenId = _RQTokenId;
    _deposits[tokenId].terms = _terms;
    _deposits[tokenId].recipients = new address[](0);
    _tokenIdsByDeposit[_RQContract][_RQTokenId] = tokenId;

    //mint the sDQ receipt token
    _safeMint(_msgSender(), tokenId);

    emit Deposited(_RQContract, _RQTokenId, tokenId, _msgSender(), _terms, _data);
  }

  /**
   * @dev See {IERC721Dispatcher-withdraw}.
   */
  function withdraw(uint256 _tokenId, bytes calldata _data) external virtual override nonReentrant {
    require(_exists(_tokenId), "no id");
    require(_msgSender() == ownerOf(_tokenId), "not owner");

    //return the delegate token
    (address delegateTokenContract, uint256 delegateTokenId) = IERC721Delegable(_deposits[_tokenId].RQContract).getDelegateToken(_deposits[_tokenId].RQTokenId);
    IERC721(delegateTokenContract).safeTransferFrom(address(this), _msgSender(), delegateTokenId, _data);

    //payout any unclaimed fees accrued, return withholding if necessary
    (,address currency) = claimFeesAccrued(_tokenId);
    _refundWithholding(currency, _tokenId);
    _refundAltWithholding(currency, _tokenId);

    //invalidate _deposits[_tokenId]
    _deposits[_tokenId].valid = false;

    //burn the sDQ token
    _burn(_tokenId);

    emit Withdrawn(_deposits[_tokenId].RQContract, _deposits[_tokenId].RQTokenId, _tokenId, _msgSender(), _data);
  }

  function _refundWithholding(address _currency, uint256 _tokenId) internal {
    if(block.timestamp < _deposits[_tokenId].nextAvailable && _deposits[_tokenId].withholdingInWei > 0){
      (address RQContract, uint256 RQTokenId) = getDepositByTokenId(_tokenId);
      address withholdingRecipient = IERC721(RQContract).ownerOf(RQTokenId);
      _pay(_currency, withholdingRecipient, _deposits[_tokenId].withholdingInWei);
    }

    _deposits[_tokenId].withholdingInWei = 0;
  }

  /**
   * @dev Hook that allows for withdrawing withheld fees accrued outside of this contract.
   */
   function _refundAltWithholding(address _currency, uint256 _tokenId) internal virtual {
     /* Hook */
   }


  function claimFeesAccrued(uint256 _tokenId) public returns (bool success, address currency){
    //process status of withholding
    if(block.timestamp >= _deposits[_tokenId].nextAvailable){
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = 0;
    }

    //all currencies must be the same, so just use the first one
    (currency,,) = DispatchLib.unpackBorrowTerms(_deposits[_tokenId].terms[0]);

    uint256 alternateFeesAccruedInWei;
    (success, alternateFeesAccruedInWei) = _claimAltFeesAccrued(currency, _tokenId);

    if((_deposits[_tokenId].feesAccruedInWei + alternateFeesAccruedInWei) > 0){
      //includes hook to include alternate fees accrued
      success = success && _payFeesAccruedToAllRecipients(currency, _deposits[_tokenId].feesAccruedInWei + alternateFeesAccruedInWei, _tokenId);
    }
  }

  /**
   * @dev Hook that is called when withdrawing fees accrued in `_currency` currency. Allows for withdrawing fees accrued outside of this contract.
   */
  function _claimAltFeesAccrued(address _currency, uint256 _tokenId) internal virtual returns (bool success, uint256 alternateFeesClaimedInWei){
    /* Hook */
    return (true, 0);
  }

  function _payFeesAccruedToAllRecipients(address _currency, uint256 _feesAccruedInWei, uint256 _tokenId) internal returns (bool success){
    uint256 sharesPaidInWei = 0;
    success = true;

    //pay out platform fee
    if(platformFeeRecipient != address(0)){
      uint256 platformFee = BasisPoints.mulByBp(_feesAccruedInWei, defaultPlatformFeeInBp);
      success = success && _pay(_currency, platformFeeRecipient, platformFee);
      sharesPaidInWei += platformFee;
    }

    //pay out royalty
    (address royaltyRecipient, uint256 royaltyAmount) = royaltyInfo(_tokenId, _feesAccruedInWei);
    if(royaltyRecipient != address(0) && royaltyAmount > 0){
      success = success && _pay(_currency, royaltyRecipient, royaltyAmount);
      sharesPaidInWei += royaltyAmount;
    }

    //pay out shares to all recipients
    for(uint256 i = 0; i < _deposits[_tokenId].recipients.length; i++){
      uint256 shareInWei = BasisPoints.mulByBp(_feesAccruedInWei, _deposits[_tokenId].sharesInBp[i]);
      success = success && _pay(_currency, _deposits[_tokenId].recipients[i], shareInWei);
      sharesPaidInWei += shareInWei;
    }

    //pay remainder to sDQ owner
    address sDQOwner = ownerOf(_tokenId);
    success = success && _pay(_currency, sDQOwner, _feesAccruedInWei - sharesPaidInWei);

    _deposits[_tokenId].feesAccruedInWei = 0;
  }

  function _pay(address _currency, address _recipient, uint256 _amountInWei) internal returns (bool success){
    if(_currency == address(0)){//ETH is the currency
      (success,) = _recipient.call{value: _amountInWei}("");
    }else{//currency is an ERC20
      try IERC20(_currency).transfer(_recipient, _amountInWei) returns (bool transferred){
        success = transferred;
      } catch {}
    }
  }

  /**
   * @dev See {IERC721Dispatcher-setTerms}.
   */
  function setTerms(bytes[] memory _terms, uint256 _tokenId, bytes calldata _data) external virtual override {
    require(_exists(_tokenId), "no id");
    require(_msgSender() == ownerOf(_tokenId), "not owner");

    require(DispatchLib.validateTerms(settableCurrency, defaultCurrency, _terms, _SERVED_METHOD_IDs), "inv terms");

    //must zero out accounts to change currency
    (bool currencyIsDifferent) = DispatchLib.isCurrencyDiff(_terms[0], _deposits[_tokenId].terms[0]);
    if(currencyIsDifferent){
      require((_deposits[_tokenId].feesAccruedInWei == 0) && (_deposits[_tokenId].withholdingInWei == 0), "claim fees or withdraw");
    }

    _deposits[_tokenId].terms = _terms;

    emit TermsSet(_msgSender(), _terms, _tokenId, _data);
  }

  /**
   * @dev See {IERC721Dispatcher-getTerms}.
   */
  function getTerms(uint256 _tokenId) public view virtual override returns (bytes[] memory terms) {
    require(_exists(_tokenId), "no id");
    return _deposits[_tokenId].terms;
  }

  /**
   * @dev Returns the owner-approved terms for borrowing.
   * @param _tokenId token ID
   * @return success true if successful
   * @return currency address of payment currency (address(0) => ETH)
   * @return feeInWeiPerSec per second fee in wei of currency
   * @return maxRentalPeriodInSecs maxiumum single rental period in seconds
   *
  function getBorrowTerms(uint256 _tokenId) external virtual view returns (bool success, address currency, uint256 feeInWeiPerSec, uint256 maxRentalPeriodInSecs){
    require(_exists(_tokenId), "no id");
    return DispatchLib.getBorrowTerms(_deposits[_tokenId].terms);
  }*/

  /**  @dev Gets the deposited RQ NFT contract address and `tokenId` for a given sDQ NFT `_tokenId`
    *  @param _tokenId sDQ NFT tokenId to query
    *  @return contractAddress deposited NFT contract address
    *  @return tokenId deposited NFT tokenId
    */
  function getDepositByTokenId(uint256 _tokenId) public view virtual override returns(address contractAddress, uint256 tokenId) {
    require(_tokenId < totalDeposits, "no id");
    return (_deposits[_tokenId].RQContract, _deposits[_tokenId].RQTokenId);
  }

  /**
   * @dev Gets the sDQ NFT `tokenId` for a given deposited NFT contract address and `tokenId`
   * @param _RQContract deposited NFT contract address
   * @param _RQTokenId deposited NFT tokenId
   * @return success true if successful
   * @return tokenId sDQ NFT token ID
   */
  function getTokenIdByDeposit(address _RQContract, uint256 _RQTokenId) public view returns (bool success, uint256 tokenId) {
    if(_tokenIdsByDeposit[_RQContract][_RQTokenId] > 0){
      return (true, _tokenIdsByDeposit[_RQContract][_RQTokenId]);
    }
    return (false, 0);
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data) external virtual override pure returns(bytes4) {

      return IERC721Receiver.onERC721Received.selector;
  }

  /**
   * @dev See {IERC721Dispatcher-requestApproval}.
   */
  function requestApproval(address _payee, address _to, address _RQContract, uint256 _RQTokenId, bytes memory _terms, bytes calldata _data) external payable virtual override {
    (bool exists, uint256 tokenId) = getTokenIdByDeposit(_RQContract, _RQTokenId);
    require(exists, "no id");

    require(_processRequest(_payee, _to, tokenId, _terms), "fail");

    if(_to != IERC721(_RQContract).getApproved(_RQTokenId) && _to != IERC721(_RQContract).ownerOf(_RQTokenId)){
      IERC721Delegable(_deposits[tokenId].RQContract).approveByDelegate(_payee, _deposits[tokenId].RQTokenId);
    }

    emit ApprovalGranted(_deposits[tokenId].RQContract, _deposits[tokenId].RQTokenId, _to, _msgSender(), _terms, _data);
  }

  function _processRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal returns (bool processed){
    //check if request is served by this contract
    if(DispatchLib.isPaymentOutstanding(_requestedTerms)){
      (bool valid, bytes4 methodId, address currency, uint256 fee, uint256 durationInSecs) = DispatchLib.validateRequest(_payee, _requestedTerms, _deposits[_tokenId].terms);
      require(valid, "inv req");
      require(isAvailable(_tokenId), "not avail");

      //process payment and update accounting
      _receivePayment(_payee, currency, fee);
      _deposits[_tokenId].feesAccruedInWei += _deposits[_tokenId].withholdingInWei;
      _deposits[_tokenId].withholdingInWei = fee;

      //shift availability window
      _deposits[_tokenId].nextAvailable = block.timestamp + durationInSecs;

      return true;
    }else{//hook to process alt request
      return _processAltRequest(_payee, _to, _tokenId, _requestedTerms);
    }
  }

  /**
   * @dev Proceeses payment.
   */
  function _receivePayment(address _payee, address _currency, uint256 _fee) internal {
    if(_fee > 0){
      //collect withholding
      if(_currency != address(0)){//pay in ERC20
        IERC20(_currency).transferFrom(_payee, address(this), _fee);
      }else{//pay in ETH
        require(msg.value >= _fee, "more ETH");
      }
    }
  }

  function _processAltRequest(address _payee, address _to, uint256 _tokenId, bytes memory _requestedTerms) internal virtual returns (bool proceesed) {
    return false;
  }

  /**
   * @dev Returns true if `_tokenId` token is available.
   */
  function isAvailable(uint256 _tokenId) public view returns (bool) {
    if(_deposits[_tokenId].nextAvailable <= block.timestamp){
      return true;
    }
    return false;
  }

  function setERC721DispatcherURI(address _ERC721DispatcherURI) external {
    require(_msgSender() == admin, "only admin");
    ERC721DispatcherURI = _ERC721DispatcherURI;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "no such token");
    return IERC721DispatcherURI(ERC721DispatcherURI).tokenURI(tokenId);
  }

}
