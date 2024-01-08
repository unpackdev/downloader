// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Utils.sol";
import "./Signature.sol";
import "./Domain.sol";
import "./TLD.sol";
import "./Settings.sol";

contract Ordering is Ownable {
  using SafeMath for uint256;
  bool public initialized;
  Settings settings;
  
  struct AcquisitionOrder {
      address payable custodianAddress;
      address requester;
      uint256 acquisitionType;
      uint256 acquisitionFee;
      uint256 paidAcquisitionFee;
      uint256 transferInitiated;
      uint256 acquisitionSuccessful;
      uint256 acquisitionFail;
      uint256 acquisitionYears;
      uint256 validUntil;
      uint256 custodianNonce;
      uint256 reservedId;
  }

  mapping(bytes32=>AcquisitionOrder) acquisitionOrders;

  event AcquisitionOrderCreated(address custodianAddress,
                                  address requesterAddress,
                                  bytes32 domainHash,
                                  uint256 acquisitionType,
                                  uint256 custodianNonce,
                                  bytes acquisitionCustodianEncryptedData);
    event TransferInitiated( bytes32 domainHash );
    event DomainAcquisitionPaid(bytes32 domainHash,
                                uint256 acquisitionFeePaid);
    
    event AcquisitionSuccessful(bytes32 domainHash,
                                string domainName,
                                uint256 acquisitionType);
    
    event AcquisitionFailed(bytes32 domainHash);
    
    event AcquisitionPaid(bytes32 domainHash,
                          string domainName,
                          uint256 amount);
    event RefundPaid(bytes32 domainHash,
                     address requester,
                     uint256 amount);
    event OrderCancel(bytes32 domainHash);
    
    event TokenExpirationExtension(bytes32 domainHash,
                                   uint256 tokenId,
                                   uint256 extensionTime);
    
  
  enum OrderStatus {
      UNDEFINED, // 0
      OPEN, // 1
      ACQUISITION_CONFIRMED, // 2
      ACQUISITION_FAILED, // 3
      EXPIRED, // 4
      TRANSFER_INITIATED // 5
  }
  
  enum OrderType {
      UNKNOWN, // should not be used
      REGISTRATION, // 1
      TRANSFER, // 2
      EXTENSION // 3
  }
  constructor(){
    
  }

  
  function initialize(Settings _settings) public onlyOwner {
    require(!initialized, "Contract instance has already been initialized");
    initialized = true;
    settings = _settings;
  }

  function user() public view returns(User){
      return User(settings.getNamedAddress("USER"));
  }
      
  function getAcquisitionOrder(bytes32 domainHash) public view returns(AcquisitionOrder memory){
      return acquisitionOrders[domainHash];
  }
  
  function getAcquisitionOrderByDomainName(string memory domainName) public view returns(AcquisitionOrder memory){
      bytes32 domainHash = Utils.hashString(domainName);
      return acquisitionOrders[domainHash];
  }
  
  
  function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
  }

  function tld() public view returns(TLD){
      return TLD(payable(settings.getNamedAddress("TLD")));
  }
  function tokenCreationFee(bytes32 domainHash)
    public
    view
    returns(uint256){
    return tld().rprice(acquisitionOrders[domainHash].reservedId);
      
  }
    
  
  function minimumOrderValidityTime(uint256 orderType)
      public
      view
      returns (uint256) {
      if(orderType == uint256(OrderType.REGISTRATION)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_REGISTRATION");
      }
      if(orderType == uint256(OrderType.TRANSFER)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_TRANSFER");
      }
      if(orderType == uint256(OrderType.EXTENSION)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_EXTENSION");
      }
      return 0;
  }

  
    function orderStatus(bytes32 domainHash)
        public
        view
        returns (uint256) {
         if(isOrderConfirmed(domainHash)){
            return uint256(OrderStatus.ACQUISITION_CONFIRMED);
        }
        if(isOrderFailed(domainHash)){
            return uint256(OrderStatus.ACQUISITION_FAILED);
        }
        
        if(isTransferInitiated(domainHash)){
          return uint256(OrderStatus.TRANSFER_INITIATED);
        }
        if(isOrderExpired(domainHash)){
            return uint256(OrderStatus.EXPIRED);
        }
        
        if(isOrderOpen(domainHash)){
            return uint256(OrderStatus.OPEN);
        }
        
        return uint256(OrderStatus.UNDEFINED);
    }
    
    function orderExists(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return acquisitionOrders[domainHash].validUntil > 0;
      
    }

    function isOrderExpired(bytes32 domainHash)
        public
        view
        returns (bool){
        return acquisitionOrders[domainHash].validUntil > 0
            && acquisitionOrders[domainHash].validUntil < block.timestamp
            && acquisitionOrders[domainHash].transferInitiated == 0
            && acquisitionOrders[domainHash].acquisitionSuccessful == 0
            && acquisitionOrders[domainHash].acquisitionFail == 0;
    }
    
    function isOrderOpen(bytes32 domainHash)
      public
      view
      returns (bool){
      return acquisitionOrders[domainHash].validUntil > block.timestamp
        || isOrderConfirmed(domainHash)
        || isTransferInitiated(domainHash);
    }
    
    function isOrderConfirmed(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return acquisitionOrders[domainHash].acquisitionSuccessful > 0;
      
    }
    
    function isOrderFailed(bytes32 domainHash)
      public
      view
      returns (bool){

      return acquisitionOrders[domainHash].acquisitionFail > 0;
      
    }

    function isTransferInitiated(bytes32 domainHash)
      public
      view
      returns(bool){
      return acquisitionOrders[domainHash].transferInitiated > 0;
    }

    function canCancelOrder(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return orderExists(domainHash)
        && acquisitionOrders[domainHash].validUntil > block.timestamp
        && !isOrderConfirmed(domainHash)
        && !isOrderFailed(domainHash)
        && !isTransferInitiated(domainHash);
      
    }
    
    function orderDomainAcquisition(bytes32 domainHash,
                                    address requester,
                                    uint256 acquisitionType,
                                    uint256 acquisitionYears,
                                    uint256 acquisitionFee,
                                    uint256 acquisitionOrderTimestamp,
                                    uint256 custodianNonce,
                                    bytes memory signature,
                                    bytes memory acquisitionCustodianEncryptedData)
      public
      payable {
        require(user().isActive(requester), "Requester must be an active user");
        require(acquisitionOrderTimestamp > block.timestamp.sub(settings.getNamedUint("ACQUISITION_ORDER_TIME_WINDOW")),
              "Try again with a fresh acquisition order");

      bytes32 message = keccak256(abi.encode(requester,
                                             acquisitionType,
                                             acquisitionYears,
                                             acquisitionFee,
                                             acquisitionOrderTimestamp,
                                             custodianNonce,
                                             domainHash));
      
      address custodianAddress = Signature.recoverSigner(message,signature);
      
      require(settings.hasNamedRole("CUSTODIAN", custodianAddress),
              "Signer is not a registered custodian");
      
      if(isOrderOpen(domainHash)){
        revert("An order for this domain is already active");
      }

      if(acquisitionType == uint256(OrderType.EXTENSION)){
        require(domainToken().tokenForHashExists(domainHash), "Token for domain does not exist");
      }
      
      require(msg.value >= acquisitionFee,
              "Acquisition fee must be paid upfront");
      uint256 reservedId = tld().reserveMint();
      acquisitionOrders[domainHash] = AcquisitionOrder(
                                                       payable(custodianAddress),
                                                       requester,
                                                       acquisitionType,
                                                       acquisitionFee,
                                                       0, // paidAcquisitionFee
                                                       0, // transferInitiated
                                                       0, // acquisitionSuccessful flag,
                                                       0, // acquisitionFail flag,
                                                       acquisitionYears,
                                                       block.timestamp.add(minimumOrderValidityTime(acquisitionType)), //validUntil,
                                                       custodianNonce,
                                                       reservedId
                                                       );
        
      emit  AcquisitionOrderCreated(custodianAddress,
                                    requester,
                                    domainHash,
                                    acquisitionType,
                                    custodianNonce,
                                    acquisitionCustodianEncryptedData);
      
    }
    modifier onlyCustodian() {
      require(settings.hasNamedRole("CUSTODIAN", _msgSender())
              || _msgSender() == owner(),
              "Must be a custodian");
      _;
    }

    function transferInitiated(bytes32 domainHash)
      public onlyCustodian {
      require(acquisitionOrders[domainHash].validUntil > 0,
              "Order does not exist");
      require(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.TRANSFER),
              "Order is not Transfer");
      require(acquisitionOrders[domainHash].transferInitiated == 0,
              "Already marked");
      acquisitionOrders[domainHash].transferInitiated = block.timestamp;
      if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
         && acquisitionOrders[domainHash].acquisitionFee > 0){

        uint256 communityFee = Utils.calculatePercentageCents(acquisitionOrders[domainHash].acquisitionFee,
                                                           settings.getNamedUint("COMMUNITY_FEE"));
        address payable custodianAddress = acquisitionOrders[domainHash].custodianAddress;
        uint256 custodianFee = acquisitionOrders[domainHash].acquisitionFee.sub(communityFee);
        acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
        custodianAddress.transfer(custodianFee);
        payable(address(tld())).transfer(communityFee);
          
      }
      emit TransferInitiated(domainHash);
    }
    
    function domainToken() public view returns(Domain){
        return Domain(settings.getNamedAddress("DOMAIN"));
    }
    function acquisitionSuccessful(string memory domainName)
      public onlyCustodian {
        bytes32 domainHash = domainToken().registryDiscover(domainName);
        require(acquisitionOrders[domainHash].validUntil > 0,
                "Order does not exist");
        require(acquisitionOrders[domainHash].acquisitionSuccessful == 0,
                "Already marked");
        if(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.TRANSFER)
           && acquisitionOrders[domainHash].transferInitiated == 0){
          revert("Transfer was not initiated");
        }
        acquisitionOrders[domainHash].acquisitionSuccessful = block.timestamp;
        acquisitionOrders[domainHash].acquisitionFail = 0;
       
        if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
           && acquisitionOrders[domainHash].acquisitionFee > 0){
          uint256 communityFee = Utils.calculatePercentageCents(acquisitionOrders[domainHash].acquisitionFee,
                                                             settings.getNamedUint("COMMUNITY_FEE"));
          address payable custodianAddress = acquisitionOrders[domainHash].custodianAddress;
          uint256 custodianFee = acquisitionOrders[domainHash].acquisitionFee.sub(communityFee);
          acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
          custodianAddress.transfer(custodianFee);
          payable(address(tld())).transfer(communityFee);
        }
        uint256 acquisitionType = acquisitionOrders[domainHash].acquisitionType;
        if(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.EXTENSION)){
          
            emit TokenExpirationExtension(domainHash,
                                          domainToken().tokenIdForHash(domainHash),
                                          acquisitionOrders[domainHash].acquisitionYears.mul(365 days));
            delete acquisitionOrders[domainHash];
        }
        
        emit AcquisitionSuccessful(domainHash, domainName, acquisitionType);

    }
    function getAcquisitionYears(bytes32 domainHash) public view returns(uint256){
      return acquisitionOrders[domainHash].acquisitionYears;
    }
    
    function acquisitionFail(bytes32 domainHash)
      public onlyCustodian {
      require(acquisitionOrders[domainHash].validUntil > 0,
              "Order does not exist");
      require(acquisitionOrders[domainHash].acquisitionFail == 0,
              "Already marked");
      acquisitionOrders[domainHash].transferInitiated = 0;
      acquisitionOrders[domainHash].acquisitionSuccessful = 0;
      acquisitionOrders[domainHash].acquisitionFail = block.timestamp;
      if( acquisitionOrders[domainHash].paidAcquisitionFee == 0
          && acquisitionOrders[domainHash].acquisitionFee > 0){
        
        address payable requester = payable(acquisitionOrders[domainHash].requester);
        uint256 refundAmount = acquisitionOrders[domainHash].acquisitionFee;
        requester.transfer(refundAmount);
        
      }
      
      delete acquisitionOrders[domainHash];
      
      emit AcquisitionFailed(domainHash);

    }

    function cancelOrder(bytes32 domainHash)
      public {
      require(canCancelOrder(domainHash),
              "Can not cancel order");
      if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
         && acquisitionOrders[domainHash].acquisitionFee > 0){
        address payable requester = payable(acquisitionOrders[domainHash].requester);
        acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
        if(requester.send(acquisitionOrders[domainHash].acquisitionFee)){

            emit RefundPaid(domainHash, requester, acquisitionOrders[domainHash].acquisitionFee);

        }
      }
      delete acquisitionOrders[domainHash];
      emit OrderCancel(domainHash);
    }

    function canClaim(bytes32 domainHash)
      public view returns(bool){
      return (acquisitionOrders[domainHash].validUntil > 0 &&
              acquisitionOrders[domainHash].acquisitionFail == 0 &&
              acquisitionOrders[domainHash].acquisitionSuccessful > 0 &&
              !domainToken().tokenForHashExists(domainHash));
      
    }
        
    function orderRequester(bytes32 domainHash)
      public view returns(address){
      return acquisitionOrders[domainHash].requester;
    }

    function computedExpirationDate(bytes32 domainHash)
      public view returns(uint256){
      return acquisitionOrders[domainHash].acquisitionSuccessful
        .add(acquisitionOrders[domainHash].acquisitionYears
             .mul(365 days));
    }
    function tldOrderReservedId(bytes32 domainHash)
      public view returns(uint256){
      return acquisitionOrders[domainHash].reservedId;
    }

    function finishOrder(bytes32 domainHash)
      public onlyOwner {
      delete acquisitionOrders[domainHash];
    }
}
