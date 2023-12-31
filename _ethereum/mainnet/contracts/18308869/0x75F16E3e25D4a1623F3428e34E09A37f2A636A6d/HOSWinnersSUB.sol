// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HOSWinnersSUB is Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint public ownerCommission = 3;
  uint256 public currentSeason = 1;

  // *** EVENTS *** //
  event WithdrawFundsToNormalWinner(
    uint256 season,
    string class,
    address to,
    uint amount
  );
  event WithdrawFundsToHardcoreWinner(
    uint256 season,
    string class,
    address to,
    uint amount
  );
  event WithdrawFundsToTeamWinner(uint256 season, address to, uint amount);
  event OwnerCommissionWithdraw(address indexed to, uint amount);

  event SetClassWinnersNormalEvent(
    uint256 _season,
    string _class,
    address _firstPlace,
    address _secondPlace,
    address _thirdPlace
  );

  event SetClassWinnersHardcoreEvent(
    uint256 _season,
    string _class,
    address _firstPlace,
    address _secondPlace,
    address _thirdPlace
  );

  event SetTeamWinnersEvent(
    uint256 _season,
    Team _firstPlace,
    Team _secondPlace,
    Team _thirdPlace
  );

  event SetClaimStatusNormalEvent(
    uint256 _season,
    string _class,
    address _winner
  );

  event SetClaimStatusHardcoreEvent(
    uint256 _season,
    string _class,
    address _winner
  );

  event SetClaimStatusTeamEvent(uint256 _season, address _winner);

  // Mapping from season number to balance
  mapping(uint => bool) public ownerPaySeason;

  // Define a struct for the winners of each class
  struct ClassWinners {
    address firstPlace;
    address secondPlace;
    address thirdPlace;
  }

  // Define a struct for the winners of each season
  struct SeasonWinners {
    ClassWinners barbarian;
    ClassWinners rogue;
    ClassWinners sorcerer;
    ClassWinners druid;
    ClassWinners necromancer;
    ClassWinners paladin;
    ClassWinners monk;
    ClassWinners amazon;
    ClassWinners vampire;
    ClassWinners demon;
  }

  // Define a struct for a team
  struct Team {
    address player1;
    address player2;
    address player3;
    address player4;
  }

  // Define a struct for the team winners
  struct TeamWinners {
    Team firstPlace;
    Team secondPlace;
    Team thirdPlace;
  }

  // season => class => winners
  mapping(uint256 => mapping(string => ClassWinners))
    private _activeWinnersNormalSeason;
  mapping(uint256 => mapping(string => ClassWinners))
    private _activeWinnersHardcoreSeason;
  // season => winners
  mapping(uint256 => TeamWinners) private _activeWinnersTeams;

  // season => class => address => bool
  mapping(uint256 => mapping(string => mapping(address => bool)))
    private _claimedNormalSeason;
  mapping(uint256 => mapping(string => mapping(address => bool)))
    private _claimedHardcoreSeason;
  // season => address => bool
  mapping(uint256 => mapping(address => bool)) private _claimedTeamsSeason;

  // ********** SEASON WINNERS NORMAL ********** //

  // Function to set the winners for a given class and season for Normal mode
  // @@@ _class bargarian, rogue, sorcerer, druid, necromancer, paladin, monk, amazon, vampire, demon
  function setClassWinnersNormal(
    uint256 _season,
    string memory _class,
    address _firstPlace,
    address _secondPlace,
    address _thirdPlace
  ) public onlyOwner {
    ClassWinners memory winners;

    winners.firstPlace = _firstPlace;
    winners.secondPlace = _secondPlace;
    winners.thirdPlace = _thirdPlace;

    _activeWinnersNormalSeason[_season][_class] = winners;

    emit SetClassWinnersNormalEvent(
      _season,
      _class,
      _firstPlace,
      _secondPlace,
      _thirdPlace
    );
  }

  // Function to get the winners for a given class and season
  function getClassWinnersNormal(
    uint256 _season,
    string memory _class
  ) public view returns (address, address, address) {
    ClassWinners memory winners;

    winners = _activeWinnersNormalSeason[_season][_class];

    return (winners.firstPlace, winners.secondPlace, winners.thirdPlace);
  }

  // Function to get all the winners for a season in Normal mode
  function getEveryNormalWinners(
    uint256 _season,
    string[] memory _classes
  ) public view returns (ClassWinners[] memory) {
    require(
      _activeWinnersNormalSeason[_season][_classes[0]].firstPlace != address(0),
      "Winners not set"
    );

    ClassWinners[] memory winnersList = new ClassWinners[](_classes.length);
    for (uint i = 0; i < _classes.length; i++) {
      winnersList[i] = _activeWinnersNormalSeason[_season][_classes[i]];
    }

    return winnersList;
  }

  // ********** SEASON WINNERS HARDCORE ********** //

  // Function to set the winners for a given class and season for Hardcore mode
  function setClassWinnersHardcore(
    uint256 _season,
    string memory _class,
    address _firstPlace,
    address _secondPlace,
    address _thirdPlace
  ) public onlyOwner {
    ClassWinners memory winners;

    winners.firstPlace = _firstPlace;
    winners.secondPlace = _secondPlace;
    winners.thirdPlace = _thirdPlace;

    _activeWinnersHardcoreSeason[_season][_class] = winners;

    emit SetClassWinnersHardcoreEvent(
      _season,
      _class,
      _firstPlace,
      _secondPlace,
      _thirdPlace
    );
  }

  // Function to get the hardcore winners for a given class and season
  function getClassWinnersHardcore(
    uint256 _season,
    string memory _class
  ) public view returns (address, address, address) {
    ClassWinners memory winners;

    winners = _activeWinnersHardcoreSeason[_season][_class];

    return (winners.firstPlace, winners.secondPlace, winners.thirdPlace);
  }

  // Function to get all the winners for a season in harcore mode
  function getEveryHardcoreWinners(
    uint256 _season,
    string[] memory _classes
  ) public view returns (ClassWinners[] memory) {
    require(
      _activeWinnersHardcoreSeason[_season][_classes[0]].firstPlace !=
        address(0),
      "Winners not set"
    );

    ClassWinners[] memory winnersList = new ClassWinners[](_classes.length);
    for (uint i = 0; i < _classes.length; i++) {
      winnersList[i] = _activeWinnersHardcoreSeason[_season][_classes[i]];
    }

    return winnersList;
  }

  // Function to set the team winners for a season
  function setTeamWinners(
    uint256 _season,
    Team memory _firstPlace,
    Team memory _secondPlace,
    Team memory _thirdPlace
  ) public onlyOwner {
    TeamWinners memory winners;

    winners.firstPlace = _firstPlace;
    winners.secondPlace = _secondPlace;
    winners.thirdPlace = _thirdPlace;

    _activeWinnersTeams[_season] = winners;

    emit SetTeamWinnersEvent(_season, _firstPlace, _secondPlace, _thirdPlace);
  }

  // Function to get the team winners for a season
  function getTeamWinners(
    uint256 _season
  ) public view returns (Team memory, Team memory, Team memory) {
    TeamWinners memory winners = _activeWinnersTeams[_season];

    return (winners.firstPlace, winners.secondPlace, winners.thirdPlace);
  }

  // Set claim status for normal season winner
  function setClaimStatusNormal(
    uint256 _season,
    string memory _class,
    address _winner
  ) public onlyOwner {
    _claimedNormalSeason[_season][_class][_winner] = true;
    emit SetClaimStatusNormalEvent(_season, _class, _winner);
  }

  // Get claim status for normal season winner
  function getClaimStatusNormal(
    uint256 _season,
    string memory _class,
    address _winner
  ) public view returns (bool) {
    return _claimedNormalSeason[_season][_class][_winner];
  }

  // Set claim status for hardcore season winner
  function setClaimStatusHardcore(
    uint256 _season,
    string memory _class,
    address _winner
  ) public onlyOwner {
    _claimedHardcoreSeason[_season][_class][_winner] = true;
    emit SetClaimStatusHardcoreEvent(_season, _class, _winner);
  }

  // Get claim status for hardcore season winner
  function getClaimStatusHardcore(
    uint256 _season,
    string memory _class,
    address _winner
  ) public view returns (bool) {
    return _claimedHardcoreSeason[_season][_class][_winner];
  }

  // Set claim status for team season winner
  function setClaimStatusTeam(
    uint256 _season,
    address _winner
  ) public onlyOwner {
    _claimedTeamsSeason[_season][_winner] = true;
    emit SetClaimStatusTeamEvent(_season, _winner);
  }

  // Get claim status for team season winner
  function getClaimStatusTeam(
    uint256 _season,
    address _winner
  ) public view returns (bool) {
    return _claimedTeamsSeason[_season][_winner];
  }

  // Withdawing funds to winners of the season for all categories, normal, hardcore and team.
  function withdrawFundsToWinner(
    address payable _to,
    uint _amount,
    string memory _class,
    uint _season,
    uint _mode // 0 = normal, 1 = hardcore, 2 = team
  ) public onlyOwner nonReentrant {
    require(address(this).balance >= _amount, "Not enough funds");
    require(_to != address(0), "Zero address invalid");

    if (_mode == 0) {
      (
        address firstPlace,
        address secondPlace,
        address thirdPlace
      ) = getClassWinnersNormal(_season, _class);
      require(
        _to == thirdPlace || _to == secondPlace || _to == firstPlace,
        "Not winner"
      );
      require(!getClaimStatusNormal(_season, _class, _to), "Already claimed");
    } else if (_mode == 1) {
      (
        address firstPlace,
        address secondPlace,
        address thirdPlace
      ) = getClassWinnersHardcore(_season, _class);
      require(
        _to == thirdPlace || _to == secondPlace || _to == firstPlace,
        "Not winner"
      );
      require(!getClaimStatusHardcore(_season, _class, _to), "Already claimed");
    } else if (_mode == 2) {
      (
        Team memory firstPlace,
        Team memory secondPlace,
        Team memory thirdPlace
      ) = getTeamWinners(_season);
      require(
        _to == firstPlace.player1 ||
          _to == firstPlace.player2 ||
          _to == firstPlace.player3 ||
          _to == firstPlace.player4 ||
          _to == secondPlace.player1 ||
          _to == secondPlace.player2 ||
          _to == secondPlace.player3 ||
          _to == secondPlace.player4 ||
          _to == thirdPlace.player1 ||
          _to == thirdPlace.player2 ||
          _to == thirdPlace.player3 ||
          _to == thirdPlace.player4 ||
          // check second and third place
          false,
        "Not winner"
      );
      require(!getClaimStatusTeam(_season, _to), "Already claimed");
    } else {
      revert("wrong mode");
    }

    // Transfer the funds
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send Ether");

    if (_mode == 0) {
      setClaimStatusNormal(_season, _class, _to);
      emit WithdrawFundsToNormalWinner(_season, _class, _to, _amount);
    } else if (_mode == 1) {
      setClaimStatusHardcore(_season, _class, _to);
      emit WithdrawFundsToHardcoreWinner(_season, _class, _to, _amount);
    } else if (_mode == 2) {
      setClaimStatusTeam(_season, _to);
      emit WithdrawFundsToTeamWinner(_season, _to, _amount);
    }
  }

  // Withdrawing percentange from contract to a specified address by Owner, once per season
  function withdrawFundsForOwner(
    address payable _to
  ) public onlyOwner nonReentrant {
    uint contractBalance = address(this).balance;
    require(contractBalance > 0, "No funds");
    require(_to != address(0), "invalid");
    require(!ownerPaySeason[currentSeason], "Already paid");

    uint ammount = (contractBalance * ownerCommission) / 100;

    (bool success, ) = _to.call{value: ammount}("");
    require(success, "Failed");
    ownerPaySeason[currentSeason] = true;
    emit OwnerCommissionWithdraw(_to, ammount);
  }
}
