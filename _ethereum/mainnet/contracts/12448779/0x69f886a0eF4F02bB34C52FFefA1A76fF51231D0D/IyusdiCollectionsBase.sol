// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./Console.sol";
import "./IyusdiNftV2.sol";
import "./IIyusdiBondingCurve.sol";

contract IyusdiCollectionsBase {

  struct RequestMintOriginal {
    uint256 mintPercent;
    uint256 burnPercent;
    BondingCurve bondingCurve;
    bytes data;
  }

  struct BondingCurve {
    address curve;
    uint256 curveType;
    uint256[] params;
    uint256 MaxPrints;
  }

  event OriginalMinted (
    uint256 indexed og,
    address bondingCurve,
    uint256[] bondingCurveParms,
    uint32 bondingCurveType,
    uint32 maxPrints,
    uint32 mintPercent,
    uint32 burnPercent
  );

  event PrintBurned(
    uint256 indexed id,
    uint256 price,
    uint256 protocolFee,
    uint256 curatorFee,
    uint256 ogFee,
    uint256 printNumber
  );

  event PrintMinted(
    uint256 indexed id,
    uint256 price,
    uint256 protocolFee,
    uint256 curatorFee,
    uint256 ogFee,
    uint256 printNumber
  );

  address public nft;
  address public owner;
  address public protocol;
  
  uint256 public curatorMintPercent;
  uint256 public curatorBurnPercent;
  uint256 public protocolMintPercent;
  uint256 public protocolBurnPercent;
  mapping (uint256 => uint256) reserves;
  mapping (uint256 => uint256) public ogMintPercent;
  mapping (uint256 => uint256) public ogBurnPercent;
  mapping (uint256 => BondingCurve) public bondingCurves;
  mapping (address => bool) public approveMintOriginals;
  mapping (address => RequestMintOriginal) public requestMintOriginals;
  
  uint256 constant PERCENT_BASE = 10000;

  modifier onlyOwner() {
    require(owner != address(0) && (msg.sender == owner || msg.sender == _getCurator()), "!owner");
    _;
  }

  modifier onlyCurator() {
    require(msg.sender == _getCurator(), "!curator");
    _;
  }

  modifier onlyProtocol() {
    require(msg.sender == protocol, "!protocol");
    _;
  }

  function setNft(address _nft) onlyOwner external {
    require(_nft != address(0), '!nft');
    nft = _nft;
  }

  function transferProtocol(address _protocol) onlyProtocol external {
    require(_protocol != address(0), '!protocol');
    protocol = _protocol;
  }

  function transferOwner(address _owner) onlyOwner external {
    owner = _owner;
  }

  function removeRequestMintOriginal() external {
    _removeRequestMintOriginal();
  }

  function _removeRequestMintOriginal() internal {
    delete requestMintOriginals[msg.sender];
    approveMintOriginals[msg.sender] = false;
  }

  function _validateBondingCurve(BondingCurve memory curve) internal view returns(bool) {
    IIyusdiBondingCurve(curve.curve).getPrintPrice(curve.curveType, 1, curve.params);
    return true;
  }

  function requestMintOriginal(uint256 mintPercent, uint256 burnPercent, BondingCurve memory bondingCurve, bytes memory data) external {
    require(protocolMintPercent + curatorMintPercent + mintPercent <= PERCENT_BASE, '!mintPercent');
    require(protocolBurnPercent + curatorBurnPercent + burnPercent <= PERCENT_BASE, '!burnPercent');
    _validateBondingCurve(bondingCurve);
    requestMintOriginals[msg.sender].mintPercent = mintPercent;
    requestMintOriginals[msg.sender].burnPercent = burnPercent;
    requestMintOriginals[msg.sender].bondingCurve = bondingCurve;
    requestMintOriginals[msg.sender].data = data;
    approveMintOriginals[msg.sender] = false;
  }

  function _getCurator() internal view returns(address) {
    return IyusdiNftV2(nft).curator();
  }

  function _getOgOwner(uint256 og) internal view returns(address) {
    return IyusdiNftV2(nft).originalOwner(og);
  }

  function approveMintOriginal(address user, bool approve) external onlyCurator {
    approveMintOriginals[user] = approve;
  }

  function mintApprovedOriginal() external returns(uint256 id) {
    require(approveMintOriginals[msg.sender], '!approved');
    uint256 mintPercent = requestMintOriginals[msg.sender].mintPercent;
    uint256 burnPercent = requestMintOriginals[msg.sender].burnPercent;
    BondingCurve memory curve = requestMintOriginals[msg.sender].bondingCurve;
    bytes memory data = requestMintOriginals[msg.sender].data;
    id = IyusdiNftV2(nft).mintOriginal(msg.sender, data);
    ogMintPercent[id] = mintPercent;
    ogBurnPercent[id] = burnPercent;
    bondingCurves[id] = curve;
    _removeRequestMintOriginal();
    emit OriginalMinted(id, curve.curve, curve.params, uint32(curve.curveType), uint32(curve.MaxPrints), uint32(mintPercent), uint32(burnPercent));
  }

  function mintPrint(uint256 og, bytes memory data) payable external returns(uint256 id) {
    id = _mintPrintFor(og, msg.sender, data);
  }

  function mintPrintFor(uint256 og, address to, bytes memory data) payable external returns(uint256 id) {
    require(to != address(0), '!for');
    id = _mintPrintFor(og, to, data);
  }

  function _getPrintNumber(uint256 og) internal view returns (uint256) {
    return IyusdiNftV2(nft).originalMintedPrints(og);
  }

  function _getOgId(uint256 og) internal view returns (uint256) {
    return IyusdiNftV2(nft).getOgId(og);
  }

  function getPrintPrice(uint256 og, uint256 printNumber) external view returns(uint256) {
    address ogOwner = _getOgOwner(og);
    require(ogOwner != address(0), '!og');
    BondingCurve storage curve = bondingCurves[og];
    return _getPrintPrice(printNumber, curve);
  }

  function getBurnPrice(uint256 og, uint256 printNumber) external view returns(uint256) {
    address ogOwner = _getOgOwner(og);
    require(ogOwner != address(0), '!og');
    BondingCurve storage curve = bondingCurves[og];
    return _getBurnPrice(og, printNumber, curve);
  }

  function _getBurnPrice(uint256 og, uint256 printNumber, BondingCurve storage curve) internal view returns(uint256) {
    uint256 printPrice = _getPrintPrice(printNumber, curve);
    uint256 protocolFee = printPrice * protocolMintPercent / PERCENT_BASE;
    uint256 curatorFee = printPrice * curatorMintPercent / PERCENT_BASE;
    uint256 ownerFee = printPrice * ogMintPercent[og] / PERCENT_BASE;
    return printPrice - protocolFee - curatorFee - ownerFee;
  }

  function getPrintNumber(uint256 og) external view returns(uint256 printNumber) {
    address ogOwner = _getOgOwner(og);
    require(ogOwner != address(0), '!og');
    printNumber = _getPrintNumber(og);
  }

  function _sendFee(address to, uint256 price, uint256 percent) internal returns(uint256 fee) {
    fee = price * percent / PERCENT_BASE;
    if (fee > 0) {
      (bool success, ) = to.call{value: fee}("");
      require(success, '!_sendFee');
    }
  }

  function _getPrintPrice(uint256 printNumber, BondingCurve storage curve) internal view returns(uint256) {
    return IIyusdiBondingCurve(curve.curve).getPrintPrice(curve.curveType, printNumber, curve.params);
  }

  function _mintPrintFor(uint256 og, address to, bytes memory data) internal returns(uint256 id) {
    address ogOwner = _getOgOwner(og);
    require(ogOwner != address(0), '!og');
    uint256 printNumber = _getPrintNumber(og) + 1;
    BondingCurve storage curve = bondingCurves[og];
    require(printNumber <= curve.MaxPrints, '!maxPrints');
    uint256 printPrice = _getPrintPrice(printNumber, curve);
    require(msg.value >= printPrice, '!printPrice');
    uint256 protocolFee = _sendFee(protocol, printPrice, protocolMintPercent);
    uint256 curatorFee = _sendFee(_getCurator(), printPrice, curatorMintPercent);
    uint256 ownerFee = _sendFee(ogOwner, printPrice, ogMintPercent[og]);
    if (msg.value > printPrice) {
      uint256 refund =  msg.value - printPrice;
      (bool rsuccess, ) = msg.sender.call{value: refund}("");
      require(rsuccess, '!refund');
    }
    reserves[og] += printPrice - protocolFee - curatorFee - ownerFee; // isolate ETH for each og
    id = IyusdiNftV2(nft).mintPrint(og, to, data);
    emit PrintMinted(id, printPrice, protocolFee, curatorFee, ownerFee, printNumber);
  }

  function burnPrint(uint256 id, uint256 minPrintNumber) external {
    require(IyusdiNftV2(nft).isPrintId(id), '!printId');
    _burnPrint(id, minPrintNumber);
  }

  function _burnPrint(uint256 id, uint256 minPrintNumber) internal {
    uint256 og = _getOgId(id);
    address ogOwner = _getOgOwner(og);
    require(ogOwner != address(0), '!og');
    uint256 printNumber = _getPrintNumber(og);
    require(printNumber >= minPrintNumber, '!minPrintNumber');
    BondingCurve storage curve = bondingCurves[og];
    uint256 burnPrice = _getBurnPrice(og, printNumber, curve);
    reserves[og] -= burnPrice; // will fail if underflows
    uint256 protocolFee = _sendFee(protocol, burnPrice, protocolBurnPercent);
    uint256 curatorFee = _sendFee(_getCurator(), burnPrice, curatorBurnPercent);
    uint256 ogFee = _sendFee(ogOwner, burnPrice, ogBurnPercent[og]);
    uint256 refund = burnPrice - protocolFee - curatorFee - ogFee;
    if (refund > 0) {
      (bool success, ) = msg.sender.call{value: refund}("");
      require(success, '!refund');
    }
    IyusdiNftV2(nft).burnPrint(msg.sender, id);
    emit PrintBurned(id, burnPrice, protocolFee, curatorFee, ogFee, printNumber);
  }

  function post(uint256 og, uint256 hash, bytes memory data) external {
    address ogOwner = _getOgOwner(og);
    require(msg.sender == ogOwner, '!owner');
    IyusdiNftV2(nft).post(og, hash, data);
  }

  function allowTransfers(uint256 og, bool allow) external {
    address ogOwner = _getOgOwner(og);
    require(msg.sender == ogOwner, '!owner');
    IyusdiNftV2(nft).allowTransfers(og, allow);
  }

}
