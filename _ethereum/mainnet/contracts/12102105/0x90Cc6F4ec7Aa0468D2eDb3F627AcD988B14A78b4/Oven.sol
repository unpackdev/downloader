//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;


import "./IERC20.sol"; 
import "./SafeERC20.sol";
import "./Math.sol";
import "./AccessControl.sol";
import "./IRecipe.sol";


contract Oven is AccessControl {
  using SafeERC20 for IERC20;
  using Math for uint256;

  bytes32 constant public BAKER_ROLE = keccak256(abi.encode("BAKER_ROLE"));
  uint256 constant public MAX_FEE = 10 * 10**16; //10%

  IERC20 public inputToken;
  IERC20 public outputToken;


  uint256 public roundSizeInputAmount;
  IRecipe public recipe;


  struct Round {
    uint256 totalDeposited;
    mapping(address => uint256) deposits;

    uint256 totalBakedInput;
    uint256 totalOutput;
  }

  struct ViewRound {
    uint256 totalDeposited;
    uint256 totalBakedInput;
    uint256 totalOutput;
  }

  Round[] public rounds;

  mapping(address => uint256[]) userRounds;

  uint256 public fee = 0; //default 0% (10**16 == 1%)
  address public feeReceiver;

  event Deposit(address indexed from, address indexed to, uint256 amount);
  event Withdraw(address indexed from, address indexed to, uint256 inputAmount, uint256 outputAmount);
  event FeeReceiverUpdate(address indexed previousReceiver, address indexed newReceiver);
  event FeeUpdate(uint256 previousFee, uint256 newFee);
  event RecipeUpdate(address indexed oldRecipe, address indexed newRecipe);
  event RoundSizeUpdate(uint256 oldRoundSize, uint256 newRoundSize);

  modifier onlyBaker() {
    require(hasRole(BAKER_ROLE, _msgSender()), "NOT_BAKER");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "NOT_ADMIN");
    _;
  }

  function initialize(address _inputToken, address _outputToken, uint256 _roundSizeInputAmount, address _recipe) external {
    require(address(inputToken) == address(0), "Oven.initializer: Already initialized");
    
    require(_inputToken != address(0), "INPUT_TOKEN_ZERO");
    require(_outputToken != address(0), "OUTPUT_TOKEN_ZERO");
    require(_recipe != address(0), "RECIPE_ZERO");
    
    inputToken = IERC20(_inputToken);
    outputToken = IERC20(_outputToken);
    roundSizeInputAmount = _roundSizeInputAmount;
    recipe = IRecipe(_recipe);

    // create first empty round
    rounds.push();

    // approve input token
    IERC20(_inputToken).safeApprove(_recipe, type(uint256).max);

    //grant default admin role
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    //grant baker role
    _setRoleAdmin(BAKER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(BAKER_ROLE, _msgSender());
  }

  function deposit(uint256 _amount) external {
    depositTo(_amount, _msgSender());
  }

  function depositTo(uint256 _amount, address _to) public {
    IERC20 inputToken_ = inputToken;
    inputToken_.safeTransferFrom(_msgSender(), address(this), _amount);
    _depositTo(_amount, _to);
  }

  function _depositTo(uint256 _amount, address _to) internal {
    // if amount is zero return early
    if(_amount == 0) {
      return;
    }

    uint256 roundSizeInputAmount_ = roundSizeInputAmount; //gas saving

    uint256 currentRound = rounds.length - 1;
    uint256 deposited = 0;

    while(deposited < _amount) {
      //if the current round does not exist create it
      if(currentRound >= rounds.length) {
        rounds.push();
      }

      //if the round is already partially baked create a new round
      if(rounds[currentRound].totalBakedInput != 0) {
        currentRound ++;
        rounds.push();
      }

      Round storage round = rounds[currentRound];

      uint256 roundDeposit = (_amount - deposited).min(roundSizeInputAmount_ - round.totalDeposited);

      round.totalDeposited += roundDeposit;
      round.deposits[_to] += roundDeposit;

      deposited += roundDeposit;

      // only push rounds we are actually in
      if(roundDeposit != 0) {
        pushUserRound(_to, currentRound);
      }

      // if full amount assigned to rounds break the loop
      if(deposited == _amount) {
        break;
      }

      currentRound ++;
    }

    emit Deposit(_msgSender(), _to, _amount);
  }

  function pushUserRound(address _to, uint256 _roundId) internal {
    // only push when its not already added
    if(userRounds[_to].length == 0 || userRounds[_to][userRounds[_to].length - 1] != _roundId) {
      userRounds[_to].push(_roundId);
    }     
  }

  function withdraw(uint256 _roundsLimit) public {
    withdrawTo(_msgSender(), _roundsLimit);
  }


  function withdrawTo(address _to, uint256 _roundsLimit) public {
    uint256 inputAmount;
    uint256 outputAmount;
    
    uint256 userRoundsLength = userRounds[_msgSender()].length;
    uint256 numRounds = userRoundsLength.min(_roundsLimit);

    for(uint256 i = 0; i < numRounds; i ++) {
      // start at end of array for efficient popping of elements
      uint256 roundIndex = userRounds[_msgSender()][userRoundsLength - i - 1];
      Round storage round = rounds[roundIndex];

      //amount of input of user baked
      uint256 bakedInput = round.deposits[_msgSender()] * round.totalBakedInput / round.totalDeposited;
      //amount of output the user is entitled to

      uint256 userRoundOutput;
      if(bakedInput == 0) {
        userRoundOutput = 0;
      } else {
        userRoundOutput = round.totalOutput * bakedInput / round.totalBakedInput;
      }
      
      // unbaked input
      inputAmount += round.deposits[_msgSender()] - bakedInput;
      //amount of output the user is entitled to
      outputAmount += userRoundOutput;

      round.totalDeposited -= round.deposits[_msgSender()] - bakedInput;
      round.deposits[_msgSender()] = 0;
      round.totalBakedInput -= bakedInput;

      round.totalOutput -= userRoundOutput;

      //pop of user round
      userRounds[_msgSender()].pop();
    }

    if(inputAmount != 0) {
      // handle rounding issues due to integer division inaccuracies
      inputAmount = inputAmount.min(inputToken.balanceOf(address(this)));
      inputToken.safeTransfer(_to, inputAmount);
    }
    
    if(outputAmount != 0) {
      // handle rounding issues due to integer division inaccuracies
      outputAmount = outputAmount.min(outputToken.balanceOf(address(this)));
      outputToken.safeTransfer(_to, outputAmount);
    }

    emit Withdraw(_msgSender(), _to, inputAmount, outputAmount);
  }

  function bake(bytes calldata _data, uint256[] memory _rounds) external onlyBaker {
    uint256 maxInputAmount;

    //get input amount
    for(uint256 i = 0; i < _rounds.length; i ++) {
      
      // prevent round from being baked twice
      if(i != 0) {
        require(_rounds[i] > _rounds[i - 1], "Rounds out of order");
      }

      Round storage round = rounds[_rounds[i]];
      maxInputAmount += (round.totalDeposited - round.totalBakedInput);
    }

    // subtract fee amount from input
    uint256 maxInputAmountMinusFee = maxInputAmount * (10**18 - fee) / 10**18;

    //bake
    (uint256 inputUsed, uint256 outputAmount) = recipe.bake(address(inputToken), address(outputToken), maxInputAmountMinusFee, _data);

    uint256 inputUsedRemaining = inputUsed;

    for(uint256 i = 0; i < _rounds.length; i ++) {
      Round storage round = rounds[_rounds[i]];

      uint256 roundInputBaked = (round.totalDeposited - round.totalBakedInput).min(inputUsedRemaining);

      // skip round if it is already baked
      if(roundInputBaked == 0) {
        continue;
      }

  	  uint256 roundInputBakedWithFee = roundInputBaked * 10**18 / (10**18 - fee);

      uint256 roundOutputBaked = outputAmount * roundInputBaked / inputUsed;

      round.totalBakedInput += roundInputBakedWithFee;
      inputUsedRemaining -= roundInputBaked;
      round.totalOutput += roundOutputBaked;

      //sanity check
      require(round.totalBakedInput <= round.totalDeposited, "Input sanity check failed");
    }

    uint256 feeAmount = (inputUsed * 10**18 / (10**18 - fee)) - inputUsed;
    address feeReceiver_ = feeReceiver; //gas saving
    if(feeAmount != 0) {
      
      // if no fee receiver is set send it to the baker
      if(feeReceiver == address(0)) {
        feeReceiver_ = _msgSender();
      }
      inputToken.safeTransfer(feeReceiver_, feeAmount);
    }
    
  }

  function setFee(uint256 _newFee) external onlyAdmin {
    require(_newFee <= MAX_FEE, "INVALID_FEE");
    emit FeeUpdate(fee, _newFee);
    fee = _newFee;
  }

  function setRoundSize(uint256 _roundSize) external onlyAdmin {
    emit RoundSizeUpdate(roundSizeInputAmount, _roundSize);
    roundSizeInputAmount = _roundSize;
  }

  function setRecipe(address _recipe) external onlyAdmin {
    emit RecipeUpdate(address(recipe), _recipe);
    
    //revoke old approval
    if(address(recipe) != address(0)) {
      inputToken.approve(address(recipe), 0);
    }

    recipe = IRecipe(_recipe);

    //set new approval
    if(address(recipe) != address(0)) {
      inputToken.approve(address(recipe), type(uint256).max);
    }
  }

  function saveToken(address _token, address _to, uint256 _amount) external onlyAdmin {
    IERC20(_token).transfer(_to, _amount);
  }
  
  function saveEth(address payable _to, uint256 _amount) external onlyAdmin {
    _to.call{value: _amount}("");
  }

  function setFeeReceiver(address _feeReceiver) external onlyAdmin {
    emit FeeReceiverUpdate(feeReceiver, _feeReceiver);
    feeReceiver = _feeReceiver;
  }

  function roundInputBalanceOf(uint256 _round, address _of) public view returns(uint256) {
    Round storage round = rounds[_round];
    // if there are zero deposits the input balance of `_of` would be zero too
    if(round.totalDeposited == 0) {
      return 0;
    }
    uint256 bakedInput = round.deposits[_of] * round.totalBakedInput / round.totalDeposited;
    return round.deposits[_of] - bakedInput;
  }

  function inputBalanceOf(address _of) public view returns(uint256) {
    uint256 roundsCount = userRounds[_of].length;

    uint256 balance;

    for(uint256 i = 0; i < roundsCount; i ++) {
      balance += roundInputBalanceOf(userRounds[_of][i], _of);
    }

    return balance;
  }

  function roundOutputBalanceOf(uint256 _round, address _of) public view returns(uint256) {
    Round storage round = rounds[_round];

    if(round.totalBakedInput == 0) {
      return 0;
    }

    //amount of input of user baked
    uint256 bakedInput = round.deposits[_of] * round.totalBakedInput / round.totalDeposited;
    //amount of output the user is entitled to
    uint256 userRoundOutput = round.totalOutput * bakedInput / round.totalBakedInput;

    return userRoundOutput;
  }

  function outputBalanceOf(address _of) external view returns(uint256) {
    uint256 roundsCount = userRounds[_of].length;

    uint256 balance;

    for(uint256 i = 0; i < roundsCount; i ++) {
      balance += roundOutputBalanceOf(userRounds[_of][i], _of);
    }

    return balance;
  }

  function getUserRoundsCount(address _user) external view returns(uint256) {
    return userRounds[_user].length;
  }

  function getRoundsCount() external view returns(uint256) {
    return rounds.length;
  }

  // Gets all rounds. Might run out of gas after many rounds
  function getRounds() external view returns (ViewRound[] memory) {
    return getRoundsRange(0, rounds.length -1);
  }

  function getRoundsRange(uint256 _from, uint256 _to) public view returns(ViewRound[] memory) {
    ViewRound[] memory result = new ViewRound[](_to - _from + 1);

    for(uint256 i = _from; i <= _to; i ++) {
      Round storage round = rounds[i];
      result[i].totalDeposited = round.totalDeposited;
      result[i].totalBakedInput = round.totalBakedInput;
      result[i].totalOutput = round.totalOutput;
    }

    return result;
  }

}
