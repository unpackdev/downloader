// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./TransferHelper.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./UserTokenLimit.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./ISwitchTreasury.sol";
import "./ISwitchSigner.sol";
import "./ISwitchTicketFactory.sol";
import "./IRewardToken.sol";

contract SwitchAcross is UserTokenLimit, Pausable, ReentrancyGuard, Initializable{
    using SafeMath for uint;
    address public weth;
    address public treasury;
    address public signer;
    address public ticketFactory;
    uint public constant DENOMINATOR = 10000;
    address public feeWallet;
    address public gasWallet;
    
    uint public totalGas;
    uint public totalFee;
    //(token => total fee)
    mapping (address => uint) public totalSlideOfToken;
    

    uint public collectedAccuGas;
    uint public collectedAccuFee;
    //(token => total fee)
    mapping (address => uint) public collectedAccuSlideOfToken;

    //(chainIdOut, tokenOut, tokenIn)
    mapping (uint => mapping (address => address)) public tokenMap;

    struct TargetToken {
        address tokenOut;
        uint decimals;
        uint fee;
        uint slideMin;
        uint slideMax;
        uint slidePre;
        uint limit;
    }

    //(source token, chainIdOut)
    mapping (address => mapping (uint => TargetToken)) public targetTokens;

    struct SourceToken {
        uint decimals;
        bool enabledIn;
        bool enabledOut;
        uint rewardRate; // its denominator is 1e18
        bool added;
    }
    //key: (token address)
    mapping (address => SourceToken) public sourceTokens;

    address[] public tokens;
    uint public inSn;
    uint public outSn;

    //(chainId => fee)
    mapping (uint => uint) public chainFees;
    uint public baseFee;
    uint public mode;     // supported mode(0: none, 1:self, 2:other)

    // from chainId=>from inSn=> outSn
    mapping (uint => mapping (uint => uint)) public outOrders;
    address public rewardToken;
    mapping (address => uint) public rewards;

    event ChianFeeChanged(uint indexed chainId, uint indexed fee);
    event TokenMapChanged(address indexed tokenIn, address indexed tokenOut, uint indexed chainIdOut);
    event TransferIned(
        uint indexed sn,
        address user,
        uint chainId,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut,
        uint mode,
        uint slide,
        uint fee
    );
    event TransferOuted(
        uint indexed sn,
        address user,
        uint chainId,
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOut,
        uint mode,
        uint slide,
        uint inSn
    );

    event ConfigureChanged(address indexed _user, address _treasury, address _signer, address _ticketFactory, uint _mode);
    event FeeWalletChanged(address indexed _user, address _old, address _new);
    event GasWalletChanged(address indexed _user, address _old, address _new);
    event BaseFeeChanged(address indexed _user, uint _old, uint _new);
    event TokenEnableChanged(address indexed _tokenIn, bool _enabledIn, bool _enabledOut);
    event RewardRateChanged(address indexed _tokenIn, uint _old, uint _new);

    function initialize(address _weth, address _rewardToken) external initializer {
        require(_weth != address(0), 'SwitchAcross: ZERO_ADDRESS');
        owner = msg.sender;
        feeWallet = msg.sender;
        gasWallet = msg.sender;
        weth = _weth;
        rewardToken = _rewardToken;
        inSn = 1;
        outSn = 1;
    }


    modifier onlyFeeWallet() {
        require(msg.sender == owner || msg.sender == feeWallet, 'SwitchAcross: FEE_FORBIDDEN');
        _;
    }

    modifier onlyGasWallet() {
        require(msg.sender == owner || msg.sender == gasWallet, 'SwitchAcross: GAS_FORBIDDEN');
        _;
    }
    
    receive() external payable {
        assert(msg.sender == weth);
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        _unpause();
    }

    function configure(address _treasury, address _signer, address _ticketFactory, uint _mode, uint _baseFee) external onlyDev {
        require(_treasury != address(0) && _signer != address(0) && _ticketFactory != address(0), 'SwitchAcross: ZERO_ADDRESS');
        emit ConfigureChanged(msg.sender, _treasury, _signer, _ticketFactory, _mode);
        emit BaseFeeChanged(msg.sender, baseFee, _baseFee);
        treasury = _treasury;
        signer = _signer;
        ticketFactory = _ticketFactory;
        mode = _mode;
        baseFee = _baseFee;
    }
    
    function countToken() public view returns (uint) {
        return tokens.length;
    }

    function changeFeeWallet(address _user) external onlyFeeWallet {
        require(feeWallet != _user, 'SwitchAcross: NO_CHANGE');
        emit FeeWalletChanged(msg.sender, feeWallet, _user);
        feeWallet = _user;
    }

    function changeGasWallet(address _user) external onlyGasWallet {
        require(gasWallet != _user, 'SwitchAcross: NO_CHANGE');
        emit GasWalletChanged(msg.sender, gasWallet, _user);
        gasWallet = _user;
    }

    function checkMode(uint _mode) public view returns (bool) {
        return (mode & _mode) == _mode;
    }

    function setBaseFee(uint _baseFee) external onlyDev {
        emit BaseFeeChanged(msg.sender, baseFee, _baseFee);
        baseFee = _baseFee;
    }

    function setTokenMap(address _tokenIn, address _tokenOut, uint _chainIdOut, uint _tokenOutDecimals, uint _tokenOutLimit, uint _fee, uint _slideMin, uint _slideMax, uint _slidePre, uint _rewardRate) public onlyDev {
        require(_slideMax >= _slideMin, "SwitchAcross: INVALID_PARAM");
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        tokenMap[_chainIdOut][_tokenOut] = _tokenIn;

        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        if(sourceToken.added == false) {
            tokens.push(_tokenIn);
            sourceToken.added = true;
            sourceToken.enabledIn = true;
            sourceToken.enabledOut = true;
            sourceToken.decimals = IERC20(_tokenIn).decimals();
        }
        
        if(sourceToken.rewardRate != _rewardRate) sourceToken.rewardRate = _rewardRate;

        TargetToken storage targetToken = targetTokens[_tokenIn][_chainIdOut];
        if(targetToken.tokenOut == address(0) && targetToken.decimals != _tokenOutDecimals) targetToken.decimals = _tokenOutDecimals;
        if(targetToken.tokenOut != _tokenOut) targetToken.tokenOut = _tokenOut;
        if(targetToken.fee != _fee) targetToken.fee = _fee;
        if(targetToken.limit != _tokenOutLimit) targetToken.limit = _tokenOutLimit;
        if(targetToken.slideMin != _slideMin) targetToken.slideMin = _slideMin;
        if(targetToken.slideMax != _slideMax) targetToken.slideMax = _slideMax;
        if(targetToken.slidePre != _slidePre) targetToken.slidePre = _slidePre;

        emit TokenMapChanged(_tokenIn, _tokenOut, _chainIdOut);
    }

    function setTokenMaps(address[] memory _tokenIn, address[] memory _tokenOut, uint[] memory _chainIdOut, uint[] memory _tokenOutDecimals, uint[] memory _tokenOutLimit, uint[] memory _fee, uint[] memory _slideMin, uint[] memory _slideMax, uint[] memory _slidePre, uint[] memory _rewardRate) external onlyDev {
        require(
            _tokenIn.length == _tokenOut.length 
            && _tokenOut.length == _chainIdOut.length 
            && _chainIdOut.length == _tokenOutDecimals.length 
            && _tokenOutDecimals.length == _tokenOutLimit.length 
            && _tokenOutLimit.length == _fee.length 
            && _fee.length == _slideMin.length 
            && _slideMin.length == _slideMax.length 
            && _slideMax.length == _slidePre.length 
            && _slidePre.length == _rewardRate.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setTokenMap(_tokenIn[i], _tokenOut[i], _chainIdOut[i], _tokenOutDecimals[i], _tokenOutLimit[i], _fee[i], _slideMin[i], _slideMax[i], _slidePre[i], _rewardRate[i]);
        }
    }

    function setTokenEnable(address _tokenIn, bool _enabledIn, bool _enabledOut) public onlyDev {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        if(sourceToken.enabledIn != _enabledIn) sourceToken.enabledIn = _enabledIn;
        if(sourceToken.enabledOut != _enabledOut) sourceToken.enabledOut = _enabledOut;
        emit TokenEnableChanged(_tokenIn, _enabledIn, _enabledOut);
    }

    function setTokenEnables(address[] memory _tokenIn, bool[] memory _enabledIn, bool[] memory _enabledOut) external onlyDev {
        require(
            _tokenIn.length == _enabledIn.length 
            && _enabledIn.length == _enabledOut.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setTokenEnable(_tokenIn[i], _enabledIn[i], _enabledOut[i]);
        }
    }

    function setRewardRate(address _tokenIn, uint _rewardRate) public onlyDev {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokenIn];
        emit RewardRateChanged(_tokenIn, sourceToken.rewardRate, _rewardRate);
        sourceToken.rewardRate = _rewardRate;
    }

    function setRewardRates(address[] memory _tokenIn, uint[] memory _rewardRate) external onlyDev {
        require(
            _tokenIn.length == _rewardRate.length 
            , "SwitchAcross: INVALID_PARAM"
        );
        for (uint i; i < _tokenIn.length; i++) {
            setRewardRate(_tokenIn[i], _rewardRate[i]);
        }
    }

    function setChainFee(uint _chainId, uint _fee) public onlyDev {
        chainFees[_chainId] = _fee;
        emit ChianFeeChanged(_chainId, _fee);
    }

    function setChainFees(uint[] memory _chainId, uint[] memory _fee) external onlyDev {
        require(_chainId.length == _fee.length, "SwitchAcross: INVALID_PARAM");
        for (uint i; i < _chainId.length; i++) {
            setChainFee(_chainId[i], _fee[i]);
        }
    }

    function collectGasFee() external onlyGasWallet nonReentrant returns (uint amount) {
        require(totalGas > 0, "SwitchAcross: NO_GAS_FEE");
        amount = totalGas;
        collectedAccuGas += amount;
        ISwitchTreasury(treasury).withdraw(true, gasWallet, weth, amount);
        totalGas = 0;
    }

    function collectFee() external onlyFeeWallet nonReentrant returns (uint amount) {
        require(totalFee > 0, "SwitchAcross: NO_FEE");
        amount = totalFee;
        collectedAccuFee += amount;
        ISwitchTreasury(treasury).withdraw(true, feeWallet, weth, amount);
        totalFee = 0;
    }

    function collectSlide(address _token) external onlyFeeWallet nonReentrant returns (uint amount) {
        amount = totalSlideOfToken[_token];
        require(amount > 0, "SwitchAcross: NO_SLIDE");
        collectedAccuSlideOfToken[_token] += amount;
        ISwitchTreasury(treasury).withdraw(false, feeWallet, _token, amount);
        totalSlideOfToken[_token] = 0;
    }

    function getSlide(address _tokenIn, uint _toChainId, uint amountIn) public view returns (uint) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        uint amount = amountIn.mul(targetToken.slidePre).div(DENOMINATOR);
        if(amount > targetToken.slideMax) {
            amount = targetToken.slideMax;
        }
        if(amount < targetToken.slideMin) {
            amount = targetToken.slideMin;
        }
        return amount;
    }

    function getAmountIn(address _tokenIn, uint _toChainId, uint _amountOut) public view returns (uint amount, uint slide) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        SourceToken memory sourceToken = sourceTokens[_tokenIn];
        amount = _amountOut;
        if(sourceToken.decimals < targetToken.decimals) {
            amount = amount / 10** (targetToken.decimals - sourceToken.decimals);
        } else if(sourceToken.decimals > targetToken.decimals) {
            amount = amount * 10** (sourceToken.decimals - targetToken.decimals);
        }
        slide = getSlide(_tokenIn, _toChainId, amount);
        amount = amount.add(slide);
    }

    function getAmountOut(address _tokenIn, uint _toChainId, uint _amountIn) public view returns (uint amount, uint slide) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        SourceToken memory sourceToken = sourceTokens[_tokenIn];
        slide = getSlide(_tokenIn, _toChainId, _amountIn);
        if(_amountIn <= slide) {
            slide = _amountIn;
        }

        amount = _amountIn.sub(slide);
        if(sourceToken.decimals < targetToken.decimals) {
            amount = amount * 10** (targetToken.decimals - sourceToken.decimals);
            slide = slide * 10** (targetToken.decimals - sourceToken.decimals);
        } else if(sourceToken.decimals > targetToken.decimals) {
            amount = amount / 10** (sourceToken.decimals - targetToken.decimals);
            slide = slide / 10** (sourceToken.decimals - targetToken.decimals);
        }
        return (amount, slide);
    }

    function getOutInfo(address _tokenIn, uint _toChainId, uint _amountIn, uint _mode) public view returns (uint amountIn, address tokenOut, uint amountOut, uint slide, uint fee, uint inLimit, uint outLimit) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        TargetToken memory targetToken = targetTokens[_tokenIn][_toChainId];
        tokenOut = targetToken.tokenOut;
        fee = baseFee.add(targetToken.fee);
        // mode != 1
        if(_mode != 1) {
            fee = fee.add(chainFees[_toChainId]);
        }
        amountIn = _amountIn;
        (uint _amountOut, uint _slide) = getAmountOut(_tokenIn, _toChainId, _amountIn);
        amountOut = _amountOut;
        slide = _slide;
        inLimit = getUserLimit(msg.sender, _tokenIn, _amountIn);
        outLimit = targetToken.limit;
    }

    function getInInfo(address _tokenIn, uint _toChainId, uint _amountOut, uint _mode) public view returns (uint amountIn, address tokenOut, uint amountOut, uint slide, uint fee, uint inLimit, uint outLimit) {
        if(_tokenIn == address(0)) {
            _tokenIn = weth;
        }
        (amountIn,) = getAmountIn(_tokenIn, _toChainId, _amountOut);
        return getOutInfo(_tokenIn, _toChainId, amountIn, _mode);
    }

    function isTicket(address _token) public view returns (bool) {
        return ISwitchTicketFactory(ticketFactory).isTicket(_token);
    }
    
    /**
        transferIn 
        address _to
        address[] _tokens, 0:_tokenIn, 1:_tokenOut
        uint[] _values, 0:_amountIn, 1:_amountOut, 2:_toChainId, 3:_mode
     */
    function transferIn(address _to, address[] memory _tokens, uint[] memory _values) external payable whenNotPaused nonReentrant  {
        require(_values[0] > 0 && _values[1] > 0, "SwitchAcross: ZERO_AMOUNT");
        require(checkMode(_values[3]), "SwitchAcross: INVALID_MODE");
        require(ISwitchSigner(signer).checkUser(_to), 'SwitchAcross: DENNY');
        bool isETH;
        if(_tokens[0] == address(0)) {
            isETH = true;
            _tokens[0] = weth;
        }
        SourceToken storage sourceToken = sourceTokens[_tokens[0]];
        require(sourceToken.enabledIn, "SwitchAcross: TOKEN_DISABLED");
        TargetToken memory targetToken = targetTokens[_tokens[0]][_values[2]];
        require(_tokens[1] == targetToken.tokenOut, "SwitchAcross: INVALID_TOKENOUT");
        require(getUserLimit(msg.sender, _tokens[0],  _values[0]) >= _values[0], "SwitchAcross: USER_LIMIT_OVERFLOW");
        (uint amountOut, uint slide) = getAmountOut(_tokens[0], _values[2], _values[0]);
        require(_values[1] == amountOut, "SwitchAcross: AMOUNTOUT_INCORRECT");
        require(targetToken.limit >= _values[1], "SwitchAcross: AMOUNTOUT_OVERFLOW");

        uint fee = baseFee.add(targetToken.fee);
        totalFee = totalFee.add(fee);
        uint gas = fee;
        // mode != 1
        if(_values[3] != 1) {
            gas = gas.add(chainFees[_values[2]]);
            totalGas = totalGas.add(chainFees[_values[2]]);
        }
        { // avoid Stack too deep, try removing local variables.
        uint depositAmount;
        if(isETH) {
            require(msg.value >= gas.add(_values[0]), "SwitchAcross: INSUFFICIENT_GAS_TOKEN_VALUE");
            _values[0] = msg.value.sub(gas);
            depositAmount = ISwitchTreasury(treasury).deposit{value: _values[0]}(msg.sender, address(0), _values[0]);
        } else {
            require(msg.value >= gas, "SwitchAcross: INSUFFICIENT_GAS_VALUE");
            if(isTicket(_tokens[0])) {
                depositAmount = ISwitchTreasury(treasury).burn(_tokens[0], msg.sender, _values[0]);
            } else {
                depositAmount = ISwitchTreasury(treasury).deposit(msg.sender, _tokens[0], _values[0]);
            }
        }
        require(depositAmount == _values[0], "SwitchAcross: TREASURY_DEPOSIT_FAIL");
        }

        _updateUserTokenLimit(_tokens[0],  _values[0]);

        emit TransferIned(inSn, _to, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], slide, fee);
        inSn = inSn.add(1);
    }

    function getDataHash(address _from, address[] memory _tokens, uint[] memory _values) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], _values[4], _values[5], msg.sender));
    }

    /**
        transferOut 
        address _from
        address[] _tokens, 0:_tokenIn, 1:_tokenOut
        uint[] _values, 0:_amountIn, 1:_amountOut, 2:from chainId, 3:_mode, 4:slide, 5:from inSn
        bytes calldata _signature
     */
    function transferOut(address _from, address[] memory _tokens, uint[] memory _values, bytes[] memory _signatures) external whenNotPaused nonReentrant  {
        SourceToken storage sourceToken = sourceTokens[_tokens[1]];
        require(sourceToken.enabledOut, "SwitchAcross: TOKEN_DISABLED");
        require(outOrders[_values[2]][_values[5]] == 0, "SwitchAcross: ALREADY_EXECUTED");
   
        require(_values[1] > 0, "SwitchAcross: NOTHING_TO_WITHDRAW");
        require(queryWithdraw(_tokens[1], _values[1]) >= _values[1], 'SwitchAcross: INSUFFICIENT_BALANCE');
        
        bytes32 message = getDataHash(_from, _tokens, _values);
        require(signer != address(0), 'SwitchAcross: NO_SIGNER');
        require(ISwitchSigner(signer).mverify(_values[3], _from, msg.sender, message, _signatures), "SwitchAcross: INVALID_SIGNATURE");

        if(isTicket(_tokens[1])) {
            ISwitchTreasury(treasury).mint(_tokens[1], _from, _values[1]);
            if(_values[4] > 0) {
                address _token = ISwitchTicketFactory(ticketFactory).getTokenMap(_tokens[1]);
                require(_token != address(0), 'SwitchAcross: INVALID_TICKET');
                totalSlideOfToken[_token] = totalSlideOfToken[_token].add(_values[4]);
            }
        } else {
            bool isETH = false;
            if(_tokens[1] == weth) {
                isETH = true;
            }
            ISwitchTreasury(treasury).withdraw(isETH, _from, _tokens[1], _values[1]);
            totalSlideOfToken[_tokens[1]] = totalSlideOfToken[_tokens[1]].add(_values[4]);
        }
     
        outOrders[_values[2]][_values[5]] = outSn;

        rewards[_from] = rewards[_from].add(computeReward(_tokens[1], _values[1]));
 
        emit TransferOuted(outSn, _from, _values[2], _tokens[0], _tokens[1], _values[0], _values[1], _values[3], _values[4], _values[5]);
        outSn = outSn.add(1);
    }

    function computeReward(address token, uint amount) public view returns (uint) {
        SourceToken memory sourceToken = sourceTokens[token];
        if(sourceToken.decimals < 18) {
            amount = amount.mul(10**(18-sourceToken.decimals));
        } else {
            amount = amount.div(10**(sourceToken.decimals-18));
        }
        uint reward = amount.mul(sourceToken.rewardRate).div(1e18);
        if(reward > IRewardToken(rewardToken).take()) {
            reward = 0;
        }
        return reward;
    }

    function queryWithdraw(address _token, uint _value) public view returns (uint) {
        if(!isTicket(_token)) {
            uint amount = ISwitchTreasury(treasury).queryWithdraw(address(this), _token);
            if(amount < _value) {
                _value = amount;
            }
        }
        return _value;
    }

    function claimReward() external nonReentrant returns (uint) {
        uint reward = rewards[msg.sender];
        require(reward > 0, 'SwitchAcross: ZERO');
        require(reward <= IRewardToken(rewardToken).take(), 'SwitchAcross: STOP');
        rewards[msg.sender] = 0;
        IRewardToken(rewardToken).mint(msg.sender, reward);
        return reward;
    }
}