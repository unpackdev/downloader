
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
contract WAVXStaking is Ownable {
    address public wavxAddress;
    mapping(address => bool) public acceptedTokens;
    // address private constant WETH9 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // goerli
    // address private constant USDTAddress = 0xa636A43458Df346Ad62548cD4A01CeDE0c1D236A; // goerli
    address private constant USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // mainnet
    address private constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //mainnet
    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    mapping(address => mapping(address => UserDeposit)) public userStakes;
    mapping(address => uint256) public totalStaked;

    uint256[] public rewardPerTier = [0, 25, 55, 65, 110];
    uint256[] public lockPerTier = [0, 30 days, 90 days, 180 days, 365 days];
    // uint256[] public lockPerTier = [0, 3 minutes, 5 minutes, 7 minutes, 10 minutes];

    struct UserDeposit {
        uint256 _amount;
        uint256 _wavxAmount;
        uint256 _epoch;
        uint _feeTier; //1 : 1 month 2.5%,  2 : 3 months 5.5%, 3 : 6 months 6.5%, 4 : 12months 11%
    }

    modifier onlyAcceptedToken(address _token) {
        require(acceptedTokens[_token] == true, "This token is not allowed to stake");
        _;
    }

    constructor(address _wavx) {
        wavxAddress = _wavx;
    }
    
    receive() external payable {}

    function addAcceptedTokens(address[] memory _addresses) public onlyOwner {
        for(uint i = 0; i < _addresses.length; i ++){
            if(acceptedTokens[_addresses[i]] == false){
                acceptedTokens[_addresses[i]] = true;
            }
        }
    }

    function addToAcceptedTokenList(address _tokenAddress) public onlyOwner {
        acceptedTokens[_tokenAddress] = true;
    }

    function removeFromAcceptedTokenList(address _tokenAddress) public onlyOwner {
        acceptedTokens[_tokenAddress] = false;
    }

    function stake(address _tokenAddress, uint256 _amount, uint256 _tier) onlyAcceptedToken(_tokenAddress) public payable {
        require(_tier >= 1 && _tier <= 4, "invalid stake tier level");
        uint256 acceptedAmount = _amount;
        if(_tokenAddress == address(0)){
            acceptedAmount = msg.value;
        } else {
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        }
        totalStaked[_tokenAddress] += acceptedAmount;
        address _inTokenAddress = _tokenAddress;
        if(_tokenAddress == address(0))
            _inTokenAddress = WETH9;
        uint256 toSendAmount = swapTokensToWAVX(_inTokenAddress, acceptedAmount);
        require(acceptedAmount > 0, "deposit amount zero");
        UserDeposit storage depositData = userStakes[msg.sender][_tokenAddress];
        require(depositData._amount == 0, "You already have depositted");
        depositData._amount = acceptedAmount;
        depositData._epoch = block.timestamp;
        depositData._wavxAmount = toSendAmount;
        depositData._feeTier = _tier;
    }

    function withdraw(address _tokenAddress) onlyAcceptedToken(_tokenAddress) external {
        UserDeposit storage depositData = userStakes[msg.sender][_tokenAddress];
        require(depositData._amount > 0 && depositData._feeTier > 0, "No stake data found");
        require(block.timestamp >= depositData._epoch + lockPerTier[depositData._feeTier], "Lock period yet");
        // if(_tokenAddress == address(0)) {
        //     payable(msg.sender).transfer(depositData._amount);
        // } else {
        //     IERC20(_tokenAddress).transfer(msg.sender, depositData._amount);
        // }
        uint256 rewardAmount = calculateRewardAmount(_tokenAddress, depositData._amount, depositData._feeTier);
        depositData._amount = 0;
        depositData._feeTier = 0;
        IERC20(wavxAddress).transfer(msg.sender, rewardAmount + depositData._wavxAmount);
        depositData._wavxAmount = 0;
    }

    function changeLockPeriod(uint256 _id, uint256 _time) public onlyOwner {
        lockPerTier[_id] = _time;
    }

    function changeRewardTier(uint256 _id, uint256 _percentage) public onlyOwner {
        rewardPerTier[_id] = _percentage;
    }

    function calculateEarning(address _tokenAddress) public view returns (uint256) {
        if(acceptedTokens[_tokenAddress] == false){
            return 0;
        }
        return calculateRewardAmount(_tokenAddress, userStakes[msg.sender][_tokenAddress]._amount, userStakes[msg.sender][_tokenAddress]._feeTier);
    }

    function calculateRewardAmount(address _stakeTokenAddress, uint256 _amount, uint256 _tier) public view returns (uint256) {
        if(acceptedTokens[_stakeTokenAddress] == false){
            return 0;
        }
        return estimatedOutOfWAVX(_stakeTokenAddress, _amount * rewardPerTier[_tier]/1000);
    }

    function emergencyRewardWithdraw(address _tokenAddress) external onlyOwner {
        if(_tokenAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this)));
        }
    }

    function swapTokensToWAVX(address _tokenAddress, uint256 amountIn) internal returns(uint256 amountOut) {
        if(_tokenAddress == wavxAddress)
            return amountIn;

        
        // For this example, we will set the pool fee to 0.3%.
        uint24 poolFee = 3000;

        // Approve the router to spend _tokenAddress.
        TransferHelper.safeApprove(_tokenAddress, address(swapRouter), amountIn);

        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        if(_tokenAddress != USDTAddress) {
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(_tokenAddress, poolFee, WETH9, poolFee, USDTAddress, poolFee, wavxAddress),
                    recipient: address(this),
                    deadline: block.timestamp + 600,
                    amountIn: amountIn,
                    amountOutMinimum: 0
                });
            // Executes the swap.
            if(_tokenAddress == WETH9){
                params = ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(WETH9, poolFee, USDTAddress, poolFee, wavxAddress),
                    recipient: address(this),
                    deadline: block.timestamp + 600,
                    amountIn: amountIn,
                    amountOutMinimum: 0
                });
                amountOut = swapRouter.exactInput{value : amountIn}(params);
            }
            else{
                amountOut = swapRouter.exactInput(params);
            }
        }
        else {
            ISwapRouter.ExactInputSingleParams  memory params = 
                ISwapRouter.ExactInputSingleParams ({
                    tokenIn: USDTAddress,
                    tokenOut: wavxAddress,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp + 600,
                    amountIn: amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
            
            // The call to `exactInputSingle` executes the swap.
            amountOut = swapRouter.exactInputSingle(params);
        }
    }

    function calcOutInToken(address tokenIn, address tokenOut, uint256 _amount) internal view returns (uint256) {
        address pool = factory.getPool(tokenIn, tokenOut, 3000);
        (int24 tick, uint128 harmonicMeanLiquidity ) = OracleLibrary.consult(pool, 10);
        uint256 amountOut = OracleLibrary.getQuoteAtTick(tick, uint128(_amount), tokenIn, tokenOut);
        return amountOut;
    }

    function estimatedOutOfWAVX(address _tokenAddress, uint256 _amount) public view returns (uint256) {
        if(_tokenAddress == wavxAddress) {
            return _amount;
        }
        else if(_tokenAddress == USDTAddress) {
            return calcOutInToken(_tokenAddress, wavxAddress, _amount);
        }
        else if(_tokenAddress == WETH9 || _tokenAddress == address(0)) {
            return calcOutInToken(USDTAddress, wavxAddress, calcOutInToken(WETH9, USDTAddress, _amount));
        }
        return calcOutInToken(USDTAddress, wavxAddress, calcOutInToken(WETH9, USDTAddress, calcOutInToken(_tokenAddress, WETH9, _amount)));
    }

    function isClaimable(address _tokenAddress) public view returns (bool) {
        UserDeposit memory _deposit = userStakes[msg.sender][_tokenAddress];
        return _deposit._amount > 0 && lockPerTier[_deposit._feeTier] + _deposit._epoch <= block.timestamp;
    }

    function isDepositted(address _tokenAddress) public view returns (bool) {
        UserDeposit memory _deposit = userStakes[msg.sender][_tokenAddress];
        return _deposit._amount > 0;
    }

    function remainingTime(address _tokenAddress) public view returns (uint256) {
        UserDeposit memory _deposit = userStakes[msg.sender][_tokenAddress];
        if(_deposit._amount == 0 || lockPerTier[_deposit._feeTier] + _deposit._epoch <= block.timestamp)
            return 0;
        return lockPerTier[_deposit._feeTier] + _deposit._epoch - block.timestamp;
    }
}