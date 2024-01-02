// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <=0.8.19;

import "./ReentrancyGuard.sol";

import "./FixedPointMathLib.sol";
import "./SafeTransferLib.sol";
import "./Ownable.sol";

import "./ERC20.sol";

import "./IUSYCAggregator.sol";

contract wUSYC is Ownable, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    IUSYCAggregator public oracle;
    ERC20 public immutable token;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public supply;

    //The compiler won't let you use immutable here cause its a "non-value type"
    string public name;
    string public symbol;

    //decimals
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    //INSERT - Set proper values for the constructor for ERC20
    constructor(address _token, address _oracle, address govController) Ownable(govController) {
        token = ERC20(_token);
        oracle = IUSYCAggregator(_oracle);
        decimals = 6;

        name = "Wrapped_USYC";
        symbol = "wUSYC";
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = IUSYCAggregator(_oracle);
    }

    function balanceOf(address _account) public view returns (uint256) {
        return scaleUp(balances[_account]);
    }

    function mint(address to, uint256 amount) external nonReentrant returns (uint256) {
        require(amount > 0, "Cannot mint 0 tokens");

        token.safeTransferFrom(msg.sender, address(this), amount);

        _mint(to, amount);

        return scaleUp(amount);
    }

    function burn(address from, uint256 amount) external nonReentrant returns (uint256) {
        require(from == msg.sender, "cannot burn shares you do not own");

        uint256 tokenReturned = scaleDown(amount);

        supply -= tokenReturned;
        balances[from] -= tokenReturned;

        token.safeTransfer(msg.sender, tokenReturned);

        emit Transfer(from, address(0), amount);

        return tokenReturned;
    }

    function _mint(address to, uint256 amount) internal {
        supply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint value.
        unchecked {
            balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        uint256 scaledDownShares = scaleDown(amount);

        balances[msg.sender] -= scaledDownShares;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint value.
        unchecked {
            balances[to] += scaledDownShares;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        uint256 scaledDownShares = scaleDown(amount);

        balances[from] -= scaledDownShares;

        unchecked {
            balances[to] += scaledDownShares;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function totalSupply() public view returns (uint256) {
        return scaleUp(supply);
    }

    function scaleUp(uint256 amount) public view returns (uint256) {
        int256 rate;
        (, rate,,,) = oracle.latestRoundData();

        return supply == 0 ? 0 : amount.mulDivDown(uint256(rate), 1e8);
    }

    function scaleDown(uint256 amount) public view returns (uint256) {
        int256 rate;
        (, rate,,,) = oracle.latestRoundData();

        return amount.mulDivUp(1e8, uint256(rate));
    }
}