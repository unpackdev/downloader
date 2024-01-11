// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";


interface IVeNFT {
  function getAmount(uint256 _tokenId) external view returns (uint256);

  function getEnd(uint256 _tokenId) external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface ICheeToken {
  function mint(address account, uint256 amount) external;

  function burnFrom(address account, uint256 amount) external;
}

contract Lend is IERC721Receiver, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct LockedVeNFT {
    bool isLocked;
    address lenderAddress;
    uint256 cheeTokenAmount;
    uint256 lockDurationBlocks;
    uint256 lockStartBlock;
    uint256 lockEndBlock;
  }

  LockedVeNFT private lockedVeNFT;

  address internal admin;
  address internal treasuryAddress;

  bool internal emergencyStop = false;

  uint256 internal interestRatePerBlock;
  uint256 internal feeRate;
  uint256 internal graceTimeBlocks;
  uint256 internal maxDurationBlocks;
  uint256 internal maxLTV;

  mapping(address => bool) internal permissioned;
  mapping(address => mapping(uint256 => LockedVeNFT)) internal lockedVeNFTInfo;
  mapping(address => mapping(address => uint256[])) internal lentVeNFTs;
  mapping(address => address) internal supportedCheeToken;
  mapping(address => address) internal supportedInterestToken;

  event ChangeAdmin(address newAdmin);
  event Whitelist(address _user);
  event StopContract();
  event ResumeContract();
  event AddSupportedAsset(address veNFTAddress, address cheeTokenAddress, address tokenAddress);
  event SetTreasuryAddress(address _address);
  event SetInterestRatePerBlock(uint256 _interestRate);
  event SetFeeRate(uint256 _feeRate);
  event SetGraceTimeBlocks(uint256 _blocks);
  event SetMaxDurationBlocks(uint256 _maxDurationBlocks);
  event SetMaxLTV(uint256 _ltv);
  event Mint(address _veNFTAddress, uint256 _nftId, uint256 _cheeTokenAmount, uint256 _lockDurationBlocks);
  event Redeem(address _veNFTAddress, uint256 _nftId);
  event Liquidate(address _veNFTAddress, uint256 _nftId);

  constructor() {
    admin = msg.sender;
  }

