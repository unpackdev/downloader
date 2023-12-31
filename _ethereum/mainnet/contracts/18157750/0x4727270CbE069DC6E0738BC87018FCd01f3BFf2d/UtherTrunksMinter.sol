// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUtherTrunks.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

contract UtherTrunksMinter is Ownable {

  using ECDSA for bytes32;

  uint256 public unitPrice = 0.3 ether;

  uint256 public startTime = block.timestamp;
  uint256 public privateStartTime = block.timestamp;


  uint256 public totalMinted = 0;
  address public signer;

  mapping(address => bool) wl;

  mapping(address =>  uint256) public usersMinted;
  IUtherTrunks public nftContract;

  constructor(
    address nftContractAddress,
    address _signer
  ){
    nftContract = IUtherTrunks(nftContractAddress);
    signer = _signer;
  }

  function privateMint(
    address _to,
    uint256 id,
    uint _count,
    uint mintableAmount,
    bytes calldata sig
  ) public payable {
    require(block.timestamp >= privateStartTime, "not started");
    require(msg.value >= price(_count), "value");
    bytes32 hash = keccak256(abi.encodePacked(_to, mintableAmount));
    hash = hash.toEthSignedMessageHash();
    address sigSigner = hash.recover(sig);
    require(sigSigner == signer, "!sig");
    require(_count + usersMinted[_to] <= mintableAmount, "exceeded balance");

    nftContract.mint(_to, id, _count, '0x');

    totalMinted += _count;
    usersMinted[_to] += _count;
  }

  function mint(
    address _to,
    uint256 id,
    uint _count
  ) public payable {
    require(block.timestamp >= startTime || wl[msg.sender], "not started");
    require(msg.value >= price(_count), "value");

    nftContract.mint(_to, id, _count, '0x');

    totalMinted += _count;
  }

  function price(uint _count) public view returns (uint256) {
    return _count * unitPrice;
  }

  function updateUnitPrice(uint256 _unitPrice) public onlyOwner {
    unitPrice = _unitPrice;
  }

  function updateStartTime(uint256 _startTime) public onlyOwner {
    startTime = _startTime;
  }

  function updatePrivateStartTime (uint256 _startTime) public onlyOwner {
    privateStartTime = _startTime;
  }

  function updateSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function updateNftContrcat(IUtherTrunks _newAddress) public onlyOwner {
    nftContract = IUtherTrunks(_newAddress);
  }

  function updateWL(address addr, bool b) public onlyOwner {
    wl[addr] = b;
  }

  function setTotalMinted(uint256 b) public onlyOwner {
    totalMinted = b;
  }

  // allows the owner to withdraw tokens
  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      IERC20(_tokenAddr).transfer(_to, amount);
    }
  }
}
