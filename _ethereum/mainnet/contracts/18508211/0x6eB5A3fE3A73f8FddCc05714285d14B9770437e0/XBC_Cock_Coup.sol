// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: bag.sol


pragma solidity 0.8.19;



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}

interface IV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
    function factory() external view returns (address);
	function positionManager() external view returns (address);
	function WETH9() external view returns (address);
}

interface IV3Factory {
	function createPool(address _tokenA, address _tokenB, uint24 _fee) external returns (address);
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

}

interface IV3Pool {
	function initialize(uint160 _sqrtPriceX96) external;
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint32 feeProtocol, bool unlocked);
    }

interface IV3NonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

     struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(uint256 tokenId)external view returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1);
    function mint(MintParams calldata params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);
    function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external payable returns (address pool);
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function burn(uint256 tokenId) external payable;

}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}





contract XBC_Cock_Coup is  Ownable, ReentrancyGuard{

    IV3NonfungiblePositionManager public immutable nonfungiblePositionManager;
    IV3Factory public immutable V3Factory;
    IFactoryV2 public immutable V2Factory;
    IV3SwapRouter public immutable V3swapRouter;  
    IRouter02 public immutable V2swapRouter;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  // Weth 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public constant Dead = 0x000000000000000000000000000000000000dEaD; 
    IERC20 public XBCToken; 
    
    uint256 private tokenId;
    uint256 private amount0;
    uint256 private amount1;
    bool public isCockSet;
    

    mapping(uint256 => Position) public positions;
    uint256[] public allTokenIds;

    address[] public claimableTokens;
    mapping(address => bool) public tokenIsActive;

    mapping(address => bool) private _authorizedAccounts;
    event AccountAuthorized(address indexed account);
    event AccountDeauthorized(address indexed account);

    modifier onlyAuthorized() {
        require(_authorizedAccounts[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    

    struct Position {
        address owner;
        uint256 tokenId;
        address token0;
        address token1;
        uint24 mintFee;
        int24 lowerTick;
        int24 upperTick;
        bool useV2;
    }

    constructor(
        address _nonfungiblePositionManager,
        address _V3Factory,
        address _V3swapRouter,
        address _V2Factory,
        address _V2swapRouter    

    ) {
        nonfungiblePositionManager = IV3NonfungiblePositionManager(_nonfungiblePositionManager);
        V3Factory = IV3Factory(_V3Factory);
        V3swapRouter = IV3SwapRouter(_V3swapRouter);
        V2Factory = IFactoryV2 (_V2Factory);
        V2swapRouter = IRouter02(_V2swapRouter);
        
        
        
       
    }

    receive() external payable {}

    function authorizeAccount(address account) external onlyOwner {
        require(account != address(0), "Zero address cannot be authorized");
        require(!_authorizedAccounts[account], "Account already authorized");

        _authorizedAccounts[account] = true;

        emit AccountAuthorized(account);
    }

//  function to deauthorize an account, callable only by the owner
    function deauthorizeAccount(address account) external onlyOwner {
        require(account != address(0), "Zero address cannot be deauthorized");
        require(_authorizedAccounts[account], "Account is not authorized");

        _authorizedAccounts[account] = false;

        emit AccountDeauthorized(account);
    }

//  function to check if an account is authorized
    function isAccountAuthorized(address account) external view returns (bool) {
        return _authorizedAccounts[account];
    }


     function getAllTokenIds() public view returns (uint256[] memory) {
        return allTokenIds;
    }

    // Wrap Specified Amount of Contract's ETH to WETH
    function wrapETH(uint256 amount) external onlyAuthorized {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        
        IWETH(WETH).deposit{value: amount}();
    }

    // Unwrap Specified Amount of Contract's WETH to ETH
    function unwrapWETH(uint256 amount) external onlyAuthorized {
        require(amount > 0, "Amount must be greater than 0");
        IERC20 weth = IERC20(WETH);
        require(weth.balanceOf(address(this)) >= amount, "Insufficient WETH balance");

        // Ensure that the contract is approved to spend its own WETH
        if (weth.allowance(address(this), address(WETH)) < amount) {
            weth.approve(address(WETH), amount);
        }

        IWETH(WETH).withdraw(amount);
    }

    function createAndInitializePoolIfNecessary(
        address _tokenA, 
        address _tokenB, 
        uint24 _fee, 
        uint160 _sqrtPriceX96
    ) external onlyAuthorized returns (address pool) {
        pool = V3Factory.getPool(_tokenA, _tokenB, _fee);
        
        // Create the pool if it doesn't exist
        if (pool == address(0)) {
            pool = V3Factory.createPool(_tokenA, _tokenB, _fee);
            require(pool != address(0), "Failed to create pool");
            IV3Pool(pool).initialize(_sqrtPriceX96);
        } else {
            // Check if the pool is already initialized
            (uint160 sqrtPriceX96,,,,,,) = IV3Pool(pool).slot0();
            if (sqrtPriceX96 == 0) {
                IV3Pool(pool).initialize(_sqrtPriceX96);
            }
        }

        require(pool != address(0), "Pool creation failed");
        return pool;
    }




    function setCock(address _Cock) external onlyOwner {
        require(!isCockSet, "Cock can only be set once");
        require(_Cock != address(0), "Cock address cannot be zero");

       XBCToken = IERC20(_Cock);
        isCockSet = true;
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
     ) public virtual  returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

    function getV3poolAddress (address token0, address token1, uint24 poolFee) public view returns (address) {
        address poolAddress = V3Factory.getPool(token0, token1, poolFee);
        return poolAddress;
    }


    function getAmountsOut(address inputToken, address outputToken, uint256 amountIn) public view returns (uint256) {
      address[] memory path = new address[](2);
      path[0] = inputToken;
      path[1] = outputToken;
      uint256[] memory amounts = V2swapRouter.getAmountsOut(amountIn, path);
      return amounts[1];
    }

    function getLiquidity(uint256 __tokenId) public view returns (uint128 liquidity) {
        (, , , , , , , liquidity, , , , ) = nonfungiblePositionManager.positions(__tokenId);
    }

 
    function getCurrentTick(address token0, address token1, uint24 poolFee) public view returns (int24) {
        address poolAddress = V3Factory.getPool(token0, token1, poolFee);

        IV3Pool pool = IV3Pool(poolAddress);

        (, int24 currentTick, , , , , ) = pool.slot0();

        return currentTick;
    }

    function _getCurrentTickByTokenId(uint256 tokenIDS) public view returns (int24) {
        Position memory position = positions[tokenIDS];
        address token0 = position.token0;
        address token1 = position.token1;
        uint24 poolFee = position.mintFee;

        address poolAddress = V3Factory.getPool(token0, token1, poolFee);
        IV3Pool pool = IV3Pool(poolAddress);
        (, int24 currentTick, , , , , ) = pool.slot0();

        return currentTick;
    }

    

     function SwapV2(address inputTokens, address outputToken, uint256 amountIn) external onlyAuthorized {
      _swapV2(inputTokens, outputToken, amountIn);
    }

    function SwapV3(address inputToken, address outputToken, uint24 swapFee, uint256 amountIn) external onlyAuthorized {
      _swapV3(inputToken, outputToken, swapFee, amountIn);
    }

    function _swapV2(address inputToken, address outputToken, uint256 amountIn) internal returns (uint256 amountOut) {
               require(address(inputToken) != address(XBCToken), "Selling COCK token is not allowed");


        if (amountIn == 0) {
        return 0;
        }
        IERC20(inputToken).approve(address(V2swapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint256 balanceBefore = IERC20(outputToken).balanceOf(address(this));

   
        V2swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 60
        );

    
        amountOut = IERC20(outputToken).balanceOf(address(this)) - balanceBefore;

        return amountOut;
    }


    function _swapV3(address inputToken, address outputToken, uint24 swapFee, uint256 amountIn) internal returns (uint256 amountOut) {

        require(address(inputToken) != address(XBCToken), "Selling COCK token is not allowed");

        if (amountIn == 0) {
        return 0;
        }
        
          
            IERC20(inputToken).approve(address(V3swapRouter), amountIn);

            IV3SwapRouter.ExactInputSingleParams memory swapParams = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: inputToken,
                tokenOut: outputToken,
                fee: swapFee,
                recipient: address(this),
                deadline: block.timestamp + 600,  // Deadline
                amountIn: amountIn,
                amountOutMinimum: 0,// amountsOut - amountsOut / slippage,  
                sqrtPriceLimitX96: 0  
            });

            
            amountOut = V3swapRouter.exactInputSingle(swapParams);
    
        return amountOut;
    }

    
    function CollectEggs(uint256 tokenID) external nonReentrant{
      _collect(tokenID);
    }

    

    function _decreaseLiquidity(uint256 _tokenId) internal returns (uint256 _amount0, uint256 _amount1){
        (, , , , , , , uint128 _liquidityt, , , , ) = nonfungiblePositionManager.positions(_tokenId);

        // Execute the decrease liquidity operation
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            IV3NonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: _liquidityt,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 600 // 10 minutes from the current block time
            })
        );
        
        return (amount0, amount1);
    }

    function _collect(uint256 _tokenId) internal returns (uint256 collectedAmount0, uint256 collectedAmount1) {
         (collectedAmount0, collectedAmount1) = nonfungiblePositionManager.collect(
            IV3NonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        return (collectedAmount0, collectedAmount1);
    }

    function increaseLiquidity(uint256 _tokenId, uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min) external onlyAuthorized {
         // Get the position details
        Position storage position = positions[_tokenId];

        // Approve the position manager to pull tokens
        IERC20(position.token0).approve(address(nonfungiblePositionManager), amount0Desired);
        IERC20(position.token1).approve(address(nonfungiblePositionManager), amount1Desired);

         // Set the parameters for the increase liquidity operation
        IV3NonfungiblePositionManager.IncreaseLiquidityParams memory params = IV3NonfungiblePositionManager.IncreaseLiquidityParams({
         tokenId: _tokenId,
         amount0Desired: amount0Desired,
          amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp + 600 // 10 minutes from the current block time
        });

            // Execute the increase liquidity operation
        (, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);

    
    }


    function mintPosition(address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint256 amount0Desired, uint256 amount1Desired, bool useV2) external onlyAuthorized {
        // Approve the position manager to pull tokens
        IERC20(token0).approve(address(nonfungiblePositionManager), amount0Desired);
        IERC20(token1).approve(address(nonfungiblePositionManager), amount1Desired);

        IV3NonfungiblePositionManager.MintParams memory params = IV3NonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
         tickLower: tickLower,
         tickUpper: tickUpper,
         amount0Desired: amount0Desired,
         amount1Desired: amount1Desired,
         amount0Min: 0,
         amount1Min: 0,
         recipient: address(this),
         deadline: block.timestamp + 600 // 10 minutes from the current block time
        });

        (tokenId,, amount0, amount1) = nonfungiblePositionManager.mint(params);

        positions[tokenId] = Position({
        owner: address(this),
        tokenId: tokenId,
        token0: token0,
        token1: token1,
        mintFee: fee,
        lowerTick: tickLower,
        upperTick: tickUpper,
        useV2: useV2
        });
    
        allTokenIds.push(tokenId);
    }

    function enterPositionSwap(address token0, address token1, uint24 mintFee, int24 lowerTick, int24 upperTick, uint256 swapAmountInEth, bool useV2, uint256 mintSlippage) external onlyAuthorized {
        
        address tokenIn = WETH;  
        address tokenOut = token0 == WETH ? token1 : token0; 
        

        if (useV2) {

            _swapV2(tokenIn, tokenOut, swapAmountInEth);

        } else {
           
           _swapV3(tokenIn, tokenOut, mintFee, swapAmountInEth);

        }

        uint256 maxAmount0 = IERC20(token0).balanceOf(address(this));
        uint256 maxAmount1 = IERC20(token1).balanceOf(address(this));
        TransferHelper.safeApprove(token0, address(nonfungiblePositionManager), maxAmount0);
        TransferHelper.safeApprove(token1, address(nonfungiblePositionManager), maxAmount1);


        IV3NonfungiblePositionManager.MintParams
            memory mintParams = IV3NonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: mintFee,
                tickLower: lowerTick,
                tickUpper: upperTick,
                amount0Desired: maxAmount0,
                amount1Desired: maxAmount1,
                amount0Min: maxAmount0 - maxAmount0 / mintSlippage,
                amount1Min: maxAmount1 - maxAmount1 / mintSlippage,
                recipient: address(this),
                deadline: block.timestamp + 600
            });

        (tokenId, , amount0, amount1) = nonfungiblePositionManager.mint(mintParams);

        positions[tokenId] = Position({
        owner: address(this),
        tokenId: tokenId,
        token0: token0,
        token1: token1,
        mintFee: mintFee,
        lowerTick: lowerTick,
        upperTick: upperTick,
        useV2: useV2
    });

        allTokenIds.push(tokenId);

    }

    function exitPosition(uint256 _tokenId) external onlyAuthorized{
       

         
            nonfungiblePositionManager.collect(
            IV3NonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
          



        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager
            .positions(_tokenId);

        nonfungiblePositionManager.decreaseLiquidity(
            IV3NonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp + 600
            })
        );

        nonfungiblePositionManager.collect(
            IV3NonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        nonfungiblePositionManager.burn(_tokenId);

        for (uint256 i = 0; i < allTokenIds.length; i++) {
        if (allTokenIds[i] == _tokenId) {
            allTokenIds[i] = allTokenIds[allTokenIds.length - 1];
            allTokenIds.pop();
            break;
        }
        }
    }


     // Function to add a token to the claimable list
    function addTokenToClaimable(address _token) external onlyAuthorized {
        require(!tokenIsActive[_token], "Token already claimable");
        claimableTokens.push(_token);
        tokenIsActive[_token] = true;
    }

    // Function to remove a token from the claimable list
    function removeTokenFromClaimable(address _token) external onlyAuthorized {
        require(tokenIsActive[_token], "Token not claimable");
        tokenIsActive[_token] = false;
        // This is a gas-intensive operation because it requires shifting array elements
        for (uint256 i = 0; i < claimableTokens.length; i++) {
            if (claimableTokens[i] == _token) {
                claimableTokens[i] = claimableTokens[claimableTokens.length - 1];
                claimableTokens.pop();
                break;
            }
        }
    }

    function claimFunds(uint256 amountOfXBC) external nonReentrant{
        require(amountOfXBC > 0, "Amount must be greater than 0");
        uint256 userBalance = XBCToken.balanceOf(msg.sender);
        require(userBalance >= amountOfXBC, "Insufficient XBC balance");

            XBCToken.transferFrom(msg.sender, Dead, amountOfXBC);


        // Calculate the user's share percentage based on the specified amount of COCK
        uint256 userSharePercentage = (amountOfXBC * 1e18) / getCirculatingSupply();

        for (uint256 i = 0; i < claimableTokens.length; i++) {
            address token = claimableTokens[i];
            if (!tokenIsActive[token]) continue; // Skip inactive tokens
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));
            if (tokenBalance == 0) continue; // Skip if no balance

           
            
            // Calculate claimable amount based on the user's share percentage
            uint256 claimableAmount = (tokenBalance * userSharePercentage) / 1e18;
            if (claimableAmount > 0) {
                IERC20(token).transfer(msg.sender, claimableAmount);
            }
        }
    }

    
    function getCirculatingSupply() public view returns (uint256) {
        uint256 totalSupply = XBCToken.totalSupply();
        uint256 burnedAmount = XBCToken.balanceOf(address(Dead)); // Assuming address(0) is the burn address
        uint256 contractBalance = XBCToken.balanceOf(address(this));
        return totalSupply - burnedAmount - contractBalance;
    }

    struct ClaimableToken {
    address tokenAddress;
    uint256 claimableAmount;
    }

    function getClaimableAmounts(address userAddress) public view returns (ClaimableToken[] memory) {
    uint256 userBalance = XBCToken.balanceOf(userAddress);
    uint256 userSharePercentage = (userBalance * 1e18) / getCirculatingSupply();

    ClaimableToken[] memory claimableAmounts = new ClaimableToken[](claimableTokens.length);

    for (uint256 i = 0; i < claimableTokens.length; i++) {
        address token = claimableTokens[i];
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        
        // Calculate claimable amount based on the user's share percentage
        uint256 claimableAmount = (tokenBalance * userSharePercentage) / 1e18;
        
        claimableAmounts[i] = ClaimableToken({
            tokenAddress: token,
            claimableAmount: claimableAmount
        });
    }

    return claimableAmounts;
   }

    function WithdrawERC20( address _contract, address _to) external onlyOwner {
        require(!isCockSet, "No withdraw once Cock is set");
        uint256 amount = IERC20(_contract).balanceOf(address(this));
        IERC20(_contract).transfer(_to, amount);
    }


}