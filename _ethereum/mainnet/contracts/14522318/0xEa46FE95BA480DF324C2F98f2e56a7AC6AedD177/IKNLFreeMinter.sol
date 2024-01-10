//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./Ownable.sol";

interface InvisibleKennel {
  function balanceOf(address owner) external returns (uint256);

  function specialMint(address[] memory recipients, uint256[] memory amounts) external;

  function transferOwnership(address newOwner) external;
}

interface InvisibleFriends {
  function balanceOf(address owner) external returns (uint256);
}

contract IKNLFreeMinter is Ownable {
  InvisibleKennel private invisibleKennel = InvisibleKennel(0xb04E3F02196698B5985b1066C05763b7F26042E8);
  InvisibleFriends private invisibleFriends = InvisibleFriends(0x59468516a8259058baD1cA5F8f4BFF190d30E066);

  uint256 public maxMints;
  uint256 public mintsTotalCount;
  uint256 public mintsCountPerTx;
  uint256 public minKennelCountRequired;

  constructor(
    uint256 _maxMints,
    uint256 _mintsCountPerTx,
    uint256 _minKennelCountRequired
  ) {
    console.log("Deploying IKNL Free Minter");

    mintsTotalCount = 0;
    maxMints = _maxMints;
    mintsCountPerTx = _mintsCountPerTx;
    minKennelCountRequired = _minKennelCountRequired;
  }

  function setMaxMints(uint256 _maxMints) external onlyOwner {
    maxMints = _maxMints;
  }

  function setMintsCountPerTx(uint256 _mintsCountPerTx) external onlyOwner {
    mintsCountPerTx = _mintsCountPerTx;
  }

  function setMinKennelCountRequired(uint256 _minKennelCountRequired) external onlyOwner {
    minKennelCountRequired = _minKennelCountRequired;
  }

  function claim() external {
    require(
      invisibleKennel.balanceOf(msg.sender) >= minKennelCountRequired || invisibleFriends.balanceOf(msg.sender) >= 1,
      "Sender doesn't qualify to claim"
    );
    require(mintsTotalCount < maxMints, "Max total claims exceeded");

    address[] memory recipients = new address[](1);
    uint256[] memory amounts = new uint256[](1);

    recipients[0] = msg.sender;
    amounts[0] = mintsCountPerTx;
    invisibleKennel.specialMint(recipients, amounts);

    mintsTotalCount++;
  }

  function transferInvisibleKennelOwnership(address _newOwner) external onlyOwner {
    invisibleKennel.transferOwnership(_newOwner);
  }
}
