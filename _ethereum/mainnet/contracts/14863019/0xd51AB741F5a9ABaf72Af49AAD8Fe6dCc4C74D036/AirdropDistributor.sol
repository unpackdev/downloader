//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./KaratDistributor.sol";

// import "./console.sol";

contract AirdropDistributor is KaratDistributor {
  using SafeERC20 for IERC20;
  string public name;
  address public immutable token;

  constructor(
    string memory _name,
    address _owner,
    address _token,
    bytes32 _merkleRoot,
    uint256 _reach,
    string memory _baseInfoURI,
    string memory _frozenInfoURI
  )
    KaratDistributor(_owner, _merkleRoot, _reach, _baseInfoURI, _frozenInfoURI)
  {
    require(_token != address(0), "Token null");
    name = _name;
    token = _token;
  }

  function claim(
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external override {
    require(account == msg.sender, "Cannot claim for others");
    _verify(account, amount, merkleProof);

    require(
      IERC20(token).transferFrom(owner, account, amount),
      "AirdropDistributor: Transfer failed."
    );

    emit Claimed(account, amount);
  }
}
