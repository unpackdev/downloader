//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./ERC721DC.sol";
import "./ReentrancyGuard.sol";
import "./IDawnChorus.sol";

contract DawnChorus is ERC721DC, ReentrancyGuard, IDawnChorus {

  struct Exhibition {
    uint256 startTime;
    uint256 endTime;
    string occasion;
    string institution;
    string location;
    RequestStatus status;
    string uri;
  }

  struct TokenInfo {
    address owner;
    address designatedRecipient;
    RequestType requestType;
    RequestStatus requestStatus;
    uint256 salePrice;
    uint256 previousSalePrice;
    Exhibition exhibition;
  }

  // Mapping token ID to the address of the potential buyer
  mapping(uint256 => address) private _designatedRecipient;

  // Mapping token ID to the status of the request
  mapping(uint256 => RequestStatus) private _requestStatuses;

  // Mapping token ID to the type of request
  mapping(uint256 => RequestType) private _requestTypes;

  // Mapping token ID to the current sale price
  mapping(uint256 => uint256) private _salePrices;

  // Mapping token ID to the previous sale price
  mapping(uint256 => uint256) private _previousSalePrices;

  // Mapping token ID to exhibition request status
  mapping(uint256 => Exhibition) private _currentExhibitions;

  constructor() ERC721DC("Dawn Chorus", "DC") {
    _safeMint(msg.sender, 0);

    _safeMint(msg.sender, 1);
    _safeMint(msg.sender, 2);
    _safeMint(msg.sender, 3);
  }

  modifier onlyTokenOperator(uint256 tokenId) {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: transfer caller is not owner nor approved"
    );
    _;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyTokenOperator(tokenId) {
    require(
      _isApprovedOrOwner(_msgSender(), 0) ||
      (
      _requestStatuses[tokenId] == RequestStatus.OK &&
      _requestTypes[tokenId] == RequestType.TRANSFER &&
      _designatedRecipient[tokenId] == to
      ), "DC: caller is not the artist and transfer was not approved"
    );

    _transfer(from, to, tokenId);

    delete _designatedRecipient[tokenId];
    delete _requestStatuses[tokenId];
    delete _requestTypes[tokenId];
    if (tokenId == 0) {
      emit OwnershipTransferred(from, to);
    }
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override onlyTokenOperator(tokenId) {
    require(
      _isApprovedOrOwner(_msgSender(), 0) ||
      (
      _requestStatuses[tokenId] == RequestStatus.OK &&
      _requestTypes[tokenId] == RequestType.TRANSFER &&
      _designatedRecipient[tokenId] == to
      ), "DC: caller is not the artist and transfer was not approved");

    _safeTransfer(from, to, tokenId, _data);

    delete _designatedRecipient[tokenId];
    delete _requestStatuses[tokenId];
    delete _requestTypes[tokenId];
    if (tokenId == 0) {
      emit OwnershipTransferred(from, to);
    }
  }

  function setTokenURI(
    uint256 tokenId,
    string memory uri
  ) public onlyTokenOperator(0) {
    _setTokenURI(tokenId, uri);
  }

  function requestSale(
    uint256 tokenId,
    address to,
    uint256 price
  ) public onlyTokenOperator(tokenId) {
    _requestStatuses[tokenId] = RequestStatus.PENDING;
    _requestTypes[tokenId] = RequestType.SALE;
    _designatedRecipient[tokenId] = to;
    _salePrices[tokenId] = price;

    emit TransferRequest(tokenId, to, RequestType.SALE);
  }

  function requestTransfer(
    uint256 tokenId,
    address to
  ) public onlyTokenOperator(tokenId) {
    _requestStatuses[tokenId] = RequestStatus.PENDING;
    _requestTypes[tokenId] = RequestType.TRANSFER;
    _designatedRecipient[tokenId] = to;

    emit TransferRequest(tokenId, to, RequestType.TRANSFER);
  }

  function requestExhibition(
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    string calldata occasion,
    string calldata institution,
    string calldata location,
    string calldata uri
  ) public onlyTokenOperator(tokenId) {
    require(tokenId != 0, "DC: can't exhibit token 0");
    require(
      _currentExhibitions[tokenId].status == RequestStatus.NONE,
      "DC: exhibition request pending or already approved"
    );

    _currentExhibitions[tokenId].startTime = startTime;
    _currentExhibitions[tokenId].endTime = endTime;
    _currentExhibitions[tokenId].status = RequestStatus.PENDING;
    _currentExhibitions[tokenId].occasion = occasion;
    _currentExhibitions[tokenId].institution = institution;
    _currentExhibitions[tokenId].location = location;
    _currentExhibitions[tokenId].uri = uri;

    emit ExhibitionRequest(
      tokenId,
      startTime,
      endTime,
      occasion,
      institution,
      location,
      uri
    );
  }

  function retractRequest(uint256 tokenId) public onlyTokenOperator(tokenId) {
    emit TransferRequestCancellation(
      tokenId,
      _designatedRecipient[tokenId],
      _requestTypes[tokenId]
    );
    delete _requestStatuses[tokenId];
    delete _requestTypes[tokenId];
    delete _designatedRecipient[tokenId];
  }

  function retractExhibitionRequest(
    uint256 tokenId
  ) public onlyTokenOperator(tokenId) {
    require(
      _currentExhibitions[tokenId].status != RequestStatus.NONE,
      "DC: nothing to do"
    );

    emit ExhibitionRequestCancellation(
      tokenId,
      _currentExhibitions[tokenId].startTime,
      _currentExhibitions[tokenId].endTime,
      _currentExhibitions[tokenId].uri
    );
    delete _currentExhibitions[tokenId];
  }

  function approveTransfer(uint256 tokenId, address to) public onlyTokenOperator(0) {
    require(
      _requestStatuses[tokenId] == RequestStatus.PENDING,
      "DC: token is not awaiting approval"
    );
    require(
      _requestTypes[tokenId] == RequestType.TRANSFER,
      "DC: token is not for transfer"
    );
    require(
      _designatedRecipient[tokenId] == to,
      "DC: token designated recipient mismatch"
    );

    emit TransferApproval(tokenId, to, RequestType.TRANSFER);

    _requestStatuses[tokenId] = RequestStatus.OK;
  }

  function approveSale(uint256 tokenId, address to, uint256 price) public onlyTokenOperator(0) {
    require(
      _requestStatuses[tokenId] == RequestStatus.PENDING,
      "DC: token is not awaiting sale approval"
    );
    require(
      _requestTypes[tokenId] == RequestType.SALE,
      "DC: token is not for sale"
    );
    require(
      _designatedRecipient[tokenId] == to,
      "DC: token designated recipient mismatch"
    );
    require(_salePrices[tokenId] == price, "DC: token sale price mismatch");

    _requestStatuses[tokenId] = RequestStatus.OK;

    emit TransferApproval(tokenId, to, RequestType.SALE);
  }

  function approveExhibition(
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    string calldata occasion,
    string calldata institution,
    string calldata location,
    string calldata uri
  ) public onlyTokenOperator(0) {
    require(
      _currentExhibitions[tokenId].status == RequestStatus.PENDING,
      "DC: exhibition was not requested or was already approved"
    );
    require(
      startTime == _currentExhibitions[tokenId].startTime,
      "DC: start time mismatch"
    );
    require(
      endTime == _currentExhibitions[tokenId].endTime,
      "DC: end time mismatch"
    );
    require(
      keccak256(abi.encode(occasion)) == keccak256(abi.encode(_currentExhibitions[tokenId].occasion)),
      "DC: occasion mismatch"
    );
    require(
      keccak256(abi.encode(institution)) == keccak256(abi.encode(_currentExhibitions[tokenId].institution)),
      "DC: institution mismatch"
    );
    require(
      keccak256(abi.encode(location)) == keccak256(abi.encode(_currentExhibitions[tokenId].location)),
      "DC: location mismatch"
    );
    require(
      keccak256(abi.encode(uri)) == keccak256(abi.encode(_currentExhibitions[tokenId].uri)),
      "DC: uri mismatch"
    );

    _currentExhibitions[tokenId].status = RequestStatus.OK;
    emit ExhibitionApproval(ownerOf(tokenId), tokenId, startTime);
  }

  function buy(uint256 tokenId) public payable nonReentrant {
    require(
      _requestStatuses[tokenId] == RequestStatus.OK,
      "DC: sale was not approved"
    );
    require(
      _requestTypes[tokenId] == RequestType.SALE,
      "DC: token is not for sale"
    );
    require(
      msg.value == _salePrices[tokenId],
      "DC: you must send the right amound"
    );

    uint256 royalty = 0;
    if (_salePrices[tokenId] > _previousSalePrices[tokenId]) {
      royalty = (_salePrices[tokenId] - _previousSalePrices[tokenId]) * 15 / 100;
      (bool royaltySuccess, ) = ownerOf(0).call{value: royalty}("");
      require(royaltySuccess, "DC: royalty payment failed");
    }
    (bool success, ) = ownerOf(tokenId).call{value: (msg.value - royalty)}("");
    require(success, "DC: payment failed");
    _previousSalePrices[tokenId] = msg.value;
    delete _salePrices[tokenId];
    delete _designatedRecipient[tokenId];
    delete _requestStatuses[tokenId];
    delete _requestTypes[tokenId];
    _transfer(ownerOf(tokenId), msg.sender, tokenId);
  }

  function getTokenInfos(uint256 tokenId) public view returns(TokenInfo memory) {
    TokenInfo memory info = TokenInfo({
      owner: ownerOf(tokenId),
      designatedRecipient: _designatedRecipient[tokenId],
      requestType: _requestTypes[tokenId],
      requestStatus: _requestStatuses[tokenId],
      salePrice: _salePrices[tokenId],
      previousSalePrice: _previousSalePrices[tokenId],
      exhibition: _currentExhibitions[tokenId]
    });
    return info;
  }

  function owner() public view returns (address) {
    return ownerOf(0);
  }
}
