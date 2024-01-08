// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ERC20Token.sol";
import "./Initializable.sol";

contract Burger is ERC20Token, Initializable {
    using SafeMath for uint;
    address public owner;
    address public admin;
    address public team;
    uint public teamRate;
    mapping (address => uint) public funds;
    
    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);
    event AdminChanged(address indexed _user, address indexed _old, address indexed _new);
    event TeamChanged(address indexed _user, address indexed _old, address indexed _new);
    event TeamRateChanged(address indexed _user, uint indexed _old, uint indexed _new);
    event FundChanged(address indexed _user, uint indexed _old, uint indexed _new);
    
    modifier onlyOwner() {
        require(msg.sender == owner, 'forbidden');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, "forbidden");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == team || msg.sender == owner, "forbidden");
        _;
    }

    function initialize() external initializer {
        decimals = 18;
        name = 'Burger Swap';
        symbol = 'BURGER';
        owner = msg.sender;
        admin = msg.sender;
        team = msg.sender;
    }
    
    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'no change');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }

    function changeAdmin(address _user) external onlyAdmin {
        require(admin != _user, 'no change');
        emit AdminChanged(msg.sender, admin, _user);
        admin = _user;
    }

    function changeTeam(address _user) external onlyTeam {
        require(team != _user, 'no change');
        emit TeamChanged(msg.sender, team, _user);
        team = _user;
    }

    function changeTeamRate(uint _teamRate) external onlyAdmin {
        require(teamRate != _teamRate, 'no change');
        emit TeamRateChanged(msg.sender, teamRate, _teamRate);
        teamRate = _teamRate;
    }

    function increaseFund (address _user, uint _value) public onlyAdmin {
        require(_value > 0, 'zero');
        uint _old = funds[_user];
        funds[_user] = _old.add(_value);
        emit FundChanged(msg.sender, _old, funds[_user]);
    }

    function decreaseFund (address _user, uint _value) public onlyAdmin {
        uint _old = funds[_user];
        require(_value > 0, 'zero');
        require(_old >= _value, 'insufficient');
        funds[_user] = _old.sub(_value);
        emit FundChanged(msg.sender, _old, funds[_user]);
    }
    
    function increaseFunds (address[] calldata _users, uint[] calldata _values) external onlyAdmin {
        require(_users.length == _values.length, 'invalid parameters');
        for (uint i=0; i<_users.length; i++){
            increaseFund(_users[i], _values[i]);
        }
    }
    
    function decreaseFunds (address[] calldata _users, uint[] calldata _values) external onlyAdmin {
        require(_users.length == _values.length, 'invalid parameters');
        for (uint i=0; i<_users.length; i++){
            decreaseFund(_users[i], _values[i]);
        }
    }

    function _mint(address to, uint value) internal returns (bool) {
        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(address(this), to, value);
        return true;
    }

    function mint(address to, uint value) external returns (bool) {
        require(funds[msg.sender] >= value, "fund insufficient");
        funds[msg.sender] = funds[msg.sender].sub(value);
        _mint(to, value);

        if(value > 0 && teamRate > 0 && team != to) {
            uint reward = value.div(teamRate);
            _mint(team, reward);
        }
        return true;
    }

    function burn(uint value) external returns (bool) {
        _transfer(msg.sender, address(0), value);
        return true;
    }

    function take() public view returns (uint) {
        return funds[msg.sender];
    }
}
