// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
// import "./Ownable.sol";
import "./MerkleProof.sol";
import "./AccessOperatable.sol";

// On Chain Maids Contract Interface(Main contract)
interface iCMOC {
  function mint(address to, uint256 quantity) external;
  function MAX_ELEMENTS() external returns (uint256);
  function totalSupply() external view returns (uint256);
}

contract CryptoMaidsOnChainSale is AccessOperatable {
  using SafeMath for uint256;
  // target contract
  iCMOC public targetContract;
  string private _defaultURI;

  // record the remainings(pre sale)
  mapping(address => uint) public preSaleWhitelistRemaining;
  // record whitelist is used(pre sale)
  mapping(address => bool) public preSaleWhitelistUsed;

  // record the remainings(partner sale)
  mapping(address => uint) public partnerSaleWhitelistRemaining;
  // record whitelist is used(partner sale)
  mapping(address => bool) public partnerSaleWhitelistUsed;

  // end time
  uint256 public preSaleStart;
  uint256 public partnerSaleStart;
  uint256 public saleStart;

  // start time
  uint256 public preSaleEnd = 253404860400; //JS: new Date(9999, 12, 31).getTime() / 1000
  uint256 public partnerSaleEnd = 253404860400; //JS: new Date(9999, 12, 31).getTime() / 1000
  uint256 public saleEnd = 253404860400; // JS: new Date(9999, 12, 31).getTime() / 1000

  // supply and max per mint
  uint256 public maxSupply = 4000;
  uint256 public maxByMint = 20;

  // sale price
  uint256 public preSalePrice = 5 * 10 ** 16; // 0.05eth
  uint256 public partnerSalePrice = 6 * 10 ** 16; // 0.06eth
  uint256 public salePrice = 8 * 10 ** 16; // 0.08eth

  // merkle root(pre sale)
  bytes32 public preSaleMerkleRoot;
  // merkle root(partner sale)
  bytes32 public partnerSaleMerkleRoot;

  constructor(address token_) {
    require(token_ != address(0x0));
    // get contract
    targetContract = iCMOC(token_);
  }

  // public mint
  function mintNFT(uint256 nftNum) external payable {
    require(totalSupply().add(nftNum) <= maxSupply, "Exceeds total supply.");
    require(nftNum <= maxByMint, "Exceed Max by mint.");
    // nftNum must be positive.
    require(nftNum > 0, "The number of purchases is incorrect.");

    require(saleStart != 0 && block.timestamp > saleStart, "The sale hasn't started yet.");
    // limit by time
    require(block.timestamp <= saleEnd, "Sale ended");
    require(salePrice.mul(nftNum) == msg.value, "Incorrect eth amount.");

    targetContract.mint(msg.sender, nftNum);
  }

  // pre sale mint
  function preSaleMint(uint256 nftNum, uint256 totalAllocation, bytes32 leaf, bytes32[] calldata proof) external payable {
    require(preSaleStart != 0 && block.timestamp > preSaleStart , "yet");
    // limit by time
    require(block.timestamp <= preSaleEnd, "Sale was finished.");
    require(nftNum <= maxByMint, "Exceed Max by mint.");
    bytes32 solidityLeaf = keccak256(abi.encodePacked(msg.sender, totalAllocation));

    if(!preSaleWhitelistUsed[msg.sender]) {
      require(solidityLeaf == leaf, "Invalid Leaf.");
      require(MerkleProof.verify(proof, preSaleMerkleRoot, leaf), "Invalid Merkle Proof.");

      preSaleWhitelistUsed[msg.sender] = true;
      preSaleWhitelistRemaining[msg.sender] = totalAllocation;
    }

    require(nftNum > 0);
    require(preSalePrice.mul(nftNum) == msg.value, "Incorrect eth amount.");
    require(totalSupply().add(nftNum) <= maxSupply, "Exceeds total supply.");
    require(preSaleWhitelistRemaining[msg.sender] >= nftNum, "Exceeds remaining whitelist.");

    preSaleWhitelistRemaining[msg.sender] -= nftNum;
    targetContract.mint(msg.sender, nftNum);
  }

  // partner sale mint
  function partnerSaleMint(uint256 nftNum, uint256 totalAllocation, bytes32 leaf, bytes32[] calldata proof) external payable {
    require(partnerSaleStart != 0 && block.timestamp > partnerSaleStart , "yet");
    // limit by time
    require(block.timestamp <= partnerSaleEnd, "Sale was finished.");
    require(nftNum <= maxByMint, "Exceed Max by mint.");
    bytes32 solidityLeaf = keccak256(abi.encodePacked(msg.sender, totalAllocation));

    if(!partnerSaleWhitelistUsed[msg.sender]) {
      require(solidityLeaf == leaf, "Invalid Leaf.");
      require(MerkleProof.verify(proof, partnerSaleMerkleRoot, leaf), "Invalid Merkle Proof.");

      partnerSaleWhitelistUsed[msg.sender] = true;
      partnerSaleWhitelistRemaining[msg.sender] = totalAllocation;
    }

    require(nftNum > 0);
    require(partnerSalePrice.mul(nftNum) == msg.value, "Incorrect eth amount.");
    require(totalSupply().add(nftNum) <= maxSupply, "Exceeds total supply.");
    require(partnerSaleWhitelistRemaining[msg.sender] >= nftNum, "Exceeds remaining whitelist.");

    partnerSaleWhitelistRemaining[msg.sender] -= nftNum;
    targetContract.mint(msg.sender, nftNum);
  }

  function totalSupply() public view returns (uint256) {
    return targetContract.totalSupply();
  }

  // withdrow method
  function withdrawAll(address withdrawAddress) public onlyOperator() {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(withdrawAddress, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  // merkle root
  function setPreSaleMerkleRoot(bytes32 preSaleMerkleRoot_) public onlyOperator() {
    preSaleMerkleRoot = preSaleMerkleRoot_;
  }
  function setPartnerSaleMerkleRoot(bytes32 partnerSaleMerkleRoot_) public onlyOperator() {
    partnerSaleMerkleRoot = partnerSaleMerkleRoot_;
  }

  // start time
  function setPreSaleStart(uint256 preSaleStart_) public onlyOperator() {
    preSaleStart = preSaleStart_;
  }
  function setPartnerSaleStart(uint256 partnerSaleStart_) public onlyOperator() {
    partnerSaleStart = partnerSaleStart_;
  }
  function setSaleStart(uint256 saleStart_) public onlyOperator() {
    saleStart = saleStart_;
  }

  // end time
  function setPreSaleEnd(uint256 preSaleEnd_) public onlyOperator() {
    preSaleEnd = preSaleEnd_;
  }
  function setPartnerSaleEnd(uint256 partnerSaleEnd_) public onlyOperator() {
    partnerSaleEnd = partnerSaleEnd_;
  }
  function setSaleEnd(uint256 saleEnd_) public onlyOperator() {
    saleEnd = saleEnd_;
  }

  // selling price
  function setPreSalePrice(uint256 preSalePrice_) public onlyOperator() {
    preSalePrice = preSalePrice_;
  }
  function setPartnerSalePrice(uint256 partnerSalePrice_) public onlyOperator() {
    partnerSalePrice = partnerSalePrice_;
  }
  function setSalePrice(uint256 salePrice_) public onlyOperator() {
    salePrice = salePrice_;
  }

  function setMaxByMint(uint256 maxByMint_) public onlyOperator() {
    maxByMint = maxByMint_;
  }
  function setMaxSupply(uint256 maxSupply_) public onlyOperator() {
    maxSupply = maxSupply_;
  }
}