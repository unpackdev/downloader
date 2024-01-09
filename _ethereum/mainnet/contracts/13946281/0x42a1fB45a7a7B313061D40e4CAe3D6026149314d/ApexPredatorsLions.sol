// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract ApexPredatorsLions is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter public _mintIds;
  Counters.Counter public _claimIds;

  // Smart contract status
  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC
  }
  MintStatus public status = MintStatus.CLOSED;

  // ERC721 params
  string private _tokenName = "Apex Predators Lions";
  string private _tokenId = "APL";
  string private _baseTokenURI = "https://claim.apexpredatorsnft.com/api/metadata/";

  // Withdraw address
  address public withdraw_address = 0x43Efca78533eb8616679F5F2C7db2EE94Af9582D;

  // Collection params
  uint256 public constant TOT = 1000;
  uint256 public constant PRICE = 1 ether;
  uint256[3] public MAX_PER_STATUS = [0, 5, 5];

  // Premint list
  mapping(address => bool) private _presaleList;
  mapping(address => uint256) private _presaleClaimed;

  // Event declaration
  event MintEvent(uint256 indexed id);
  event ChangedStatusEvent(uint256 newStatus);
  event ChangedBaseURIEvent(string newURI);
  event ChangedWithdrawAddress(address newAddress);

  // Modifier to check claiming requirements
  modifier onlyIfAvailable(uint256 _qty) {
    require(status != MintStatus.CLOSED, "Minting is closed");
    require(_qty > 0, "NFTs amount must be greater than zero");
    require(_qty <= MAX_PER_STATUS[uint256(status)], "Exceeded the max amount of claimable NFT");
    require(_claimIds.current() < _mintIds.current(), "Collection is sold out");
    require(_claimIds.current() + _qty <= _mintIds.current(), "Not enough NFTs available");
    require(msg.value == PRICE * _qty, "Ether sent is not correct");
    _;
  }

  // Constructor
  constructor() ERC721(_tokenName, _tokenId) { }

  // Owner mint function
  function ownerMint(uint256 _qty) external nonReentrant onlyOwner {
    require(_qty > 0, "qty must be positive");
    require(_mintIds.current() < TOT, "Collection is sold out");
    require(_mintIds.current() + _qty <= TOT, "Not enough NFTs available");

    for (uint i = 0; i < _qty; i++){
        _mintIds.increment();
        _safeMint(msg.sender, _mintIds.current());
        emit MintEvent(_mintIds.current());
    }

  }

  // Public claim
  function claim(uint256 _qty) external payable nonReentrant onlyIfAvailable(_qty){
      if(status == MintStatus.PRESALE){
          require(_presaleList[msg.sender] == true, "You are not in the presale list");
          require(_presaleClaimed[msg.sender] + _qty <= MAX_PER_STATUS[uint256(status)], "Not enough NFTs available in presale");
          _presaleClaimed[msg.sender] += _qty;
      }

      for (uint i = 0; i < _qty; i++) {
          _claim();
      }
  }

  // Private claim
  function _claim() private {
      require(_exists(_claimIds.current() + 1), "Token does not exists");
      _claimIds.increment();
      _safeTransfer(ownerOf(_claimIds.current()), msg.sender, _claimIds.current(), "");
  }

  // Presale list: Add addresses to presale list
  function addToPresaleList(address[] calldata _addresses)
    external
    onlyOwner
  {
    require(_addresses.length > 0, "List is empty");
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(!_presaleList[_addresses[i]], "Already in presale list");
      _presaleList[_addresses[i]] = true;
    }
  }

  // Getters
  function tokenExists(uint256 _id) public view returns (bool) {
    return _exists(_id);
  }

  function getStatus() external view returns(string memory status_, uint qty_, uint price_, string memory msg_, uint256 available_){
    uint256 _available = availableToClaim();
    if(_available == 0){
      return ("SOLD OUT", 0, PRICE, "Sold out", 0);
    }
      if(status == MintStatus.CLOSED){
          return ("CLOSED", MAX_PER_STATUS[uint256(status)], PRICE, "Minting is closed", _available);
      } else if  (status == MintStatus.PRESALE){
          if(_presaleList[msg.sender] == true) {
            if(_presaleClaimed[msg.sender] < MAX_PER_STATUS[uint256(status)] ) {
                  return ("PRESALE", MAX_PER_STATUS[uint256(status)] - _presaleClaimed[msg.sender], PRICE, "You are in presale", _available);
              } else {
                  return( "PRESALE", 0, PRICE, "You already claimed your presale", _available);
              }
          } else {
              return ("PRESALE", 0, PRICE, "You are not in presale", _available);
          }
      } else {
          return ("PUBLIC", MAX_PER_STATUS[uint256(status)], PRICE, "Public sale", _available);
      }
  }

  function availableToClaim() public view  returns (uint256){
    return _mintIds.current() - _claimIds.current();
  }

  function _baseURI()
    internal view virtual
    override(ERC721)
    returns (string memory)
  {
    return _baseTokenURI;
  }

  // Setters
  function setStatus(uint8 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: PRESALE, 2: PUBLIC
    require(_status >= 0 && _status <= 2, "Mint status must be between 0 and 2");
    status = MintStatus(_status);
    emit ChangedStatusEvent(_status);
  }

  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
    emit ChangedBaseURIEvent(_URI);
  }

  function setWithdrawAddress(address _withdraw) external onlyOwner {
    withdraw_address = _withdraw;
    emit ChangedWithdrawAddress(_withdraw);
  }

  // Withdraw function
  function withdrawAll() external payable nonReentrant onlyOwner {
    require(address(this).balance != 0, "Balance is zero");
    payable(withdraw_address).transfer(address(this).balance);
  }
}