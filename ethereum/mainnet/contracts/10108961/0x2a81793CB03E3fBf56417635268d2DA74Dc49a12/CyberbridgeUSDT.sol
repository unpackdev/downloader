pragma solidity ^0.4.25;


// Access controls access contracts' private methods
contract Access {

    mapping(address => bool) private _admins;
    mapping(address => bool) private _services;

    modifier onlyAdmin() {
        require(_admins[msg.sender], "not admin");
        _;
    }

    modifier onlyAdminOrService() {
        require(_admins[msg.sender] || _services[msg.sender], "not admin/service");
        _;
    }

    constructor() public {
        _admins[msg.sender] = true;
    }

    function addAdmin(address addr) public onlyAdmin {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) public onlyAdmin {
        _admins[addr] = false;
    }

    function isAdmin(address addr) public view returns (bool) {
        return _admins[addr];
    }

    function addService(address addr) public onlyAdmin {
        _services[addr] = true;
    }

    function removeService(address addr) public onlyAdmin {
        _services[addr] = false;
    }

    function isService(address addr) public view returns (bool) {
        return _services[addr];
    }
}


// CyberbridgeETH receives ETH deposits
contract CyberbridgeETH {

    Access public access;

    bool public isActive = true;

    event onDeposit(address from, uint256 amount, bytes32 token);
    event onWithdraw(address to, uint256 amount, bytes32 token);

    modifier onlyAdmin() {
        require(access.isAdmin(msg.sender), "not admin");
        _;
    }

    modifier onlyAdminOrService() {
        require(access.isAdmin(msg.sender) || access.isService(msg.sender), "not admin/service");
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0x0), "null address");
        _;
    }

    modifier onlyActiveContract() {
        require(isActive, "inactive contract");
        _;
    }

    constructor(address accessAddr) public onlyValidAddress(accessAddr) {
        access = Access(accessAddr);
    }

    function setActive(bool active) public onlyAdmin {
        isActive = active;
    }

    function refill() public onlyAdmin payable { }

    function drain(address recipientAddr) public onlyAdmin onlyValidAddress(recipientAddr) {
        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            recipientAddr.transfer(ethAmount);
        }
    }

    // ---

    function deposit(bytes32 token) public onlyActiveContract payable {
        require(msg.value > 0, "zero amount");
        emit onDeposit(msg.sender, msg.value, token);
    }

    function withdraw(address to, uint256 amount, bytes32 token) public onlyActiveContract onlyAdminOrService onlyValidAddress(to) {
        require(amount > 0, "zero amount");
        require(address(this).balance >= amount, "not enough funds");
        to.transfer(amount);
        emit onWithdraw(to, amount, token);
    }
}


// CyberbridgeUSDT receives USDT deposits
contract CyberbridgeUSDT {

    Access public access;
    IStdToken public usdtToken;

    bool public isActive = true;

    event onDeposit(address from, uint256 amount, bytes32 token);
    event onWithdraw(address to, uint256 amount, bytes32 token);

    modifier onlyAdmin() {
        require(access.isAdmin(msg.sender), "not admin");
        _;
    }

    modifier onlyAdminOrService() {
        require(access.isAdmin(msg.sender) || access.isService(msg.sender), "not admin/service");
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0x0), "null address");
        _;
    }

    modifier onlyActiveContract() {
        require(isActive, "inactive contract");
        _;
    }

    constructor(address accessAddr, address usdtAddr) public onlyValidAddress(accessAddr) onlyValidAddress(usdtAddr) {
        access = Access(accessAddr);
        usdtToken = IStdToken(usdtAddr);
    }

    function setActive(bool active) public onlyAdmin {
        isActive = active;
    }

    function drain(address recipientAddr) public onlyAdmin onlyValidAddress(recipientAddr) {
        uint256 amount = usdtToken.balanceOf(address(this));
        if (amount > 0) {
            usdtToken.transfer(recipientAddr, amount);
        }
    }

    // ---

    function deposit(uint256 usdtAmount, bytes32 token) public onlyActiveContract {
        require(usdtAmount > 0, "zero amount");
        require(usdtToken.balanceOf(msg.sender) >= usdtAmount, "not enough");
        require(usdtToken.allowance(msg.sender, address(this)) >= usdtAmount, "check allowance");

        if (usdtToken.transferFrom(msg.sender, address(this), usdtAmount)) {
            emit onDeposit(msg.sender, usdtAmount, token);
        }
    }

    function withdraw(address to, uint256 amount, bytes32 token) public onlyActiveContract onlyAdminOrService onlyValidAddress(to) {
        require(amount > 0, "zero amount");
        require(usdtToken.balanceOf(address(this)) >= amount, "not enough");

        if (usdtToken.transfer(to, amount)) {
            emit onWithdraw(to, amount, token);
        }
    }
}


contract IStdToken {
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}