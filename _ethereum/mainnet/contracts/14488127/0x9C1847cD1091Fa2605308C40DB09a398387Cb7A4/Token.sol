//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {
    mapping(address => uint256) private _balances;

    constructor() ERC20('Digital Bank of Africa', 'DBA') {
        setMinterRole(msg.sender, true);
    }

    bool public feeEnabled = true;
    uint256 private _totalSupply = 0;
    address public feeAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public feeHolder = 0; // fee amount expected to be divided by 1000, 10 feeAmount is 1% fee
    uint256 public feeBurn = 20; // fee amount expected to be divided by 1000, 10 feeBurn is 1% fee to burn
    mapping(address => bool) private excludeFromFee;

    mapping(address => bool) private isMinter;

    function decimals() public pure override returns(uint8) {
        return 8;
    }

    function setMinterRole(address account, bool _isMinter) public onlyOwner {
        isMinter[account] = _isMinter;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function setFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    function setFeeHolderAmount(uint256 newFeeAmount) external onlyOwner {
        feeHolder = newFeeAmount;
    }

    function setFeeBurnAmount(uint256 newFeeBurnAmount) external onlyOwner {
        feeBurn = newFeeBurnAmount;
    }

    function configureFeeForAccount(address account, bool isExcluded) public onlyOwner {
        excludeFromFee[account] = isExcluded;
    }

    function turnOnFee() external onlyOwner {
        require(feeEnabled);
        feeEnabled = false;
    }

    function turnOffFee() external onlyOwner {
        require(!feeEnabled);
        feeEnabled = true;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        bool fee = feeEnabled && !(excludeFromFee[from] || excludeFromFee[to]);

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, 'ERC20: transfer amount exceeds balance');
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        if (fee) {
            uint256 burnFee = (amount * feeBurn) / 1000;
            uint256 holderFee = (amount * feeHolder) / 1000;
            amount = amount - burnFee - holderFee;
            _balances[feeAddress] += holderFee;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        if (fee) {
            emit Transfer(from, feeAddress, feeHolder);
            emit Transfer(from, address(0), feeBurn);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal override onlyMinter {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal override {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        require(account != address(0), 'ERC20: burn from the zero address');
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, 'ERC20: burn amount exceeds allowance');
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], 'only minter can mint tokens');
        _;
    }
}
