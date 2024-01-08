// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ISwitchTicketFactory.sol";
import "./ISwitchTreasury.sol";
import "./TransferHelper.sol";
import "./UserTokenLimit.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./SwitchTicket.sol";

contract SwitchTicketFactory is UserTokenLimit, Pausable, ReentrancyGuard, Initializable {
    address public weth;
    address public treasury;
    address public oldTicketFactory;
    string public prefixSymbol;
    string public prefixName;
    address[] public tickets;
    address[] public tokens;
    mapping(address => address) public tokenMap;
    mapping(address => bool) public tokenStatus;
    mapping(address => bool) public tokenExistence;
    mapping(address => bool) public ticketExistence;
    bool public enableTokenList;

    struct TokenMapData {
        address token;
        address ticket;
    }

    event TokenStatusChanged(address indexed token, bool enabled);
    event TicketCreated(address indexed token, address indexed ticket, string symbol, string name);
    event Deposited(address indexed _token, address indexed _ticket, address from, address to, uint value);
    event Withdrawed(address indexed _token, address indexed _ticket, address from, address to, uint _value);
    event TreasuryChanged(address indexed user, address indexed _old, address indexed _new);
    event PrefixChanged(address indexed user, string _prefixSymbol, string _prefixName);
    event OldTicketFactoryChanged(address indexed user, address indexed _old, address indexed _new);
    event EnableTokenListChanged(address indexed user, bool indexed _old, bool indexed _new);

    receive() external payable {
    }

    function initialize(address _weth) external initializer {
        require(_weth != address(0), 'SwitchTicketFactory: ZERO_ADDRESS');
        owner = msg.sender;
        weth = _weth;
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    function unpause() external onlyManager whenPaused {
        _unpause();
    }

    function countTicket() public view returns (uint) {
        return tickets.length;
    }

    function countToken() public view returns (uint) {
        return tokens.length;
    }

    function configure(address _treasury, bool _value, string calldata _prefixSymbol, string calldata _prefixName) external onlyDev {
        require(_treasury != address(0), 'SwitchTicketFactory: ZERO_ADDRESS');
        emit TreasuryChanged(msg.sender, treasury, _treasury);
        emit PrefixChanged(msg.sender, _prefixSymbol, _prefixName);
        treasury = _treasury;
        enableTokenList = _value;
        prefixSymbol = _prefixSymbol;
        prefixName = _prefixName;
    }

    function setTreasury(address _treasury) external onlyDev {
        require(_treasury != address(0), 'SwitchTicketFactory: ZERO_ADDRESS');
        emit TreasuryChanged(msg.sender, treasury, _treasury);
        treasury = _treasury;
    }

    function setPrefix(string calldata _prefixSymbol, string calldata _prefixName) external onlyDev {
        emit PrefixChanged(msg.sender, _prefixSymbol, _prefixName);
        prefixSymbol = _prefixSymbol;
        prefixName = _prefixName;
    }

    function setOldTicketFactory(address _oldTicketFactory) external onlyDev {
        require(oldTicketFactory != _oldTicketFactory && _oldTicketFactory != address(this), 'SwitchTicketFactory: INVALID_PARAM');
        emit OldTicketFactoryChanged(msg.sender, oldTicketFactory, _oldTicketFactory);
        oldTicketFactory = _oldTicketFactory;
    }

    function getTokenMap(address _token) public view returns (address) {
        if (_token == address(0)) {
            _token = weth;
        }
        address res = tokenMap[_token];
        if(res == address(0) && oldTicketFactory != address(0)) {
            res = ISwitchTicketFactory(oldTicketFactory).getTokenMap(_token);
        }
        return res;
    }

    function isTicket(address _ticket) public view returns (bool) {
        bool res = ticketExistence[_ticket];
        if(res == false && oldTicketFactory != address(0)) {
            res = ISwitchTicketFactory(oldTicketFactory).isTicket(_ticket);
        }
        return res;
    }

    function enableToken(bool _value) external onlyDev {
        emit EnableTokenListChanged(msg.sender, enableTokenList, _value);
        enableTokenList = _value;
    }

    function setToken(address _token, bool _value) public onlyDev {
        if(tokenExistence[_token] == false) {
            tokens.push(_token);
            tokenExistence[_token] = true;
        }
        tokenStatus[_token] = _value;
        emit TokenStatusChanged(_token, _value);
    }

    function setTokens(address[] memory _tokens, bool[] memory _values) external onlyDev {
        require(_tokens.length == _values.length, 'SwitchTicketFactory: INVALID_PARAM');
        for (uint i; i < _tokens.length; i++) {
            setToken(_tokens[i], _values[i]);
        }
    }

    function canCreateTicket(address _token) public view returns (bool) {
        if(_token == address(0)) {
            _token = weth;
        }
        if(enableTokenList) {
            if(tokenMap[_token] == address(0) && tokenStatus[_token]) {
                return true;
            }
        } else {
            if(tokenMap[_token] == address(0)) {
                return true;
            }
        }
        return false;
    }

    function createTicket(address _token) public returns (address ticket) {
        if(_token == address(0)) {
            _token = weth;
        }
        if(enableTokenList) {
            require(tokenStatus[_token], "SwitchTicketFactory: TOKEN_FORBIDDEN");
        }
        require(tokenMap[_token] == address(0), 'SwitchTicketFactory: EXISTS');
        {
            // check is compatible or not
            IERC20(_token).decimals();
            IERC20(_token).totalSupply();
            IERC20(_token).name();
            IERC20(_token).symbol();
        }

        bytes memory bytecode = type(SwitchTicket).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token));
        
        assembly {
            ticket := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        string memory _symbol = stringConcat(prefixSymbol, IERC20(_token).symbol());
        string memory _name = stringConcat(prefixName, IERC20(_token).name());
        SwitchTicket(ticket).initialize(treasury, _token, _symbol, _name);
        tokenMap[_token] = ticket;
        tokenMap[ticket] = _token;
        ticketExistence[ticket] = true;
        tickets.push(ticket);
        emit TicketCreated(_token, ticket, _symbol, _name);
        return ticket;
    }

    function deposit(address _token, uint _value, address _to) external payable nonReentrant whenNotPaused returns (address) {
        require(_value > 0, 'SwitchTicketFactory: ZERO');
        if(canCreateTicket(_token)) {
            createTicket(_token);
        }
        bool isETH;
        if(_token == address(0)) {
            isETH = true;
            _token = weth;
        }
        address ticket = tokenMap[_token];
        require(ticket != address(0), 'SwitchTicketFactory: TICKET_NONEXISTS');
        
        uint depositAmount;
        if (isETH) {
            _value = msg.value;
            depositAmount = ISwitchTreasury(treasury).deposit{value: msg.value}(msg.sender, address(0), _value);
        } else {
            depositAmount = ISwitchTreasury(treasury).deposit(msg.sender, _token, _value);
        }
        require(depositAmount == _value, "SwitchTicketFactory: TREASURY_DEPOSIT_FAIL");
  
        ISwitchTreasury(treasury).mint(ticket, _to, _value);
        emit Deposited(_token, ticket, msg.sender, _to, _value);
        return ticket;
    }

    function queryWithdrawInfo(address _user, address _ticket) public view returns (uint balance, uint amount) {
        address _token = tokenMap[_ticket];
        balance = IERC20(_ticket).balanceOf(_user);
        amount = ISwitchTreasury(treasury).queryWithdraw(address(this), _token);
        if(amount < balance) {
            amount = balance;
        }
        amount = getUserLimit(_user, _token, amount);
        return (balance, amount);
    }

    function queryWithdraw(address _user, address _ticket) public view returns (uint) {
        (uint balance, uint amount) = queryWithdrawInfo(_user, _ticket);
        if(amount < balance) {
            balance = amount;
        }
        return balance;
    }

    function withdrawAdv(bool isETH, address _to, address _ticket, uint _value) public nonReentrant whenNotPaused returns (bool) {
        require(_value > 0, 'SwitchTicketFactory: ZERO');
        address _token = tokenMap[_ticket];
        require(_token != address(0), 'SwitchTicketFactory: NOTFOUND_TICKET');
        require(queryWithdraw(msg.sender, _ticket) >= _value, 'SwitchTicketFactory: INSUFFICIENT_BALANCE');

        _updateUserTokenLimit(_token, _value);
        emit Withdrawed(_token, _ticket, msg.sender, _to, _value);
        
        ISwitchTreasury(treasury).burn(_ticket, msg.sender, _value);
        ISwitchTreasury(treasury).withdraw(isETH, _to, _token, _value);
        return true;
    }

    function withdraw(address _to, address _ticket, uint _value) external whenNotPaused returns (bool) {
        address _token = tokenMap[_ticket];
        bool isETH;
        if(_token == weth) {
            isETH = true;
        }
        return withdrawAdv(isETH, _to, _ticket, _value);
    }

    function getTokenMapData(address _ticket) public view returns (TokenMapData memory){
        return TokenMapData({
            token: tokenMap[_ticket],
            ticket: _ticket
        });
    }

    function iterateTokenMapData(uint _start, uint _end) external view returns (TokenMapData[] memory result){
        require(_start <= _end && _start >= 0 && _end >= 0, "SwitchTicketFactory: INVAID_PARAMTERS");
        uint count = countTicket();
        if (_end > count) _end = count;
        count = _end - _start;
        result = new TokenMapData[](count);
        if (count == 0) return result;
        uint index = 0;
        for(uint i = _start;i < _end;i++) {
            address _ticket = tickets[i];
            result[index] = getTokenMapData(_ticket);
            index++;
        }
        return result;
    }

    function stringConcat(string memory _a, string memory _b) public returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }
}
