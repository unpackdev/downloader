// contracts/Dirham.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./Ownable.sol";

contract Dirham is Initializable, AccessControlUpgradeSafe, ERC20DetailedUpgradeSafe, OwnableUpgradeSafe{

    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");
    
    uint256 public _currentFactor;
    uint256 public _rebaseFactor;
    uint256 public _accuracy;

    event Rebase(uint256 rebaseFactor);

    function initialize(address gnosis) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, gnosis);
        _setupRole(MINTER_ROLE, gnosis);
        _setupRole(REBASER_ROLE, gnosis);
        __ERC20Detailed_init('Dirham', 'DHS');
        __Ownable_init();

        _currentFactor = 1e18;
        _rebaseFactor = 1000754529000000000;
        _accuracy = 1e18;
    }


    function mint(address account, uint256 amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(account != address(0), "ERC20: mint to the zero address");

        uint256 scaledAmount = amount.mul(_accuracy).div(_currentFactor);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(scaledAmount);

        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {         
                 
         uint256 scaledAmount = amount.mul(_accuracy).div(_currentFactor);

        _balances[_msgSender()] = _balances[_msgSender()].sub(scaledAmount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);       
        emit Transfer(_msgSender(), address(0), amount);
    }

    function rebase() external {
        require(hasRole(REBASER_ROLE, _msgSender()), "Caller is not a rebaser");
        _totalSupply = _totalSupply.mul(_rebaseFactor).div(_accuracy);
        _currentFactor = _currentFactor.mul(_rebaseFactor).div(_accuracy);
        emit Rebase(_rebaseFactor);
    }

    function setRebaseFactor(uint256 rebaseFactor) external {
        require(hasRole(REBASER_ROLE, _msgSender()), "Caller is not a rebaser");
        _rebaseFactor = rebaseFactor;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(this), "Transfer to Dirham is not allowed");
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;   
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
                
        uint256 scaledAmount = amount.mul(_accuracy).div(_currentFactor);

        _balances[sender] = _balances[sender].sub(scaledAmount, "ERC20: transfer amount exceeds balance");
        if (amount.mul(_accuracy) % _currentFactor != 0) {
            _balances[recipient] = _balances[recipient].add(scaledAmount + 1);
            _totalSupply = _totalSupply + _currentFactor.div(_accuracy);
        }

        else {
            _balances[recipient] = _balances[recipient].add(scaledAmount);        
        }
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {

        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;        
    }

    function totalSupply() external view override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256){
        return _balances[account].mul(_currentFactor).div(_accuracy);
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function rescueERC20(address token, address recipient, uint256 amount) external onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }
}