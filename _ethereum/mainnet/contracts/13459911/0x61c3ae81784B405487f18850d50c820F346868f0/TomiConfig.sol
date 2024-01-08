// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./ConfigNames.sol";
import "./TransferHelper.sol";
import "./TokenRegistry.sol";
import "./Ownable.sol";

contract TomiConfig is TokenRegistry, Ownable {
    uint public version = 1;
    event ConfigValueChanged(bytes32 _name, uint _old, uint _value);

    struct Config {
        uint minValue;
        uint maxValue;
        uint maxSpan;
        uint value;
        uint enable;  // 0:disable, 1: enable
    }

    mapping(bytes32 => Config) public configs;
    address public tgas;                                // TGAS contract address
    address public platform;      
    address public dev;                         
    uint public constant PERCENT_DENOMINATOR = 10000;
    uint public constant TGAS_DECIMAL = 10 ** 18;
    address[] public defaultListTokens;

    modifier onlyPlatform() {
        require(msg.sender == platform, 'TomiConfig: ONLY_PLATFORM');
        _;
    }

    constructor()  public {
        _initConfig(ConfigNames.PRODUCE_TGAS_RATE, 1 * TGAS_DECIMAL, 120 * TGAS_DECIMAL, 10 * TGAS_DECIMAL, 40 * TGAS_DECIMAL);
        _initConfig(ConfigNames.SWAP_FEE_PERCENT, 5,30,5,30);
        _initConfig(ConfigNames.LIST_TGAS_AMOUNT, 0, 100000 * TGAS_DECIMAL, 1000 * TGAS_DECIMAL, 0);
        _initConfig(ConfigNames.UNSTAKE_DURATION, 17280, 17280*7, 17280, 17280);
        // _initConfig(ConfigNames.EXECUTION_DURATION, 0, 18000, 1200, 300);
        _initConfig(ConfigNames.REMOVE_LIQUIDITY_DURATION, 0, 17280*7, 17280, 0);
        _initConfig(ConfigNames.TOKEN_TO_TGAS_PAIR_MIN_PERCENT, 20, 500, 10, 100);
        _initConfig(ConfigNames.LIST_TOKEN_FAILURE_BURN_PRECENT, 100, 5000, 500, 1000);
        _initConfig(ConfigNames.LIST_TOKEN_SUCCESS_BURN_PRECENT, 1000, 5000, 500, 5000);
        _initConfig(ConfigNames.PROPOSAL_TGAS_AMOUNT, 100 * TGAS_DECIMAL, 10000 * TGAS_DECIMAL, 100 * TGAS_DECIMAL, 100 * TGAS_DECIMAL);
        // _initConfig(ConfigNames.VOTE_DURATION, 17280, 17280*7, 17280, 17280);
        _initConfig(ConfigNames.VOTE_REWARD_PERCENT, 0, 1000, 100, 500);
        _initConfig(ConfigNames.TOKEN_PENGDING_SWITCH, 0, 1, 1, 1);  // 0:off, 1:on
        _initConfig(ConfigNames.TOKEN_PENGDING_TIME, 0, 100*17280, 10*17280, 100*17280);
        _initConfig(ConfigNames.LIST_TOKEN_SWITCH, 0, 1, 1, 0);  // 0:off, 1:on
        _initConfig(ConfigNames.DEV_PRECENT, 1000, 1000, 1000, 1000);

        _initConfig(ConfigNames.DEV_PRECENT, 1000, 1000, 1000, 1000);

        _initConfig(ConfigNames.FEE_FUNDME_REWARD_PERCENT, 833, 833, 833, 833);  
        _initConfig(ConfigNames.FEE_LOTTERY_REWARD_PERCENT, 833, 833, 833, 833);
        _initConfig(ConfigNames.FEE_STAKING_REWARD_PERCENT, 833, 833, 833, 833);
    }

    function _initConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) internal {
        Config storage config = configs[_name];
        config.minValue = _minValue;
        config.maxValue = _maxValue;
        config.maxSpan = _maxSpan;
        config.value = _value;
        config.enable = 1;
    }

    function initialize(
        address _tgas,
        address _governor,
        address _platform,
        address _dev,
        address[] memory _listTokens) public onlyOwner {
        require(_tgas != address(0), "TomiConfig: ZERO ADDRESS");
        tgas = _tgas;
        platform = _platform;
        dev = _dev;
        for(uint i = 0 ; i < _listTokens.length; i++){
            _updateToken(_listTokens[i], OPENED);
            defaultListTokens.push(_listTokens[i]);
        }
        initGovernorAddress(_governor);
    }

    function modifyGovernor(address _new) public onlyOwner {
        _changeGovernor(_new);
    }

    function modifyDev(address _new) public {
        require(msg.sender == dev, 'TomiConfig: FORBIDDEN');
        dev = _new;
    }

    function changeConfig(bytes32 _name, uint _minValue, uint _maxValue, uint _maxSpan, uint _value) external onlyOwner returns (bool) {
        _initConfig(_name, _minValue, _maxValue, _maxSpan, _value);
        return true;
    }

    function getConfig(bytes32 _name) external view returns (uint minValue, uint maxValue, uint maxSpan, uint value, uint enable) {
        Config memory config = configs[_name];
        minValue = config.minValue;
        maxValue = config.maxValue;
        maxSpan = config.maxSpan;
        value = config.value;
        enable = config.enable;
    }
    
    function getConfigValue(bytes32 _name) public view returns (uint) {
        return configs[_name].value;
    }

    function changeConfigValue(bytes32 _name, uint _value) external onlyGovernor returns (bool) {
        Config storage config = configs[_name];
        require(config.enable == 1, "TomiConfig: DISABLE");
        require(_value <= config.maxValue && _value >= config.minValue, "TomiConfig: OVERFLOW");
        uint old = config.value;
        uint span = _value >= old ? (_value - old) : (old - _value);
        require(span <= config.maxSpan, "TomiConfig: EXCEED MAX ADJUST SPAN");
        config.value = _value;
        emit ConfigValueChanged(_name, old, _value);
        return true;
    }

    function checkToken(address _token) public view returns(bool) {
        if (getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            return true;
        }
        if (tokenStatus[_token] == OPENED) {
            return true;
        } else if (tokenStatus[_token] == PENDING ) {
            if (getConfigValue(ConfigNames.TOKEN_PENGDING_SWITCH) == 1 && block.number > publishTime[_token] + getConfigValue(ConfigNames.TOKEN_PENGDING_TIME)) {
                return false;
            } else {
                return true;
            }
        }
        return false;
    }

    function checkPair(address tokenA, address tokenB) external view returns (bool) {
        if (checkToken(tokenA) && checkToken(tokenB)) {
            return true;
        }
        return false;
    }

    function getDefaultListTokens() external view returns (address[] memory) {
        address[] memory res = new address[](defaultListTokens.length);
        for (uint i; i < defaultListTokens.length; i++) {
            res[i] = defaultListTokens[i];
        }
        return res;
    }

    function addToken(address _token) external onlyPlatform returns (bool) {
        if(getConfigValue(ConfigNames.LIST_TOKEN_SWITCH) == 0) {
            if(tokenStatus[_token] != OPENED) {
                _updateToken(_token, OPENED);
            }
        }
        return true;
    }

}