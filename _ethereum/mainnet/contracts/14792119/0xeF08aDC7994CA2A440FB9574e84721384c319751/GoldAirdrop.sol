//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "./ECDSA.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract GoldAirdrop is Ownable {

  mapping(address => uint) public nonce;

  using ECDSA for bytes32;
  address public signer;
  IERC20 public immutable gold;

  uint public dayAirdroped;
  uint public maxDayAirdrop;
  uint public today;

  uint chainId;

  event UserClaim(address indexed user, uint amount, uint nonce);
  event SignerChanged(address signer);

  constructor(address _signer, uint _max, address _gold) {
    signer = _signer;
    maxDayAirdrop = _max;
    gold = IERC20(_gold);
    chainId = block.chainid;
  }
  
  function setSigner(address _signer) external onlyOwner {
      signer = _signer;
      emit SignerChanged(_signer);
  }

  function setMaxDayAirdrop(uint _max) external onlyOwner {
      maxDayAirdrop = _max;
  }

  function withdrawGold(address to, uint amount) external onlyOwner {
      gold.transfer(to, amount);
  }
  
  function claim(uint amount, bytes calldata sig) external {
    uint day = getDay(block.timestamp);
    if (today != day) {
      dayAirdroped = amount;
      today = day;
    } else {
      dayAirdroped += amount;
    }
    require(dayAirdroped <= maxDayAirdrop, "over day limit");

    address user = msg.sender;
    uint userNonce = nonce[user];
    require(verify(user, amount, userNonce, sig), "signature unmatch");
    
    gold.transfer(user, amount);
    emit UserClaim(user, amount, userNonce);

    nonce[user] += 1;
  }

  function verify(address sender,
        uint amount,
        uint nonce,
        bytes memory sig
    ) internal view returns (bool) {
        bytes32 hashStruct = keccak256(abi.encode(sender, amount, nonce, chainId, address(this)));
        return recover(hashStruct, sig) == signer;
    }

  function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
      return hash.toEthSignedMessageHash().recover(sig);
    }

  function getDay(uint ts) internal pure returns (uint) {
    return ts / 60 / 60 / 24;
  }

}