// SPDX-License-Identifier: MIT
import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

pragma solidity 0.8.19;

contract ERC20PresetMinterRebaser is Context, AccessControlEnumerable, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(REBASER_ROLE, _msgSender());
    }
}

pragma solidity 0.8.19;

contract Scramble is ERC20PresetMinterRebaser, Ownable {
    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10 ** 24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10 ** 18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public scrambleScalingFactor;

    mapping(address => uint256) internal _scrambleBalances;

    mapping(address => mapping(address => uint256)) internal _allowedFragments;

    mapping(address => bool) public excludedFromReflections;

    address payable public reflectionsReceiver;

    uint256 public reflectionsPercent = 200;

    uint256 public maxReflectionsSwap = 500_000e18;

    bool public tradingOpen = false;

    uint256 public maxWallet = 3_000_000e18;

    bool inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 public initSupply;
    uint256 public immutable INIT_SUPPLY = 100_000_000e18;
    uint256 private _totalSupply;

    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor() ERC20PresetMinterRebaser("Scramble Finance", "SCRAMBLE") {
        scrambleScalingFactor = BASE;
        initSupply = _fragmentToScramble(INIT_SUPPLY);
        _totalSupply = INIT_SUPPLY;
        _scrambleBalances[owner()] = initSupply;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );

        excludedFromReflections[owner()] = true;
        excludedFromReflections[address(this)] = true;

        excludedFromReflections[0x52CD8FD56F9ce6569BE118eCe6BAE6aB86CA34fb] = true;
        reflectionsReceiver = payable(0x52CD8FD56F9ce6569BE118eCe6BAE6aB86CA34fb);

        emit Transfer(address(0), msg.sender, INIT_SUPPLY);
    }

    event Rebase(uint256 epoch, uint256 prevScramblesScalingFactor, uint256 newScramblesScalingFactor);
    event Mint(address to, uint256 amount);
    event Burn(address from, uint256 amount);

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Computes the current max scaling factor
     */
    function maxScalingFactor() external view returns (uint256) {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = initSupply * scrambleScalingFactor
        // this is used to check if scrambleScalingFactor will be too high to compute balances when rebasing.
        return uint256(int256(-1)) / initSupply;
    }

    /**
     * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
     */
    function mint(address to, uint256 amount) external returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");

        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal override {
        // increase totalSupply
        _totalSupply = _totalSupply + amount;

        // get underlying value
        uint256 scrambleValue = _fragmentToScramble(amount);

        // increase initSupply
        initSupply = initSupply + scrambleValue;

        // make sure the mint didnt push maxScalingFactor too low
        require(scrambleScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _scrambleBalances[to] = _scrambleBalances[to] + scrambleValue;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @notice Burns tokens from msg.sender, decreases totalSupply, initSupply, and a users balance.
     */

    function burn(uint256 amount) public override {
        _burn(amount);
    }

    function _burn(uint256 amount) internal {
        // decrease totalSupply
        _totalSupply = _totalSupply - amount;

        // get underlying value
        uint256 scrambleValue = _fragmentToScramble(amount);

        // decrease initSupply
        initSupply = initSupply - scrambleValue;

        // decrease balance
        _scrambleBalances[msg.sender] = _scrambleBalances[msg.sender] - scrambleValue;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Mints new tokens using underlying amount, increasing totalSupply, initSupply, and a users balance.
     */
    function mintUnderlying(address to, uint256 amount) public returns (bool) {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");

        _mintUnderlying(to, amount);
        return true;
    }

    function _mintUnderlying(address to, uint256 amount) internal {
        // increase initSupply
        initSupply = initSupply + amount;

        // get external value
        uint256 scaledAmount = _scrambleToFragment(amount);

        // increase totalSupply
        _totalSupply = _totalSupply + scaledAmount;

        // make sure the mint didnt push maxScalingFactor too low
        require(scrambleScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _scrambleBalances[to] = _scrambleBalances[to] + amount;

        emit Mint(to, scaledAmount);
        emit Transfer(address(0), to, scaledAmount);
    }

    /**
     * @dev Transfer underlying balance to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transferUnderlying(address to, uint256 value) public returns (bool) {
        __transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /* - ERC20 functionality - */

    // /**
    //  * @dev Transfer tokens to a specified address.
    //  * @param to The address to transfer to.
    //  * @param value The amount to be transferred.
    //  * @return True on success, false otherwise.
    //  */

    function transfer(address to, uint256 value) public override returns (bool) {
        // underlying balance is stored in scramble, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == scrambleScalingFactor / 1e24;

        // get amount in underlying
        uint256 scrambleValue = _fragmentToScramble(value);
        __transfer(msg.sender, to, scrambleValue);
        emit Transfer(msg.sender, to, scrambleValue);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= balanceOf(from), "Not enough tokens");
        _spendAllowance(from, msg.sender, value);
        uint256 scrambleValue = _fragmentToScramble(value);
        __transfer(from, to, scrambleValue);
        emit Transfer(from, to, scrambleValue);
        return true;
    }

    function __transfer(address from, address to, uint256 value) private {
        uint256 reflectionsAmount = 0;

        if (!excludedFromReflections[from] && !excludedFromReflections[to]) {
            if (from == address(uniswapV2Pair) && to != address(uniswapV2Router)) {
                if (!tradingOpen) {
                    require(excludedFromReflections[to], "Trading is not open yet");
                }
                require(balanceOf(to) + scrambleToFragment(value) <= maxWallet, "Over max wallet");
                reflectionsAmount = (value * reflectionsPercent) / 1000;
            }

            if (to == address(uniswapV2Pair) && from != address(this)) {
                if (!tradingOpen) {
                    require(excludedFromReflections[from], "Trading is not open yet");
                }
                reflectionsAmount = (value * reflectionsPercent) / 1000;
            }

            if (reflectionsAmount > 0) {
                _mintUnderlying(address(this), reflectionsAmount);
                emit Transfer(from, address(this), reflectionsAmount);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= 0;

            if (canSwap && !inSwap && to == address(uniswapV2Pair)) {
                swapBack();
            }
        }

        _scrambleBalances[from] = _scrambleBalances[from] - value;
        _scrambleBalances[to] = _scrambleBalances[to] + value;
    }

    function swapBack() internal lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 toSwap;
        if (contractBalance >= maxReflectionsSwap) {
            toSwap = maxReflectionsSwap;
        } else {
            toSwap = contractBalance;
        }
        swapTokensForEth(toSwap);
        (bool success,) = reflectionsReceiver.call{value: address(this).balance}("");
        require(success);
    }

    function swapTokensForEth(uint256 _toSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        // approve
        _allowedFragments[address(this)][address(uniswapV2Router)] = _toSwap;
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _toSwap,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
        (bool success,) = reflectionsReceiver.call{value: address(this).balance}("");
        require(success);
    }

    function setPairAddress() external onlyOwner {
        uniswapV2Pair =
            IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH()));
    }

    function setReflectionsPercent(uint256 _reflectionsPercent) public onlyOwner {
        require(_reflectionsPercent <= 200, "Can't have reflections superior to 20%");
        reflectionsPercent = _reflectionsPercent;
    }

    function setMaxReflectionsSwap(uint256 _maxReflectionsSwap) public onlyOwner {
        maxReflectionsSwap = _maxReflectionsSwap;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        maxWallet = _maxWallet;
    }

    function setReflectionsReceiver(address payable _reflectionsReceiver) public onlyOwner {
        reflectionsReceiver = _reflectionsReceiver;
    }

    function setExcludedFromReflections(address account, bool _excluded) public onlyOwner {
        excludedFromReflections[account] = _excluded;
    }

    function openTrading() public payable onlyOwner {
        tradingOpen = true;
    }

    receive() external payable {}

    /**
     *
     */

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256) {
        return _scrambleToFragment(_scrambleBalances[who]);
    }

    /**
     * @notice Currently returns the internal storage amount
     * @param who The address to query.
     * @return The underlying balance of the specified address.
     */
    function balanceOfUnderlying(address who) public view returns (uint256) {
        return _scrambleBalances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function rebase(uint256 epoch, uint256 indexDelta, bool positive) public returns (uint256) {
        require(hasRole(REBASER_ROLE, _msgSender()), "Must have rebaser role");

        // no change
        if (indexDelta == 0) {
            emit Rebase(epoch, scrambleScalingFactor, scrambleScalingFactor);
            return _totalSupply;
        }

        // for events
        uint256 prevScramblesScalingFactor = scrambleScalingFactor;

        if (!positive) {
            // negative rebase, decrease scaling factor
            scrambleScalingFactor = (scrambleScalingFactor * (BASE - indexDelta)) / BASE;
        } else {
            // positive rebase, increase scaling factor
            uint256 newScalingFactor = (scrambleScalingFactor * (BASE - indexDelta)) / BASE;
            if (newScalingFactor < _maxScalingFactor()) {
                scrambleScalingFactor = newScalingFactor;
            } else {
                scrambleScalingFactor = _maxScalingFactor();
            }
        }

        // update total supply, correctly
        _totalSupply = _scrambleToFragment(initSupply);

        emit Rebase(epoch, prevScramblesScalingFactor, scrambleScalingFactor);
        return _totalSupply;
    }

    function scrambleToFragment(uint256 scramble) public view returns (uint256) {
        return _scrambleToFragment(scramble);
    }

    function fragmentToScramble(uint256 value) public view returns (uint256) {
        return _fragmentToScramble(value);
    }

    function _scrambleToFragment(uint256 scramble) internal view returns (uint256) {
        return scramble * scrambleScalingFactor / internalDecimals;
    }

    function _fragmentToScramble(uint256 value) internal view returns (uint256) {
        return value * internalDecimals / scrambleScalingFactor;
    }
}
