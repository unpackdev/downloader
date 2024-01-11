// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

interface IWealthyTowersApartments {
  function ownerOf(uint256 tokenId) external returns (address);

  function getApartmentType(uint256 _tokenId) external view returns (uint8);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract WealthyTowersApartmentsStaking is OwnableUpgradeable, UUPSUpgradeable {
  IWealthyTowersApartments private wealthyTowersApartmentsStakingContract;

  struct Token {
    uint256 id;
    uint256 lastUpdate;
  }

  mapping(address => Token[]) private stakedTokens;

  address private wealthyApeSocialClubStakingContract;

  modifier onlyStakingContract() {
    require(msg.sender == wealthyApeSocialClubStakingContract);
    _;
  }

  function initialize(
    address _wealthyTowersApartmentsStakingContract,
    address _wealthyApeSocialClubStakingContract
  ) public initializer {
    __Ownable_init();

    wealthyTowersApartmentsStakingContract = IWealthyTowersApartments(
      _wealthyTowersApartmentsStakingContract
    );

    wealthyApeSocialClubStakingContract = _wealthyApeSocialClubStakingContract;
  }

  function stake(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; ++i) {
      Token memory token;
      token.id = _tokenIds[i];
      token.lastUpdate = block.timestamp;

      stakedTokens[tx.origin].push(token);

      wealthyTowersApartmentsStakingContract.transferFrom(
        tx.origin,
        address(this),
        _tokenIds[i]
      );
    }
  }

  function unstake(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    for (uint256 i; i < _tokenIds.length; ++i) {
      bool found = false;

      for (uint256 j; j < stakedTokens[_msgSender()].length; ++j) {
        if (stakedTokens[_msgSender()][j].id == _tokenIds[i]) {
          found = true;

          stakedTokens[_msgSender()][j] = stakedTokens[_msgSender()][
            stakedTokens[_msgSender()].length - 1
          ];
          stakedTokens[_msgSender()].pop();
          break;
        }
      }

      require(found, "Not token owner");

      wealthyTowersApartmentsStakingContract.transferFrom(
        address(this),
        _msgSender(),
        _tokenIds[i]
      );
    }
  }

  function stakeOf(address _owner) public view returns (uint256[] memory) {
    uint256 _balance = stakedTokens[_msgSender()].length;
    uint256[] memory wallet = new uint256[](_balance);

    for (uint256 i; i < stakedTokens[_msgSender()].length; ++i) {
      wallet[i] = stakedTokens[_owner][i].id;
    }

    return wallet;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0), "Zero address not allowed");

    return stakedTokens[_owner].length;
  }

  function getTokenPendingWealth(Token memory _token)
    public
    view
    returns (uint256)
  {
    uint256 wealthRate;

    if (
      wealthyTowersApartmentsStakingContract.getApartmentType(_token.id) == 1
    ) {
      // Standard
      wealthRate = 75 ether;
    } else if (
      wealthyTowersApartmentsStakingContract.getApartmentType(_token.id) == 2
    ) {
      // Studio
      wealthRate = 100 ether;
    } else if (
      wealthyTowersApartmentsStakingContract.getApartmentType(_token.id) == 3
    ) {
      // Penthouse
      wealthRate = 150 ether;
    }

    return ((wealthRate * (block.timestamp - _token.lastUpdate)) / 86400);
  }

  function getPendingWealthOf(address _owner) public view returns (uint256) {
    uint256 totalBalance;

    for (uint256 i; i < stakedTokens[_owner].length; ++i) {
      totalBalance += getTokenPendingWealth(stakedTokens[_owner][i]);
    }

    return totalBalance;
  }

  function getStakedTokensOf(address _owner)
    public
    view
    returns (Token[] memory)
  {
    return stakedTokens[_owner];
  }

  function updateStakedTokenTimestampsOf(address _owner)
    external
    onlyStakingContract
  {
    for (uint256 i; i < stakedTokens[_owner].length; ++i) {
      stakedTokens[_owner][i].lastUpdate = block.timestamp;
    }
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {} // solhint-disable-line no-empty-blocks
}
