// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IX2Factory.sol";
import "./IX2Market.sol";
import "./IX2Token.sol";

contract X2Token is IERC20, IX2Token, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override _totalSupply;

    address public override market;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    bool public isInitialized;

    modifier onlyMarket() {
        require(msg.sender == market, "X2Token: forbidden");
        _;
    }

    function initialize(address _market, string memory _symbol) public {
        require(!isInitialized, "X2Token: already initialized");
        isInitialized = true;
        market = _market;
        name = _symbol;
        symbol = _symbol;
    }

    function mint(address _account, uint256 _amount, uint256 _divisor) public override onlyMarket {
        _mint(_account, _amount, _divisor);
    }

    function burn(address _account, uint256 _amount) public override onlyMarket {
        _burn(_account, _amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply.div(getDivisor());
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account].div(getDivisor());
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "X2Token: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function getDivisor() public view returns (uint256) {
        return IX2Market(market).getDivisor(address(this));
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        IX2Market(market).rebase();

        require(_sender != address(0), "X2Token: transfer from the zero address");
        require(_recipient != address(0), "X2Token: transfer to the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_sender, _amount, divisor);
        _increaseBalance(_recipient, _amount, divisor);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address _account, uint256 _amount, uint256 _divisor) private {
        require(_account != address(0), "X2Token: mint to the zero address");

        _increaseBalance(_account, _amount, _divisor);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "X2Token: burn from the zero address");

        uint256 divisor = getDivisor();
        _decreaseBalance(_account, _amount, divisor);

        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "X2Token: approve from the zero address");
        require(_spender != address(0), "X2Token: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _increaseBalance(address _account, uint256 _amount, uint256 _divisor) private {
        if (_amount == 0) { return; }

        uint256 scaledAmount = _amount.mul(_divisor);
        balances[_account] = balances[_account].add(scaledAmount);
        _totalSupply = _totalSupply.add(scaledAmount);
    }

    function _decreaseBalance(address _account, uint256 _amount, uint256 _divisor) private {
        if (_amount == 0) { return; }

        uint256 scaledAmount = _amount.mul(_divisor);
        balances[_account] = balances[_account].sub(scaledAmount);
        _totalSupply = _totalSupply.sub(scaledAmount);
    }
}
