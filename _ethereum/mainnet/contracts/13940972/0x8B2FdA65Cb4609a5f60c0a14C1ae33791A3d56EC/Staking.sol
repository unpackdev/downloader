// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Turtles.sol";
import "./SHELL.sol";

contract Staking is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {

  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    uint80 time; 
    address owner;
  }

  // reference to the Turtle mint contract
  Turtles public turtles;
  // reference to the $SHELL contract 
  SHELL public shell;

  // maps ID of Turtle to stake
  mapping(uint256 => Stake) public stakedTurtle; 
  // maps address to amount of Turtles staked
  mapping(address => uint256) public amountOfTurtlesStaked;
 
  // there will only ever be 90 million $SHELL earned through staking
  uint256 public constant MAXIMUM_GLOBAL_SHELL = 90000000 ether;
  // daily earnable shells decrease over time as more shells have been supplied
  // 0 to 24 million supplied: earn 3 $SHELL per day
  // 24 to 60 million supplied: earn 2 $SHELL per day
  // 60 to 90 million supplied: earn 1 $SHELL per day
  uint256 public constant SHELL_SUPPLIED_LOW = 24000000 ether;
  uint256 public constant SHELL_SUPPLIED_MEDIUM = 60000000 ether;
  // amount of $SHELL earned so far
  uint256 public totalShellEarned = 0 ether;
  // staked Turtles earn a certain amount of $SHELL per day
  uint256 public dailyShellRate = 3 ether;
  // number of Turtles staked 
  uint256 public totalTurtlesStaked = 0;
  // the last time $SHELL was claimed
  uint256 public lastClaimTimestamp;

  event TurtleStaked(address owner, uint256 tokenId, uint256 time);
  event TurtleClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  /**
   * @param _turtles reference to the Turtles NFT contract
   * @param _shell reference to the $SHELL token
   */
  constructor(address _turtles, address _shell) { 
    turtles = Turtles(_turtles);
    shell = SHELL(_shell);
  }

  // STAKING TURTLES

  /**
   * Stakes the given amount of Turtles
   * @param _tokenIds the IDs of the Turtles
   */
  function stakeTurtles(uint16[] calldata _tokenIds) external _updateEarnings { 
    require(_tokenIds.length <= 15, "INVALID STAKE AMOUNT! YOU CAN ONLY STAKE 15 TURTLES!");
    require((amountOfTurtlesStaked[msg.sender] + _tokenIds.length) <= 15, "YOU CAN ONLY HAVE 15 TURTLES STAKED AT THE SAME TIME!");
    for (uint i = 0; i < _tokenIds.length; i++) {
        require(turtles.ownerOf(_tokenIds[i]) == _msgSender(), "THIS IS NOT YOUR TOKEN");
        turtles.transferFrom(_msgSender(), address(owner()), _tokenIds[i]); 
        _stakeTurtle(_msgSender(), _tokenIds[i]);
    }
  }

  /**
   * Stakes a single Turtle
   * @param _address address of the staker
   * @param _tokenId the ID of the Turtle
   */
  function _stakeTurtle(address _address, uint256 _tokenId) internal whenNotPaused {
    require(amountOfTurtlesStaked[msg.sender] <= 15, "YOU CAN ONLY HAVE 15 TURTLES STAKED AT THE SAME TIME!");
    stakedTurtle[_tokenId] = Stake({
      owner: _address,
      tokenId: uint16(_tokenId),
      time: uint80(block.timestamp)
    });
    totalTurtlesStaked += 1;
    amountOfTurtlesStaked[_address] += 1;
    emit TurtleStaked(_address, _tokenId, block.timestamp);
  }

  // CLAIMING AND UNSTAKING TURTLES

  /**
   * Claim $SHELL earnings for multiple Turtles and optionally unstake them 
   * @param _tokenIds the IDs of the Turtles to claim earnings from
   * @param _unstake whether or not to unstake all of the Turtles listed in _tokenIds
   */
  function claimStakedTurtles(uint16[] calldata _tokenIds, bool _unstake) external whenNotPaused _updateEarnings nonReentrant {
    uint256 earnings = 0;
    for (uint i = 0; i < _tokenIds.length; i++) {
        earnings += _claimStakedTurtle(_tokenIds[i], _unstake);
    }
    if (earnings == 0) return;
    shell.mint(_msgSender(), earnings);
  }

  /**
   * Claim $SHELL earnings for a single Turtle and optionally unstake it
   * @param _tokenId the ID of the Turtle to claim earnings from
   * @param _unstake whether or not to unstake the Turtle
   * @return earnings - the amount of $SHELL earned
   */
  function _claimStakedTurtle(uint256 _tokenId, bool _unstake) internal _getCurrentShellRate returns (uint256 earnings) {
    Stake memory stake = stakedTurtle[_tokenId];
    require(stake.owner == _msgSender(), "HEY! DON'T STEAL!");
    if (totalShellEarned < MAXIMUM_GLOBAL_SHELL) {
      earnings = (block.timestamp - stake.time) * dailyShellRate / 1 days; 
    } else if (stake.time > lastClaimTimestamp) { 
      earnings = 0; 
    } else {
      earnings = (lastClaimTimestamp - stake.time) * dailyShellRate / 1 days; 
    }
    if (_unstake) {
      turtles.transferFrom(address(owner()), _msgSender(), _tokenId); 
      delete stakedTurtle[_tokenId];
      totalTurtlesStaked -= 1;
      amountOfTurtlesStaked[_msgSender()] -= 1;
    } else {
      stakedTurtle[_tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(_tokenId),
        time: uint80(block.timestamp)
      });
    }
    emit TurtleClaimed(_tokenId, earnings, _unstake);
  }
  

  /**
  * Query amount of current staking earnings from multiple Turtles
  * @param _tokenIds the IDs of the tokens to query earnings from
  */
  function queryStakingProfits(uint256[] calldata _tokenIds) external view returns (uint256 earnings) {
    earnings = 0;
    for (uint i = 0; i < _tokenIds.length; i++) {
      earnings += querySingleStakingProfit(_tokenIds[i]);
    }
    return earnings;
  }

  /**
  * Query amount of current staking earnings from a single Turtle
  * @param _tokenId the ID of the token to query earnings from
  */
  function querySingleStakingProfit(uint256 _tokenId) internal view returns (uint256 earnings) {
    earnings = 0;
    Stake memory stake;
    stake = stakedTurtle[_tokenId];
    require(stake.owner != 0x0000000000000000000000000000000000000000, "TURTLE CURRENTLY NOT STAKED!");
    require(stake.owner == _msgSender() || _msgSender() == owner(), "HEY! THIS IS NOT YOURS!");
    if (totalShellEarned < MAXIMUM_GLOBAL_SHELL) {
      return earnings = (block.timestamp - stake.time) * dailyShellRate / 1 days; 
    } else if (stake.time > lastClaimTimestamp) { 
      return earnings = 0; 
    } else {
      return earnings = (lastClaimTimestamp - stake.time) * dailyShellRate / 1 days; 
    }
  }

  /**
  * Query duration of staked Turtle by ID
  * @param _tokenId the ID of the token to query staking duration from
  */
  function queryStakingDurationInSeconds(uint256 _tokenId) external view returns (uint256 time) {
    Stake memory stake = stakedTurtle[_tokenId];
    require(msg.sender == stake.owner || msg.sender == owner(), "THIS IS NOT YOUR TURTLE!");
    if((block.timestamp - stake.time) == 1640697428) return 0;
    else return (block.timestamp - stake.time);
  }

  // MODIFIERS

  /**
   * updates $SHELL earnings, stops once 90 million shell have been earned
   */
  modifier _updateEarnings() {
    if (totalShellEarned < MAXIMUM_GLOBAL_SHELL) {
      totalShellEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalTurtlesStaked
        * dailyShellRate / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  /**
   * Sets the $SHELL payout rate according to the amount of $SHELL that has been minted already
   */
  modifier _getCurrentShellRate() {
    if(totalShellEarned <= SHELL_SUPPLIED_LOW) {
        dailyShellRate = 3 ether;
    }
    else if(totalShellEarned <= SHELL_SUPPLIED_MEDIUM) {
        dailyShellRate = 2 ether;
    }
    else {
        dailyShellRate = 1 ether;
    }
    _;
  }

  // ONLY FOR TURTLE ADMINS

  /**
   * Increases the total shell earned. Used for Burning mechanism.
   * @param _amount the amount of shell to be added to the counter
   */
  function increaseTotalShellEarned(uint256 _amount) public onlyOwner {
      totalShellEarned += _amount;
  }
  /**
   * Decreases the total shell earned. 
   * @param _amount the amount of shell to be subtracted from the counter
   */
  function decreaseTotalShellEarned(uint256 _amount) public onlyOwner {
      totalShellEarned -= _amount;
  }
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }
  function setDailyShellRate(uint256 _shellrate) external onlyOwner {
    dailyShellRate = _shellrate;
  }


  // UTILS

  function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "CAN'T DO THAT!");
      return IERC721Receiver.onERC721Received.selector;
    }
} 