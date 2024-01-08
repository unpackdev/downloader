// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";

contract EpherERC20 is ERC20Capped, Ownable {

  struct Minted {
    uint coreTeam;
    uint playToEarn;
    bool reserve;
  }

  uint    private constant _maxSupply         = 300000000 * 10**18;

  address private constant _walletAdvisors    = 0xB86bfB0d2b11E2B86b63F7fbD995765474c71f3f;
  address private constant _walletCoreTeamM1  = 0xB621E20f17aafC11ff7408D15B3449ab0dd3FC93;
  address private constant _walletCoreTeamM2  = 0x13C7cECb0ea3987Ded126b59624C898fCBa8feB9;
  address private constant _walletCoreTeamM3  = 0x2Af22f3A5899fE765036d5FeEE97BABa512507E6;
  address private constant _walletPrivateSale = 0xf28FdC5aD77f1426A0cD7F2Dac3f96d93C11d385;
  address private constant _walletPublicSale  = 0xc3691f6e9D1eB05B02CE85B4C7c86D72a06B3cF7;
  address private constant _walletReserve     = 0xD90918CB8adF7daEbaD19AB53bCe2917f8e36077;

  uint    private immutable _created = block.timestamp;

  Minted  private _minted;

  constructor() ERC20("Epher", "EPH") ERC20Capped(_maxSupply) {
    // Using ERC20._mint because of https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2580
    ERC20._mint(_walletAdvisors,    _maxSupply * 6 / 100);
    ERC20._mint(_walletPrivateSale, _maxSupply * 6 / 100);
    ERC20._mint(_walletPublicSale,  _maxSupply * 8 / 100);
  }

  function mintCoreTeam(uint quarter) public onlyOwner {
    if (quarter == 1) {
      require(block.timestamp > _created + 86400 * 30, "Core Team Q1 tokens can only be minted 30 days after EPH token creation");
      require(_minted.coreTeam < 1, "Core Team Q1 tokens were minted already");
  
      _mint(_walletCoreTeamM1, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    } else if (quarter == 2) {
      require(block.timestamp > _created + 86400 * 120, "Core Team Q2 tokens can only be minted 120 days after EPH token creation");
      require(_minted.coreTeam < 2, "Core Team Q2 tokens were minted already");

      _mint(_walletCoreTeamM1, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    } else if (quarter == 3) {
      require(block.timestamp > _created + 86400 * 210, "Core Team Q3 tokens can only be minted 210 days after EPH token creation");
      require(_minted.coreTeam < 3, "Core Team Q3 tokens were minted already");

      _mint(_walletCoreTeamM1, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    }  else if (quarter == 4) {
      require(block.timestamp > _created + 86400 * 300, "Core Team Q4 tokens can only be minted 300 days after EPH token creation");
      require(_minted.coreTeam < 4, "Core Team Q4 tokens were minted already");

      _mint(_walletCoreTeamM1, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    } else if (quarter == 5) {
      require(block.timestamp > _created + 86400 * 390, "Core Team Q5 tokens can only be minted 390 days after EPH token creation");
      require(_minted.coreTeam < 5, "Core Team Q5 tokens were minted already");

      _mint(_walletCoreTeamM1, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 1 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    } else if (quarter == 6) {
      require(block.timestamp > _created + 86400 * 480, "Core Team Q6 tokens can only be minted 480 days after EPH token creation");
      require(_minted.coreTeam < 6, "Core Team Q6 tokens were minted already");

      _mint(_walletCoreTeamM1, _maxSupply * 2 / 100);
      _mint(_walletCoreTeamM2, _maxSupply * 2 / 100);
      _mint(_walletCoreTeamM3, _maxSupply * 1 / 100);
      _minted.coreTeam++;
    } else {
      revert("Invalid param: quarter");
    }
  }

  function mintPlayToEarn(address receiver, uint amount) public onlyOwner {
    require(_minted.playToEarn + amount <= _maxSupply * 40 / 100, "Play to Earn tokens were minted already");

    _mint(receiver, amount);
    _minted.playToEarn += amount;
  }

  function mintReserve() public onlyOwner {
    require(!_minted.reserve, "Reserve tokens were minted already");

    _mint(_walletReserve, _maxSupply * 20 / 100);
    _minted.reserve = true;
  }

}