  modifier onlyPermissioned() {
    require(permissioned[msg.sender] == true, "No permission");
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, "Not admin");
    _;
  }

  function changeAdmin(address _newAdmin) public onlyAdmin {
    require(_newAdmin != address(0), "Invalid address");
    admin = _newAdmin;
    emit ChangeAdmin(_newAdmin);
  }

  function whitelist(address _user) public onlyAdmin {
    require(_user != address(0), "Invalid address");
    permissioned[_user] = true;
    emit Whitelist(_user);
  }

  function stopContract() public onlyAdmin {
    emergencyStop = true;
    emit StopContract();
  }

  function resumeContract() public onlyAdmin {
    emergencyStop = false;
    emit ResumeContract();
  }

  function addSupportedAsset(
    address veNFTAddress,
    address cheeTokenAddress,
    address tokenAddress
  ) public onlyAdmin {
    require(veNFTAddress != address(0) && cheeTokenAddress != address(0) && tokenAddress != address(0), "Incorrect input");
    supportedCheeToken[veNFTAddress] = cheeTokenAddress;
    supportedInterestToken[veNFTAddress] = tokenAddress;
    emit AddSupportedAsset(veNFTAddress, cheeTokenAddress, tokenAddress);
  }

  function setTreasuryAddress(address _address) public onlyAdmin {
    require(_address != address(0), "Invalid address");
    treasuryAddress = _address;
    emit SetTreasuryAddress(_address);
  }

  function setInterestRatePerBlock(uint256 _interestRate) public onlyAdmin {
    require(_interestRate >= 0, "Value less than 0");
    interestRatePerBlock = _interestRate;
    emit SetInterestRatePerBlock(_interestRate);
  }

  function setFeeRate(uint256 _feeRate) public onlyAdmin {
    require(_feeRate >= 0, "Value less than 0");
    feeRate = _feeRate;
    emit SetFeeRate(_feeRate);
  }

  function setGraceTimeBlocks(uint256 _blocks) public onlyAdmin {
    require(_blocks >= 0, "Value less than 0");
    graceTimeBlocks = _blocks;
    emit SetGraceTimeBlocks(_blocks);
  }

  function setMaxDurationBlocks(uint256 _maxDurationBlocks) public onlyAdmin {
    require(_maxDurationBlocks >= 0, "Value less than 0");
    maxDurationBlocks = _maxDurationBlocks;
    emit SetMaxDurationBlocks(_maxDurationBlocks);
  }

  function setMaxLTV(uint256 _ltv) public onlyAdmin {
    require(_ltv > 0, "Value less than 0");
    maxLTV = _ltv;
    emit SetMaxLTV(_ltv);
  }

  function getTreasuryAddress() public view returns (address) {
    return treasuryAddress;
  }

  function getInterestRatePerBlock() public view returns (uint256) {
    return interestRatePerBlock;
  }

  function getFeeRate() public view returns (uint256) {
    return feeRate;
  }

  function getGraceTimeBlocks() public view returns (uint256) {
    return graceTimeBlocks;
  }

  function getMaxDurationBlocks() public view returns (uint256) {
    return maxDurationBlocks;
  }

  function getMaxLTV() public view returns (uint256) {
    return maxLTV;
  }

  function getMaxCheeTokenAmount(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    return IVeNFT(_veNFTAddress).getAmount(_nftId).mul(maxLTV).div(1e18);
  }

  function getCheeTokenAmount(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    return lockedVeNFTInfo[_veNFTAddress][_nftId].cheeTokenAmount;
  }

  function getLockDurationBlocks(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    return lockedVeNFTInfo[_veNFTAddress][_nftId].lockDurationBlocks;
  }

  function getLockStartBlock(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    return lockedVeNFTInfo[_veNFTAddress][_nftId].lockStartBlock;
  }

  function getLockEndBlock(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    return lockedVeNFTInfo[_veNFTAddress][_nftId].lockEndBlock;
  }

  function getAccruedInterestAmount(address _veNFTAddress, uint256 _nftId) public view returns (uint256) {
    uint256 _cheeTokenAmount = lockedVeNFTInfo[_veNFTAddress][_nftId].cheeTokenAmount;
    uint256 _lockStartBlock = lockedVeNFTInfo[_veNFTAddress][_nftId].lockStartBlock;
    uint256 _interest = _cheeTokenAmount.mul(block.number.sub(_lockStartBlock)).mul(interestRatePerBlock).div(1e18);
    uint256 _fee = _cheeTokenAmount.mul(feeRate).div(1e18);
    uint256 _total = _interest.add(_fee);
    return _total;
  }

  function getLentNFTIds(address _veNFTAddress, address _user) public view returns (uint256[] memory) {
    return lentVeNFTs[_user][_veNFTAddress];
  }

  function checkPermission(address _user) public view returns (bool) {
    return permissioned[_user];
  }

  function mint(
    address _veNFTAddress,
    uint256 _nftId,
    uint256 _cheeTokenAmount,
    uint256 _lockDurationBlocks
  ) external nonReentrant {
    require(emergencyStop == false, "Contract paused");
    require(_veNFTAddress != address(0) && _nftId > 0 && _cheeTokenAmount > 0 && _lockDurationBlocks > 0, "Incorrect input");
    require(IVeNFT(_veNFTAddress).ownerOf(_nftId) == msg.sender, "Not owner");
    require(_cheeTokenAmount <= IVeNFT(_veNFTAddress).getAmount(_nftId).mul(maxLTV).div(1e18), "Value greater than max");
    require(_lockDurationBlocks <= maxDurationBlocks, "Value greater than max");
    IERC721(_veNFTAddress).safeTransferFrom(msg.sender, address(this), _nftId);
    ICheeToken(supportedCheeToken[_veNFTAddress]).mint(msg.sender, _cheeTokenAmount);
    lockedVeNFTInfo[_veNFTAddress][_nftId].lenderAddress = msg.sender;
    lockedVeNFTInfo[_veNFTAddress][_nftId].cheeTokenAmount = _cheeTokenAmount;
    lockedVeNFTInfo[_veNFTAddress][_nftId].lockDurationBlocks = _lockDurationBlocks;
    lockedVeNFTInfo[_veNFTAddress][_nftId].lockStartBlock = block.number;
    lockedVeNFTInfo[_veNFTAddress][_nftId].lockEndBlock = block.number.add(_lockDurationBlocks);
    lentVeNFTs[msg.sender][_veNFTAddress].push(_nftId);
    emit Mint(_veNFTAddress, _nftId, _cheeTokenAmount, _lockDurationBlocks);
  }

  function redeem(address _veNFTAddress, uint256 _nftId) external nonReentrant {
    require(emergencyStop == false, "Contract paused");
    require(_veNFTAddress != address(0) && _nftId > 0, "Incorrect input");
    require(IERC721(_veNFTAddress).ownerOf(_nftId) == address(this), "Invalid NFT ID");
    require(lockedVeNFTInfo[_veNFTAddress][_nftId].lenderAddress == msg.sender, "Not the lender");
    require(lockedVeNFTInfo[_veNFTAddress][_nftId].lockEndBlock.add(graceTimeBlocks) >= block.number, "Cannot repay now");
    uint256 _cheeTokenAmount = lockedVeNFTInfo[_veNFTAddress][_nftId].cheeTokenAmount;
    uint256 _lockStartBlock = lockedVeNFTInfo[_veNFTAddress][_nftId].lockStartBlock;
    uint256 _interest = _cheeTokenAmount.mul(block.number.sub(_lockStartBlock)).mul(interestRatePerBlock).div(1e18);
    uint256 _fee = _cheeTokenAmount.mul(feeRate).div(1e18);
    uint256 _total = _interest.add(_fee);
    ICheeToken(supportedCheeToken[_veNFTAddress]).burnFrom(msg.sender, _cheeTokenAmount);
    IERC20(supportedInterestToken[_veNFTAddress]).safeTransferFrom(msg.sender, treasuryAddress, _total);
    IVeNFT(_veNFTAddress).safeTransferFrom(address(this), msg.sender, _nftId);
    emit Redeem(_veNFTAddress, _nftId);
  }

  function liquidate(address _veNFTAddress, uint256 _nftId) external nonReentrant onlyPermissioned {
    require(emergencyStop == false, "Contract paused");
    require(_veNFTAddress != address(0) && _nftId > 0, "Incorrect input");
    uint256 _lockEndBlock = lockedVeNFTInfo[_veNFTAddress][_nftId].lockEndBlock.add(graceTimeBlocks);
    require(_lockEndBlock < block.number, "Cannot liquidate now");
    uint256 _cheeTokenAmount = lockedVeNFTInfo[_veNFTAddress][_nftId].cheeTokenAmount;
    uint256 _lockStartBlock = lockedVeNFTInfo[_veNFTAddress][_nftId].lockStartBlock;
    uint256 _interest = _cheeTokenAmount.mul(block.number.sub(_lockStartBlock)).mul(interestRatePerBlock).div(1e18);
    uint256 _fee = _cheeTokenAmount.mul(feeRate).div(1e18);
    uint256 _total = _interest.add(_fee);
    ICheeToken(supportedCheeToken[_veNFTAddress]).burnFrom(msg.sender, _cheeTokenAmount);
    IERC20(supportedInterestToken[_veNFTAddress]).safeTransferFrom(msg.sender, treasuryAddress, _total);
    IVeNFT(_veNFTAddress).safeTransferFrom(address(this), msg.sender, _nftId);
    emit Liquidate(_veNFTAddress, _nftId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}
