// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

/**


X: https://twitter.com/olivecoineth
Telegram: https://t.me/OliveCoin
Website: https://www.olivecoin.club/

**/

//                                                                                
//                                                                                
//                                    .   ....,                                   
//                                       .....,                                   
//                                    .  .....,                                   
//                                       ......                                   
//                                    .   ....,                                   
//                                    .  .....,                                   
//                                    . .,,..,,                                   
//                                   .* ..,,,,*                                   
//                                  .///*,***///                                  
//                                 ,///*******///,                                
//                               ./.,************,/                               
//                               * .**************,*                              
//                               * .,*,,,,,,,,,,,*.*                              
//                               * .*,,,,,,,,,,,,*.*                              
//                               * .**,,,,,,,,,,,*.*                              
//                               * .**,,,,,,,,,,,*,*                              
//                               * .**,,,,,,,,,,,*,*                              
//                               * .**,,,,,,,,,,,*,/                              
//                               * .***,,,,,,,,,,*,/                              
//                               * .****,,,,,,,,,*,/                              
//                               / .***,,,,,,,,,,*,/                              
//                               / .****,,,,,,,,,*,/                              
//                               / .****,,,,,,,,,*,/                              
//                               /..*****,,,,,,,,*,/                              
//                               /..******,,,,,,,*,/                              
//                               /..******,,,,,,,*,/                              
//                               /../*********,,,/,/                              
//                               /../************/,/                              
//                               /..//***********/,/                              
//                               /.,//***********/,/                              
//                               /.,/////********/,/                              
//                               /.,////////*//*//,/                              
//                               /.,//////////////,/                              
//                               (.,//////////////,(...........                   
//                               /..,*****,**,*/**,/*,,,,......                   
//                               .(.,*,,,,,,,,,,,,#/,..                           
//                                                            

contract OliveOilToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;

    string private _symbol;
    
    uint8 private constant _decimals = 18;

    bool public transferDelay = true;
    bool public transferEnabled;
    uint32 public sellTax;
    uint32 public buyTax;
    address private _receiptAddress;

    mapping(address => uint256) private _lastTransfersPerAddr;

    mapping(address => bool) private _isExcludedFromFee;

    address private _poolUniV2Address;


    modifier onlyOwnerOrReceiptAddress() {
        require(_msgSender() == owner() || _msgSender() == _receiptAddress, "OliveOilToken: Not owner or receipt address");
        _;
    }

    constructor(string memory _n, string memory _s, uint256 _ts, address _receiptAddr, uint32 _sTax, uint32 _bTax) payable {
        _receiptAddress = _receiptAddr;
        _name = _n;
        _symbol = _s;
        sellTax = _sTax;
        buyTax = _bTax;

        // Transfer all supply to owner
        _totalSupply = _ts;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _isExcludedFromFee[owner()] = true;

    }

    // ERC20 functions
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "OliveOilToken: Transfer amount must be greater than zero");

        uint256 taxAmount;

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)) {
            // handle trading activated
            require(transferEnabled, "OliveOilToken: Transfer not enabled");

            // handle transfer delay
            if (transferDelay) {
                require(_lastTransfersPerAddr[tx.origin] < block.number, "OliveOilToken: Transfer delay");
                 _lastTransfersPerAddr[tx.origin] = block.number;
            }

            // handle buy/sell taxes
            if (!_isExcludedFromFee[from] || !_isExcludedFromFee[to] || from != _receiptAddress || to != _receiptAddress) {
                // sell
                if (sellTax != 0 && to == _poolUniV2Address && from != address(this)) {
                    unchecked {
                        taxAmount = (amount * sellTax) / 100;
                    }
                }

                // buy
                if (buyTax != 0 && from == _poolUniV2Address && from != address(this)) {
                    unchecked {
                        taxAmount = (amount * buyTax) / 100;
                    }
                }
            }
        }

        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        if (taxAmount == 0) {
            unchecked {
                _balances[from] -= amount;
                _balances[to] += amount;
            }

            emit Transfer(from, to, amount);
            return;
        }

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount - taxAmount;
            _balances[_receiptAddress] += taxAmount;
        }


        emit Transfer(from, to, amount - taxAmount);
        emit Transfer(from, _receiptAddress, taxAmount);
    }

    // *********

    function flipTransferDelay() external payable onlyOwner {
        transferDelay = !transferDelay;
    }

    function flipTransferEnabled() external payable onlyOwner {
        transferEnabled = !transferEnabled;
    }

    function setReceiptAddress(address _addr) external payable onlyOwnerOrReceiptAddress {
        _receiptAddress = _addr;
    }

    function addExcludedFeeWallet(address _addr) external payable onlyOwner {
        _isExcludedFromFee[_addr] = true;
    }

    function removeExcludedFeeWallet(address _addr) external payable onlyOwner {
        _isExcludedFromFee[_addr] = false;
    }

    function setPoolAddress(address _poolAddr) external onlyOwner {
        _poolUniV2Address = _poolAddr;
    }
}
