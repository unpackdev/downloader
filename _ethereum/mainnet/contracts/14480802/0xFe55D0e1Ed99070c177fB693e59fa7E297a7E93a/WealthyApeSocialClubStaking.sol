// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

interface IWealth {
  function transfer(address to, uint256 amount) external returns (bool);
}

interface IWealthyApeSocialClub {
  function ownerOf(uint256 tokenId) external returns (address);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract WealthyApeSocialClubStaking is OwnableUpgradeable, UUPSUpgradeable {
  IWealth private wealthContract;
  IWealthyApeSocialClub private wealthyApeSocialClubContract;

  uint256 private endOfFirstWeek;
  address private verifier;

  struct Token {
    uint256 id;
    uint256 lastUpdate;
    uint8 reputation;
  }

  mapping(address => Token[]) private stakedTokens;
  // 0 ignore, 1 eligible, 2 claimed
  mapping(uint256 => uint8) private firstWeekBonus;

  function initialize(
    address _wealthyApeSocialClubContract,
    address _wealthContract
  ) public initializer {
    __Ownable_init();

    wealthContract = IWealth(_wealthContract);
    wealthyApeSocialClubContract = IWealthyApeSocialClub(
      _wealthyApeSocialClubContract
    );

    verifier = 0xb80a45f186Cee437980A0De1C99461797867952C;

    // Bonus deadline: 7th April 2022 00:00:00
    endOfFirstWeek = 1649289600;
  }

  function _recoverWallet(
    address _wallet,
    uint256[] calldata _tokenIds,
    uint8[] calldata _tokenTypes,
    bytes memory _signature
  ) internal pure returns (address) {
    return
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(
          keccak256(abi.encodePacked(_wallet, _tokenIds, _tokenTypes))
        ),
        _signature
      );
  }

  function stake(
    uint256[] calldata _tokenIds,
    uint8[] calldata _tokenTypes,
    bytes calldata _signature
  ) external {
    require(_tokenIds.length > 0, "tokenIds must not be empty");
    require(_tokenTypes.length > 0, "tokenTypes must not be empty");
    require(
      _tokenIds.length == _tokenTypes.length,
      "tokenIds and tokenTypes must match"
    );

    address signer = _recoverWallet(
      _msgSender(),
      _tokenIds,
      _tokenTypes,
      _signature
    );

    require(signer == verifier, "Unverified transaction");

    for (uint256 i; i < _tokenIds.length; i++) {
      require(
        wealthyApeSocialClubContract.ownerOf(_tokenIds[i]) == _msgSender(),
        "Not token owner"
      );

      Token memory token;
      token.id = _tokenIds[i];
      token.lastUpdate = block.timestamp;
      token.reputation = _tokenTypes[i];

      stakedTokens[_msgSender()].push(token);

      if (
        block.timestamp < endOfFirstWeek && firstWeekBonus[_tokenIds[i]] == 0
      ) {
        firstWeekBonus[_tokenIds[i]] = 1;
      }

      wealthyApeSocialClubContract.transferFrom(
        _msgSender(),
        address(this),
        _tokenIds[i]
      );
    }
  }

  function unstake(uint256[] calldata _tokenIds) external {
    require(_tokenIds.length > 0, "tokenIds must not be empty");

    uint256 pendingWealth;

    for (uint256 i; i < _tokenIds.length; i++) {
      bool found = false;

      for (uint256 j; j < stakedTokens[_msgSender()].length; ++j) {
        if (stakedTokens[_msgSender()][j].id == _tokenIds[i]) {
          found = true;
          pendingWealth += getTokenPendingWealth(stakedTokens[_msgSender()][j]);

          stakedTokens[_msgSender()][j] = stakedTokens[_msgSender()][
            stakedTokens[_msgSender()].length - 1
          ];
          stakedTokens[_msgSender()].pop();
          break;
        }
      }

      require(found, "Not token owner");

      // Remove from storage to refund gas
      if (
        block.timestamp > endOfFirstWeek && firstWeekBonus[_tokenIds[i]] != 0
      ) {
        delete firstWeekBonus[_tokenIds[i]];
      }

      wealthyApeSocialClubContract.transferFrom(
        address(this),
        _msgSender(),
        _tokenIds[i]
      );
    }

    wealthContract.transfer(_msgSender(), pendingWealth);
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
    internal
    view
    returns (uint256)
  {
    uint256 wealthRate;
    uint256 firstWeekBonusWealth;

    if (_token.reputation == 1) {
      // Shiller
      wealthRate = 100 ether;
    } else if (_token.reputation == 2) {
      // Flipper
      wealthRate = 103 ether;
    } else if (_token.reputation == 3) {
      // Hodler
      wealthRate = 110 ether;
    } else if (_token.reputation == 4) {
      // Fudder
      wealthRate = 116 ether;
    } else if (_token.reputation == 5) {
      // Whale
      wealthRate = 121 ether;
    }

    uint256 daysStaked = (block.timestamp - _token.lastUpdate) / 86400;

    if (daysStaked > 60) {
      wealthRate += (wealthRate * 20) / 100;
    } else if (daysStaked > 30) {
      wealthRate += (wealthRate * 10) / 100;
    }

    if (firstWeekBonus[_token.id] == 1) {
      firstWeekBonusWealth = 1000 ether;
    }

    return
      firstWeekBonusWealth +
      ((wealthRate * (block.timestamp - _token.lastUpdate)) / 86400);
  }

  function getPendingWealthOf(address _owner) public view returns (uint256) {
    uint256 totalBalance;

    for (uint256 i; i < stakedTokens[_owner].length; ++i) {
      totalBalance += getTokenPendingWealth(stakedTokens[_owner][i]);
    }

    return totalBalance;
  }

  function claim() external {
    uint256 totalBalance = getPendingWealthOf(_msgSender());

    for (uint256 i; i < stakedTokens[_msgSender()].length; ++i) {
      stakedTokens[_msgSender()][i].lastUpdate = block.timestamp;

      if (firstWeekBonus[stakedTokens[_msgSender()][i].id] == 1) {
        firstWeekBonus[stakedTokens[_msgSender()][i].id] = 2;
      }
    }

    wealthContract.transfer(_msgSender(), totalBalance);
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {} // solhint-disable-line no-empty-blocks
}
