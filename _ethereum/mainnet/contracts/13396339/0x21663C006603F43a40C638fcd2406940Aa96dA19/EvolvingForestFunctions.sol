// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./AccessControl.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

interface IEvolvingForestsNft is IERC721 {

  function totalSupply() external view returns (uint256);
  function nextTokenId() external view returns (uint256);
  function numberMintedByAddress(address _address) external view returns (uint256);

  function mintNext(address _to, uint256 _amount) external;
  function addToNumberMintedByAddress(address _address, uint256 amount) external;
}

contract EvolvingForestFunctions is AccessControl, ReentrancyGuard {
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  using ECDSA for bytes32;

  uint256 public price;
  uint256 public saleStartTime;
  uint256 public maxMintsPerTx;
  address public verifier;

  IEvolvingForestsNft nftContract;

  constructor(address _nftContract, address _verifier, uint256 _maxMintsPerTx, uint256 _price, uint256 _saleStartTime) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    verifier = _verifier;
    nftContract = IEvolvingForestsNft(_nftContract);
    maxMintsPerTx = _maxMintsPerTx;
    price = _price;
    saleStartTime = _saleStartTime;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not an admin");
    _;
  }

  function setMaxMintsPerTx(uint256 _maxMintsPerTx)
    external onlyOwner {
      maxMintsPerTx = _maxMintsPerTx;
  }

  function setNftContract(address _nftContract)
    external onlyOwner {
      nftContract = IEvolvingForestsNft(_nftContract);
  }

  function setPrice(uint256 _price) 
    external onlyOwner {
      price = _price;
  }

  function setSaleStartTime(uint256 _startTime) 
    external onlyOwner {
      saleStartTime = _startTime;
  }
  
  function setVerifierAddress(address _verifier) 
    external onlyOwner {
      verifier = _verifier;
  }

  function getNFTs(address _address, uint256 _start, uint256 _end) 
    external view returns (uint256[] memory amounts) {
      uint256[] memory _amounts = new uint256[](_end - _start);
      uint256 count;
      for (uint256 i = _start; i <= _end; i++) {
        try nftContract.ownerOf(i) returns (address a) {
          if (a == _address) {
            _amounts[count] = i;
            count++;
          }
        } catch Error(string memory /*reason*/) {
        }
      }

      uint256[] memory _amounts2 = new uint256[](count);
      for (uint256 i = 0; i < count; i++) {
        _amounts2[i] = _amounts[i];
      }

      return _amounts2;
  }

  function mint(uint256 _amount, bytes memory sig, uint256 maxMints) 
    external payable nonReentrant {

      require(_amount <= maxMintsPerTx, '_amount over max');
      int256 _supplyLeft = int256((nftContract.totalSupply() + 1)) - int256(nftContract.nextTokenId());
      require(_supplyLeft > 0, 'supply exhausted');

      if (int256(_amount) > _supplyLeft) {
        _amount = uint256(_supplyLeft);
      }

      if (block.timestamp < saleStartTime) {
        bytes32 _hash = keccak256(abi.encode('EvolvingForestFunctions|buy|', _msgSender(), maxMints));
        address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig);
        require (signer == verifier, "Invalid sig");

        require(nftContract.numberMintedByAddress(_msgSender()) + _amount <= maxMints);
        nftContract.addToNumberMintedByAddress(_msgSender(), _amount);
      }

      nftContract.mintNext(_msgSender(), _amount);

      uint256 refund = msg.value - _amount * price;
      if(refund > 0) {
        (bool refundSuccess, ) = _msgSender().call{ value: refund }("");
        require(refundSuccess, "refund failed");
      }
  }

  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
  }
}
 