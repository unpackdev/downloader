/**
    Website  : https://alphadegenpass.netlify.app
    Telegram : https://t.me/alphadegenpass
    twitter: https://twitter.com/kecoqolo

    🔑 **What is AlphaDegenPass?**
    AlphaDegenPass is not just a pass; it's your golden ticket to the forefront of the crypto market! This is your chance to become part of 
    an exclusive club of investors who gain early access to the hottest projects before they go public. Imagine being ahead of the curve on the 
    next big crypto sensation. That's the power of AlphaDegenPass.

    🌐 **AlphaDegenPass ERC-20 Token: Limited to 1000 Tokens**
    The AlphaDegenPass is not just any pass; it's an exclusive ERC-20 token. There are only 1000 tokens in existence, making it one of the most 
    sought-after assets in the crypto world. This limited supply ensures its exclusivity and rarity. Holders of this token gain access to a world 
    of opportunity.

    🚀 **Early Access to Stealth Launches**
    As an AlphaDegenPass holder, you'll be at the forefront of the crypto market. You will receive exclusive notifications and updates about stealth 
    launches, giving you the chance to buy in before the public even knows about them. Don't miss out on the potential for massive gains that come 
    with early access.

    💼 **Membership Benefits:**
    - Early access to ICOs and token launches.
    - Exclusive insights and analysis from our team of experts.
    - Priority participation in token sales.
    - Direct access to the development teams of upcoming projects.
    - A community of like-minded investors to share knowledge and insights.
    - Rare and limited-edition NFTs for select AlphaDegenPass holders.

    💎 **Exclusive Community**
    This channel is not just about early access; it's about building a community of forward-thinking investors who want to maximize their crypto 
    portfolios. Share your thoughts, learn from others, and be part of something special.

    📜 **How to Obtain AlphaDegenPass**
    The AlphaDegenPass is not available to just anyone. Stay tuned to this channel for updates on how you can acquire one of the 1000 limited tokens. 
    We'll be conducting exclusive giveaways and events, so keep your eyes peeled.

    📣 **Stay Informed**
    Don't miss out on the next big opportunity. Join the *AlphaDegenPass Early Access Hub* today and secure your place at the forefront of the crypto 
    market. Together, we'll ride the waves of success in this exciting and ever-evolving industry. 🌊🚀

**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal returns(bool){
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        return success;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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

contract AlphaDegenPass is ERC20, Ownable {
    using Address for address payable;

    address public uniswapV2Pair;

    uint256 public maxWalletLimit;

    constructor() ERC20("ALPHA DEGEN PASS", "ADP") {

        _mint(msg.sender, 1000 * (10**decimals()));
        maxWalletLimit = 1 * (10**decimals());
    }

    function reedemOtherTokens(address token) external onlyOwner{
        if (token == address(0x0)) {
            payable(owner()).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(owner(), balance);
    }

    function setPair(address _pair) external onlyOwner{
        require(_pair != uniswapV2Pair, "Already set");

        uniswapV2Pair = _pair;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (from != owner() && to != uniswapV2Pair) {
            require(
                amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
            require(
                balanceOf(to) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (from == uniswapV2Pair && to != owner()) {
            require(
                amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
            require(
                balanceOf(to) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        super._transfer(from, to, amount);
    }
}
