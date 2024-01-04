pragma solidity 0.6.12;

import "./VesterFactory.sol";
import "./Vester.sol";
import "./Idle.sol";

contract LockedIDLE {
  address public constant IDLE = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);
  address public constant vestingFactory = address(0xbF875f2C6e4Cc1688dfe4ECf79583193B6089972);
  Idle public idle;
  VesterFactory public factory;

  constructor() public {
    idle = Idle(IDLE);
    factory = VesterFactory(vestingFactory);
  }
  function name() public view returns (string memory) {
    return "LockedIDLE";
  }
  function decimals() public view returns (uint256) {
    return 18;
  }
  function balanceOf(address _user) public view returns (uint256) {
    if (_user == address(0x4191dbEe094bDFD087f14791E7D7084f5e92447e)) {
      return idle.balanceOf(0x43fDd8d3E17A4E40ef97FED432B488105E620316);
    }
    address vestingContract = factory.vestingContracts(_user);
    if (vestingContract == address(0)) {
      return 0;
    }
    uint256 balance = idle.balanceOf(vestingContract);
    // team members have 1/10th of the voting power
    if (_user == address(0x3675D2A334f17bCD4689533b7Af263D48D96eC72) ||
        _user == address(0x4F314638B730Bc46Df5e600E524267d0641C98B4) ||
        _user == address(0xd889Acb680D5eDbFeE593d2b7355a666248bAB9b) ||
        _user == address(0xaDa343Cb6820F4f5001749892f6CAA9920129F2A)
      ) {
      return balance / 10;
    }

    return balance;
  }
}
