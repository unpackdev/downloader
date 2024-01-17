// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMRC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./Counters.sol";

contract MetaMartianNFTMinter is Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  using ECDSA for bytes32;

  event Claim(
    uint256 txId,
    address indexed user
  );

  struct TX {
    uint256 txId;
    address wallet;
  }

  mapping(uint256 => TX) public txs;
  mapping(address => uint256[]) public userMints;

  address public signer;
  bool public mintEnabled = true;

  IMRC721 public nftContract;

  constructor(
    address nftContractAddress,
    address _signer
  ){
    nftContract = IMRC721(nftContractAddress);
    signer = _signer;
    _tokenIds.increment();
  }

  function mint(
    uint256 txId,
    uint256[] memory ids,
    bytes calldata sig
  ) public {
    require(mintEnabled, "!enabled");
    address user = msg.sender;
    require(txs[txId].wallet == address(0), 'Already Minted');

    bytes32 hash = keccak256(abi.encodePacked(msg.sender, txId, ids));
    hash = hash.toEthSignedMessageHash();

    address sigSigner = hash.recover(sig);
    require(sigSigner == signer, "!sig");

    txs[txId] = TX({
      txId: txId,
      wallet: user
    });
    userMints[user].push(txId);

    _mint(user, ids);
    emit Claim(txId, user);

  }

  function _mint(address _to, uint256[] memory ids) private{
    for(uint i = 0; i < ids.length; i++){
      nftContract.mint(_to, ids[i]);
    }
  }


  function updateMintEnable(bool enable) public onlyOwner {
    mintEnabled = enable;
  }

  function updateSigner(address _signer) public onlyOwner {
    signer = _signer;
  }


  function updateNftContrcat(IMRC721 _newAddress) public onlyOwner {
    nftContract = IMRC721(_newAddress);
  }

  function getUserTxs(address _user) public view returns (
    uint256[] memory ids
  ){
    ids = new uint256[](userMints[_user].length);
    for(uint i = 0; i < ids.length; i++) {
      ids[i] = userMints[_user][i];
    }
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
