// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IWETH.sol";
import "./IERC20.sol";
import "./ISwitchTreasurySubscriber.sol";
import "./ISwitchTreasury.sol";
import "./ISwitchTicket.sol";
import "./Configable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";


contract SwitchTreasury is Configable, Pausable, ReentrancyGuard, Initializable {
    using SafeMath for uint;
    string public constant name = "SwitchTreasury";
    address public weth;
    address public targetTreasury;

    // _token=>_sender=>_value
    mapping(address => mapping(address => int)) public senderBalanceOf;

    address[] public subscribes;

    event Deposited(address indexed _token, address indexed _sender, address indexed _from, uint _value);
    event Withdrawed(address indexed _token, address indexed _from, address indexed _to, uint _value);
    event AllocPointChanged(address indexed _user, uint indexed _old, uint indexed _new);
    event TargetTreasuryChanged(address indexed _user, address indexed _old, address indexed _new);

    receive() external payable {
    }

    mapping(address => bool) public applyWhiteList;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public tokenExistence;
    address[] public tokens;

    uint public totalAllocPoint;
    mapping(address => uint) public allocPoint;

    struct TokenLimit {
        bool enabled;
        uint blocks;
        uint amount;
        uint lastBlock;
        uint consumption;
    }
    //key:(white user, token)
    mapping(address => mapping(address => TokenLimit)) public tokenLimits;

    modifier onlyWhite() {
        require(whiteList[msg.sender], "SwitchTreasury: FORBIDDEN");
        _;
    }

    modifier whenNotPaused() override {
        if(msg.sender != targetTreasury) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function initialize(address _weth) external initializer {
        require(_weth != address(0), 'SwitchTreasury: ZERO_ADDRESS');
        owner = msg.sender;
        weth = _weth;
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        _unpause();
    }

    function applyWhite(address _user, bool _value) public onlyDev {
        applyWhiteList[_user] = _value;
    }

    function applyWhites(address[] memory _users, bool[] memory _values) external onlyDev {
        require(_users.length == _values.length, "SwitchTreasury: invalid param");
        for (uint256 i; i < _users.length; i++) {
            applyWhite(_users[i], _values[i]);
        }
    }

    function setWhite(address _user) public onlyAdmin {
        whiteList[_user] = applyWhiteList[_user];
    }

    function setWhites(address[] memory _users) external onlyAdmin {
        for (uint256 i; i < _users.length; i++) {
            setWhite(_users[i]);
        }
    }

    function setAllocPoint(address _user, uint _value) public onlyManager {
        totalAllocPoint = totalAllocPoint.sub(allocPoint[_user]).add(_value);
        emit AllocPointChanged(msg.sender, allocPoint[_user], _value);
        allocPoint[_user] = _value;
    }

    function batchSetAllocPoint(address[] memory _users, uint256[] memory _values) external onlyManager {
        require(_users.length == _values.length, 'SwitchTreasury: INVALID_PARAM');
        for (uint i; i<_users.length; i++) {
            setAllocPoint(_users[i], _values[i]);
        }
    }

    function setTokenLimit(address _user, address _token, bool _enabled, uint _blocks, uint _amount, uint _consumption) public onlyManager {
        require(_amount >= _consumption, 'SwitchTreasury: INVALID_PARAM');
        TokenLimit storage limit = tokenLimits[_user][_token];
        limit.enabled = _enabled;
        limit.blocks = _blocks;
        limit.amount = _amount;
        limit.consumption = _consumption;
    }

    function setTokenLimits(address[] memory _user, address[] memory _token, bool[] memory _enabled, uint[] memory _blocks, uint[] memory _amount, uint[] memory _consumption) external onlyManager {
        require(
            _user.length == _token.length 
            && _token.length == _enabled.length 
            && _enabled.length == _blocks.length 
            && _blocks.length == _amount.length 
            && _amount.length == _consumption.length 
            , "SwitchTreasury: INVALID_PARAM"
        );
        for (uint i; i<_user.length; i++) {
            setTokenLimit(_user[i], _token[i], _enabled[i], _blocks[i], _amount[i], _consumption[i]);
        }
    }

    function addSubscribe(address _user) external onlyDev {
        if(isSubscribe(_user) == false) {
            subscribes.push(_user);
        }
    }

    function removeSubscribe(address _user) external onlyDev {
        uint index = indexSubscribe(_user);
        if(index == subscribes.length) {
            return;
        }
        if(index < subscribes.length -1) {
            subscribes[index] = subscribes[subscribes.length-1];
        }
        subscribes.pop();
    }

    function isSubscribe(address _user) public view returns (bool) {
        for(uint i = 0;i < subscribes.length;i++) {
            if(_user == subscribes[i]) {
                return true;
            }
        }
        return false;
    }
    
    function indexSubscribe(address _user) public view returns (uint) {
        for(uint i; i< subscribes.length; i++) {
            if(subscribes[i] == _user) {
                return i;
            }
        }
        return subscribes.length;
    }
 
    function countSubscribe() public view returns (uint) {
        return subscribes.length;
    }

    function _subscribe(address _sender, address _from, address _to, address _token, uint _value) internal {
        for(uint i; i< subscribes.length; i++) {
            ISwitchTreasurySubscriber(subscribes[i]).subscribeTreasury(_sender, _from, _to, _token, _value);
        }
    }

    function countToken() public view returns (uint) {
        return tokens.length;
    }

    function mint(address _token, address _to, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        ISwitchTicket(_token).mint(_to, _value);
        senderBalanceOf[_token][msg.sender] += int(_value);
        return _value;
    }

    function burn(address _token, address _from, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        ISwitchTicket(_token).burn(_from, _value);
        senderBalanceOf[_token][msg.sender] -= int(_value);
        return _value;
    }

    function deposit(address _from, address _token, uint _value) external payable onlyWhite whenNotPaused nonReentrant returns (uint) {
        require(_value > 0, 'SwitchTreasury: ZERO');
        if (_token == address(0)) {
            _token = weth;
            require(_value == msg.value, 'SwitchTreasury: INVALID_VALUE');
            IWETH(weth).deposit{value: msg.value}();
        } else {
            require(IERC20(_token).balanceOf(_from) >= _value, 'SwitchTreasury: INSUFFICIENT_BALANCE');
            TransferHelper.safeTransferFrom(_token, _from, address(this), _value);
        }

        senderBalanceOf[_token][msg.sender] += int(_value);

        if(tokenExistence[_token] == false) {
            tokens.push(_token);
            tokenExistence[_token] = true;
        }
        
        _subscribe(msg.sender, _from, address(this), _token, _value);
        emit Deposited(_token, msg.sender, _from, _value);
        return _value;
    }

    function withdraw(bool _isETH, address _to, address _token, uint _value) external onlyWhite whenNotPaused nonReentrant returns (uint) {
        if (_token == address(0)) {
            _token = weth;
        }
        uint _amount = queryWithdraw(msg.sender, _token);
        require(_value > 0, 'SwitchTreasury: ZERO');
        require(_amount >= _value, 'SwitchTreasury: INSUFFICIENT_BALANCE');

        _updateTokenLimit(_token, _value);

        senderBalanceOf[_token][msg.sender] -= int(_value);
        
        emit Withdrawed(_token, msg.sender, _to, _value);
        if (_isETH && _token == weth) {
            uint balance = address(this).balance;
            if(balance < _value) {
                IWETH(weth).withdraw(_value.sub(balance));
            }
            TransferHelper.safeTransferETH(_to, _value);
        } else {
            TransferHelper.safeTransfer(_token, _to, _value);
        }
        _subscribe(msg.sender, address(this), _to, _token, _value);
        return _value;
    }

    function queryWithdraw(address _user, address _token) public view returns (uint) {
        if (_token == address(0)) {
            _token = weth;
        }
        uint amount = IERC20(_token).balanceOf(address(this));
        if(totalAllocPoint > 0) {
            amount = amount.mul(allocPoint[_user]).div(totalAllocPoint);
        }

        return getTokenLimit(_user, _token, amount);        
    }

    function getTokenLimit(address _user, address _token, uint _value) public view returns (uint) {
        TokenLimit memory limit = tokenLimits[_user][_token];
        if (limit.enabled == false) {
            return _value;
        }

        if(_value > limit.amount) {
            _value = limit.amount;
        }

        if (block.number.sub(limit.lastBlock) >= limit.blocks) {
            return _value;
        }

        if (limit.consumption.add(_value) > limit.amount) {
            _value = limit.amount.sub(limit.consumption);
        }
        return _value;
    }

    function _updateTokenLimit(address _token, uint _value) internal {
        TokenLimit storage limit = tokenLimits[msg.sender][_token];
        if(limit.enabled == false) {
            return;
        }
        if(block.number.sub(limit.lastBlock) > limit.blocks) {
            limit.consumption = 0;
        }
        limit.lastBlock = block.number;
        limit.consumption = limit.consumption.add(_value);
    }

    function toWETH() external onlyManager {
        uint balance = address(this).balance;
        IWETH(weth).deposit{value: balance}();
    }

    // for upgrade {
    function setTargetTreasury(address _targetTreasury) external onlyDev {
        require(_targetTreasury != address(0), 'SwitchTreasury: ZERO_ADDRESS');
        emit TargetTreasuryChanged(msg.sender, targetTreasury, _targetTreasury);
        targetTreasury = _targetTreasury;
    }

    function migrate(address _from, address _token) public onlyDev {
        uint amount = IERC20(_token).balanceOf(_from);
        if(amount > 0){
            ISwitchTreasury(_from).withdraw(false, address(this), _token, amount);
        }
    }

    function migrateList(address _from, address[] memory _tokens) external onlyDev {
        for(uint i; i<_tokens.length; i++) {
            migrate(_from, _tokens[i]);
        }
    }

    function migrateAll(address _from) external onlyDev {
        for(uint i; i<tokens.length; i++) {
            migrate(_from, tokens[i]);
        }
    }

    function changeOwnerForToken(address _token, address _user) public onlyDev {
        return ISwitchTicket(_token).changeOwner(_user);
    }

    function changeOwnerForTokens(address[] memory _tokens, address[] memory _users) external onlyDev {
        require(_tokens.length == _users.length, 'SwitchTreasury: invalid params');
        for(uint i; i<_tokens.length; i++) {
            changeOwnerForToken(_tokens[i], _users[i]);
        }
    }
    // for upgrade }
}
