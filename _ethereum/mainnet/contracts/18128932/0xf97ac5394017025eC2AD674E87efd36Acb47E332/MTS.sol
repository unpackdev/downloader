// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MTS {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    address payable public owner;

    address public tax = 0xfc43961ce694a42F250ee62b2c330B5680Db032A;

    uint256 public airdropReleaseDate = 1697328000;

    uint256 public Fee = 100; // 1%

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private claimed;

    receive() external payable {}

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _initialSupply * (10 ** uint256(_decimals));

        owner = payable(msg.sender);

        balances[owner] = (85 * totalSupply) / 100;
        balances[address(this)] = totalSupply - balances[owner];

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Must be creator");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function renounceOwnership() public onlyOwner {
        owner = payable(address(0));
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        _transfer(msg.sender, _to, _value);

        return true;

    }

    function _transfer(address _from, address _to, uint256 _value) internal {

        require(_to != address(0), "Invalid recipient address");
        require(_from != address(0), "Invalid sender address");

        require(balances[_from] >= _value, "Insufficient balance");

        if (airdropReleaseDate > block.timestamp) {
            if (claimed[_from] == true) {
                uint256 balance = balances[_from];
                balance -= 37500000 * (10 ** 18);
                require(balance >= _value, "Airdrop allocation cannot be spent at this time");
            }
        }

        uint256 _amount = _value;

        if(!_isExcludedFromFees[_from] && !_isExcludedFromFees[_to]
        ) {

            uint256 fees = _value * Fee / 10000;

            if(fees > 2) {
                if (balances[address(0)] < (20 * totalSupply) / 100) {
                    balances[tax] += fees / 2;
                    balances[address(0)] += fees / 2;
                }
                else {
                    balances[tax] += fees;
                }
            }

            _amount = _value - fees;

        }

        balances[_from] -= _value;
        balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);

    }

    function airdropPool() public view returns (uint256) {
        return balances[address(this)];
    }

    function hasClaimed(address _account) public view returns (bool) {
        return claimed[_account];
    }

    function claimAirdrop() public payable returns (bool) {

        uint256 claimPerPerson = 37500000 * (10 ** 18);

        require(msg.value >= 7 * (10 ** 14), "Amount lower than required ETH for claim");
        require(claimed[msg.sender] == false, "Cannot claim more than once");
        require(balances[address(this)] >= claimPerPerson, "Amount in pool is insufficient");
        require(block.timestamp < airdropReleaseDate, "Cannot claim airdrop at this time");
        
        unchecked {
            balances[address(this)] -= claimPerPerson;
            balances[msg.sender] += claimPerPerson;
        }

        claimed[msg.sender] = true;

        owner.transfer(msg.value);

        emit Transfer(address(this), msg.sender, claimPerPerson);

        return true;
    }

    function setClaimDate(uint256 _date) public onlyOwner returns (bool) {
        airdropReleaseDate = _date;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(allowed[_from][msg.sender] >= _value, "Allowance exceeded");

        _transfer(_from, _to, _value);

        allowed[_from][msg.sender] -= _value;

        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowed[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "Allowance exceeded");
        allowed[msg.sender][_spender] = currentAllowance - _subtractedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function setFees(uint256 _Fee) public onlyOwner() {
        require(_Fee <= 1000, "buy tax too high");
        Fee = _Fee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
}