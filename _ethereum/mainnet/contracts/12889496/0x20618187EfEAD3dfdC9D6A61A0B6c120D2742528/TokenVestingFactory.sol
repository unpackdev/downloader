pragma solidity ^0.8.0;

import "./Create2.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./TokenVesting.sol";

contract TokenVestingFactory is Ownable {
  using SafeERC20 for IERC20;

  mapping (address => address) public vestingForAddress;

  event VestingDeployed(
    address indexed vestingAddress,
    address indexed beneficiary,
    uint256 start,
    uint256 cliffDuration,
    uint256 duration,
    bool revocable
  );

  function deployVesting(
    address beneficiary,
    uint256 start,
    uint256 cliffDuration,
    uint256 duration,
    bool revocable,
    uint256 amount,
    IERC20 token,
    bytes32 salt,
    address owner,
    address tokenHolder
  ) public returns (address vestingAddress){
    require(vestingForAddress[beneficiary] == address(0), "User is already vested");
    bytes memory bytecode = abi.encodePacked(
      type(TokenVesting).creationCode,
      abi.encode(
        beneficiary,
        start,
        cliffDuration,
        duration,
        revocable
      )
    );

    vestingAddress = Create2.deploy(0, salt, bytecode);

    vestingForAddress[beneficiary] = vestingAddress;
    
    TokenVesting vesting = TokenVesting(vestingAddress);

    vesting.transferOwnership(owner);

    token.safeTransferFrom(tokenHolder, address(vesting), amount);

    emit VestingDeployed(
      vestingAddress,
      beneficiary,
      start,
      cliffDuration,
      duration,
      revocable
    );
  
    return vestingAddress;
  }
}