// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;
pragma abicoder v2;

// import "./LinkTokenInterface.sol";
// import "./VRFCoordinatorV2Interface.sol";
// import "./VRFConsumerBaseV2.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IWETH.sol";


//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}

contract SwapTest {
  // VRFCoordinatorV2Interface COORDINATOR;
  // LinkTokenInterface LINKTOKEN;

  // Goerli coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

  // Goerli LINK token contract. For other networks, see
  // https://docs.chain.link/docs/vrf-contracts/#configurations
  // address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

  // A reasonable default is 100000, but this value could be different
  // on other networks.
  // uint32 callbackGasLimit = 2500000;

  // The default is 3, but you can set this higher.
  // uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  // uint32 numWords =  500;

  // Storage parameters
  // uint256[] private s_randomWords;
  // uint256 public s_requestId;
  // uint64 public s_subscriptionId;
  address s_owner;

  mapping(address => bool) gameContracts;

  // uint256 wordsThreshold = 75;
  // bool requestPending;
  
  ISwapRouter public constant swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  uint24 public constant poolFee = 3000;
  uint256 public swapThreshold = 10000000000000000;
  address public constant LINKTOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  // constructor() VRFConsumerBaseV2(vrfCoordinator) {
  //   COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
  //   LINKTOKEN = LinkTokenInterface(link_token_contract);
  //   s_owner = msg.sender;
  //   //Create a new subscription when you deploy the contract.
  //   createNewSubscription();
  //   gameContracts[address(this)] = true;
  // }

  constructor() {
    s_owner = msg.sender;
    gameContracts[address(this)] = true;
    gameContracts[msg.sender] = true;
  }

  receive() external payable {}

  modifier onlyGames() {
    require(gameContracts[msg.sender], "only game contracts allowed");
    _;
  }

  // Assumes the subscription is funded sufficiently.
  // function requestRandomWords() public onlyGames {
  //   // Will revert if subscription is not set and funded.
  //   s_requestId = COORDINATOR.requestRandomWords(
  //     keyHash,
  //     s_subscriptionId,
  //     requestConfirmations,
  //     callbackGasLimit,
  //     numWords
  //   );
  // }

  // function fulfillRandomWords(
  //   uint256, /* requestId */
  //   uint256[] memory randomWords
  // ) internal override {
  //   s_randomWords = randomWords;
  //   requestPending = false;
  // }

  // function getRandomWords(uint256 number) external onlyGames returns (uint256[] memory ranWords) {
  //   ranWords = new uint256[](number);
  //   for (uint i = 0; i < number; i++) {
  //     uint256 curIndex = s_randomWords.length-1;
  //     ranWords[i] = s_randomWords[curIndex];
  //     s_randomWords.pop();
  //   }

  //   uint256 remainingWords = s_randomWords.length;
  //   if(remainingWords < wordsThreshold && !requestPending) {
  //     swapAndTopLink(); 
  //     requestRandomWords(); 
  //     requestPending = true;
  //   }
  // }

  // function getRemainingWords() external view onlyGames returns (uint256) {
  //   return s_randomWords.length;
  // }

  // // Create a new subscription when the contract is initially deployed.
  // function createNewSubscription() private onlyOwner {
  //   s_subscriptionId = COORDINATOR.createSubscription();
  //   // Add this contract as a consumer of its own subscription.
  //   COORDINATOR.addConsumer(s_subscriptionId, address(this));
  // }

  function swapAndTopLink(address _to) public onlyGames {

    uint256 amountIn = address(this).balance;

    // if(amountIn < swapThreshold) {
    //   return;
    // }

    // swapExactInputSingle(amountIn);

    IWETH(weth).deposit{value: amountIn}();

    swap(WETH, LINKTOKEN, amountIn, 0, address(this));
    uint256 amount = IERC20(LINKTOKEN).balanceOf(address(this));
    // LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
    IERC20(LINKTOKEN).transfer(_to, amount);
  }

  /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
  /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
  /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
  /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
  /// @return amountOut The amount of WETH9 received.
  function swapExactInputSingle(uint256 amountIn) internal returns (uint256 amountOut) {

      IWETH(weth).deposit{value: amountIn}();

      TransferHelper.safeApprove(weth, address(swapRouter), amountIn);

      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: address(weth),
              tokenOut: address(LINK),
              fee: uint24(poolFee),
              recipient: address(this),
              deadline: uint256(block.timestamp),
              amountIn: uint256(amountIn),
              amountOutMinimum: uint256(0),
              sqrtPriceLimitX96: uint160(0)
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }

  // Assumes this contract owns link.
  // 1000000000000000000 = 1 LINK
  // function topUpSubscription(uint256 amount) external onlyOwner {
  //   LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  // }

  // function addConsumer(address consumerAddress) external onlyOwner {
  //   // Add a consumer contract to the subscription.
  //   COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  // }

  // function removeConsumer(address consumerAddress) external onlyOwner {
  //   // Remove a consumer contract from the subscription.
  //   COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  // }

  // function cancelSubscription(address receivingWallet) external onlyOwner {
  //   // Cancel the subscription and send the remaining LINK to a wallet address.
  //   COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
  //   s_subscriptionId = 0;
  // }

  // Transfer this contract's funds to an address.
  // 1000000000000000000 = 1 LINK
  function withdraw(uint256 amount, address to) external onlyOwner {
    IERC20(LINKTOKEN).transfer(to, amount);
  }

  function setGameContract(address _contract, bool flag)external onlyOwner {
        gameContracts[_contract] = flag;
  }

  // function setCallbackGas(uint32 _gas) external onlyOwner {
  //   callbackGasLimit = _gas;
  // }

  // function setNumWords(uint32 _numWords) external onlyOwner {
  //   numWords = _numWords;
  // }

  // function setSwapThreshold(uint256 _threshold) external onlyOwner {
  //   swapThreshold = _threshold;
  // }

  // function setWordsThreshold(uint256 _threshold) external onlyOwner {
  //   wordsThreshold = _threshold;
  // }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function rescueETH() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(s_owner).transfer(amount);
  }

  function rescueToken(address _token) external onlyOwner {
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(s_owner, amount);
  }

  //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
   function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) internal {

    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

    //path is an array of addresses.
    //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
    //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
       //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}

