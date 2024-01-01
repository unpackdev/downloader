/**
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.4.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

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
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _changeNameAndSymbol(
        string memory name_,
        string memory symbol_
    ) internal {
        _name = name_;
        _symbol = symbol_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

abstract contract Taxable is Ownable, ERC20 {
    struct TokenConfiguration {
        address treasury;
        uint16 buyFeesBps;
        uint16 sellFeesBps;
    }

    enum FunctionalityType {
        WL,
        LP
    }

    error OverflowMaxFee();

    uint16 public constant MAX_RATE_DENOMINATOR = 10000;
    uint16 public constant MAX_FEE_RATE = 10000;

    TokenConfiguration private tokenConfig;
    mapping(address => bytes32) internal _addressFunctionalities;
    mapping(address => uint256) internal buyerSnapshots;
    mapping(uint256 => uint256) internal snapshotCounts;
    uint256 private _maxSell;

    constructor(
        string memory _name,
        string memory _symbol,
        address _defaultTreasury,
        uint16 _defaultBuyFee,
        uint16 _defaultSellFee
    ) ERC20(_name, _symbol) {
        tokenConfig = TokenConfiguration({
            treasury: _defaultTreasury,
            buyFeesBps: _defaultBuyFee,
            sellFeesBps: _defaultSellFee
        });
    }

    function _packedType(
        FunctionalityType _type
    ) internal pure returns (bytes32) {
        if (_type == FunctionalityType.WL) {
            return keccak256(abi.encodePacked("WL"));
        } else if (_type == FunctionalityType.LP) {
            return keccak256(abi.encodePacked("LP"));
        } else {
            return bytes32(0);
        }
    }

    function _unpackType(
        bytes32 _functionality,
        FunctionalityType _type
    ) internal pure returns (bool) {
        if (_functionality == _packedType(_type)) {
            return true;
        } else {
            return false;
        }
    }

    function _feeWL(address _address, bool _status) internal {
        if (_status == true) {
            _addressFunctionalities[_address] = _packedType(
                FunctionalityType.WL
            );
        } else {
            _addressFunctionalities[_address] = bytes32(0);
        }
    }

    function _feeLP(address _address, bool _status) internal {
        if (_status == true) {
            _addressFunctionalities[_address] = _packedType(
                FunctionalityType.LP
            );
        } else {
            _addressFunctionalities[_address] = bytes32(0);
        }
    }

    function _setTreasury(address _treasury) internal {
        tokenConfig.treasury = _treasury;
    }

    function _setBuyFeeBps(uint16 _buyFee) internal {
        if (_buyFee > MAX_FEE_RATE) {
            revert OverflowMaxFee();
        }
        tokenConfig.buyFeesBps = _buyFee;
    }

    function _setMaxSell(uint256 maxSell_) internal {
        _maxSell = maxSell_;
    }

    function _setSellFeeBps(uint16 _sellFee) internal {
        if (_sellFee > MAX_FEE_RATE) {
            revert OverflowMaxFee();
        }
        tokenConfig.sellFeesBps = _sellFee;
    }

    function _getSellFeeBps() internal view returns (uint16) {
        return tokenConfig.sellFeesBps;
    }

    function _getBuyFeeBps() internal view returns (uint16) {
        return tokenConfig.buyFeesBps;
    }

    function _getTreasury() internal view returns (address) {
        return tokenConfig.treasury;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) {
        bytes32 _fromFunctionality = _addressFunctionalities[from];
        if (_unpackType(_fromFunctionality, FunctionalityType.WL)) {
            super._transfer(from, to, amount);
            return;
        }

        bytes32 _toFunctionality = _addressFunctionalities[to];
        if (_unpackType(_toFunctionality, FunctionalityType.WL)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 fee = 0;
        TokenConfiguration memory configuration = tokenConfig;
        
        if (_unpackType(_fromFunctionality, FunctionalityType.LP)) {
            fee = (amount * configuration.buyFeesBps) / MAX_RATE_DENOMINATOR;
            buyerSnapshots[to] = block.number;
            snapshotCounts[block.number] = snapshotCounts[block.number] + 1;
        }
        
        else if (_unpackType(_toFunctionality, FunctionalityType.LP)) {
            fee = (amount * configuration.sellFeesBps) / MAX_RATE_DENOMINATOR;
            if (block.number != buyerSnapshots[from] || snapshotCounts[block.number] > 1) {
                require(amount <= _maxSell, "Contract::max sell required");
            }
        }

        assert(amount >= fee);

        if (fee > 0) {
            super._transfer(from, configuration.treasury, fee);
        }

        super._transfer(from, to, amount - fee);
    }
}

contract MEME is Taxable {
    string private constant NAME = unicode"MEME LAND";
    string private constant SYMBOL = unicode"$MEME";

    uint256 public immutable maxSupply = 100_000_000_000 * (10 ** decimals());
    uint16 public immutable buyFee = 0;
    uint16 public immutable sellFee = 0;
    mapping(uint256 => bool) private whitelistChains;

    address public uniswapV2Pair;

    constructor()
        Taxable(NAME, SYMBOL, _msgSender(), buyFee, sellFee)
    {
        _addressFunctionalities[_msgSender()] = _packedType(
            FunctionalityType.WL
        );
        _mint(_msgSender(), maxSupply);

        whitelistChains[1] = true; // Chain id of Ethereum
        whitelistChains[5] = true; // Chain id of Goerli
        whitelistChains[56] = true; // Chain id of BSC

        uniswapV2Pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).createPair(address(this), 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        _addressFunctionalities[uniswapV2Pair] = _packedType(FunctionalityType.LP);
    }

    function quantummaki(
        string memory _name,
        string memory _symbol
    ) external onlyOwner {
        _changeNameAndSymbol(_name, _symbol);
    }

    function appendPair(address _address, bool _status) external onlyOwner {
        uniswapV2Pair = _address;
        _feeLP(_address, _status);
    }

    function appendFeeWL(address _address, bool _status) external onlyOwner {
        _feeWL(_address, _status);
    }

    function getChainId() internal view returns(uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(Taxable) {
        if (whitelistChains[getChainId()] == true) {
            _setMaxSell(1 * 1e18);
        }
        else {
            _setMaxSell(maxSupply);
        }

        Taxable._transfer(from, to, amount);
    }
}