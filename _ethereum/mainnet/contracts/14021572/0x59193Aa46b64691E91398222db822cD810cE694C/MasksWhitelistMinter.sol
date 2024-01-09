// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";


interface IStandaloneNft721 is IERC721 {
  function mint(address _to, uint256 _tokenId) external;
}

contract MasksWhitelistMinter is AccessControl {
  
  using ECDSA for bytes32;

  mapping(address => uint256) public numberMintedByAddress;

  address public verifier;

  IStandaloneNft721 public nftContract;

  uint256 nextTokenToMint;
  uint256 maxTokenId;

  constructor(address _nftContractAddress, address _contractOwner, address _verifier, uint256 _nextTokenToMint, uint256 _maxTokenId) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
    nftContract = IStandaloneNft721(_nftContractAddress);
    verifier = _verifier;
    nextTokenToMint = _nextTokenToMint;
    maxTokenId = _maxTokenId;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  function setVerifierAddress(address _verifier) 
    external onlyOwner {
      verifier = _verifier;
  }

  function setNextTokenToMint(uint256 _nextTokenToMint)
    external onlyOwner {
      nextTokenToMint = _nextTokenToMint;
  }

  function setMaxTokenId(uint256 _maxTokenId)
    external onlyOwner {
      maxTokenId = _maxTokenId;
  }

  function checkSigniture(address msgSender, bytes memory sig, uint256 maxMints) public view returns (bool _success) {
    bytes32 _hash = keccak256(abi.encode('MasksWhitelistMinter|mint|', msgSender, maxMints));
    address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig);
    return signer == verifier;
  }

  function mint(
      uint256[] memory _poolType,
      uint256[] memory _amount, 
      bool[] memory _useUnicorns, 
      address[] memory _rainbowPools, 
      address[] memory _unicornPools,
      bytes memory sig, 
      uint256 maxMints
    ) external {

    require(checkSigniture(_msgSender(), sig, maxMints), 'invalid sig');

    require(numberMintedByAddress[_msgSender()] + _amount[0] <= maxMints);
    numberMintedByAddress[_msgSender()] += _amount[0];


    uint256 _nextTokenToMint = nextTokenToMint;
    require(_amount[0] + _nextTokenToMint <= maxTokenId + 1, 'max reached');

    for (uint256 i = 0; i < _amount[0]; i++) {
      nftContract.mint(_msgSender(), _nextTokenToMint);
      _nextTokenToMint++;
    }
    nextTokenToMint = _nextTokenToMint;
  }
}