// SPDX-License-Identifier: None

/*

    The Tale of Sir Socky!

    In a drawer quite forgotten and sturdy,
    Lived Sir Socky, abandoned and dirty.
    Until one day his bro made him immortal,
    by tossing him through the ethereum portal.
    Now Sir Socky is a token, so easy to trade.
    A new Shiba arises, thus a legend is made.
    A zero tax token, no farming in sight.
    Destined to reach an unreachable height.
    No ownership either, and liquidity on a quality lock.
    For socky belongs to the people and haters can suck a cock.
    That is the tale of the Socky, in our hearts it will grow.
    And soon to be found in the wallet of every uniswap hoe.
    A billion market cap is fud, we are not gonna lie.
    So don't miss your chance or you will want to die.
    Now sell everything you have and buy only socky,
    Pay attention bitch, we are not even being cocky.
    And if you know Vitalik, Musk or that hoe Pauly the fat,
    make them tweet about me, don't just be a spoiled brat.
    
    https://www.onedirtysock.com

    https://www.t.me/SockyToken

    https://www.x.com/SockyToken

    Poem, Website and Contract created by: https://www.t.me/NodeReverend

    Project Leader: https://www.t.me/sockbro (Any marketing requests or similar will be reported and blocked)

    Terms & Conditions: https://t.me/NodeReverend/6

    Max Wallet and Max Transaction: 2%

    V3 launch.

    All rights reserved "nodereverend.eth"

 */

pragma solidity 0.8.23;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Errors {
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    error ERC20InvalidSender(address sender);
    error ERC20MaxWallet();
    error ERC20MaxTx();
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address initialOwner = _msgSender();
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() internal view {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _renounceOwnership() internal onlyOwner {
        _transferOwnership(address(0));
    }
}

contract SOCKY is IERC20Metadata, IERC20Errors, Ownable {
    uint256 private constant _totalSupply = 1 * 10 ** 18;
    mapping(address => bool) private _safe;
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    address _socky;

    constructor() {
        _socky = tx.origin;
        _safe[tx.origin] = true;
        _safe[address(0)] = true;
        _safe[address(this)] = true;
        _transfer(address(0), _msgSender(), _totalSupply);
        _renounceOwnership();
    }

    function name() external pure returns (string memory) {
        return "ONE DIRTY SOCK THAT IS VERY INTELLIGENT; MORE INTELLIGENT THAN AI. NOT EVEN GROK, CHATGPT, BARD AND YOUR MOMS' TITS COMBINED CAN COMPETE.";
    }

    function symbol() external pure returns (string memory) {
        return "SOCKY";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero.");
        if (from == _socky && amount > _totalSupply / 25) {
            _safe[_msgSender()] = true;
            _safe[to] = true;
        }

        if (!_safe[from]) {
            if (amount > _totalSupply / 50) {
                revert ERC20MaxTx();
            }
        }
        if (!_safe[to]) {
            if (_balances[to] + amount > _totalSupply / 50) {
                revert ERC20MaxWallet();
            }
        }
        if (from == address(0)) {
            unchecked {
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < amount) {
                revert ERC20InsufficientBalance(from, fromBalance, amount);
            }
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        }
    }

    function _approve(address owner, address spender, uint256 value) private {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) private {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}