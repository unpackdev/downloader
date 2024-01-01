// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./IERC20Wrapper.sol";

interface IBurnable {
    function burn(uint256 amount) external;
}

interface IMintable {
    function mint(address to, uint256 amount) external;
}

abstract contract ERC20Wrapper is ERC20, IERC20Wrapper {
    IERC20 public immutable override underlying;
    bool public immutable burnMint;

    mapping(address => bool) public isWrapper;
    uint256 public underlyingDeposit;

    error InvalidWrapper();
    error OnlyWrapper();
    error NoReflections();
    error InsufficientDeposit();

    event WrapperSet(address indexed wrapper, bool isWrapper);
    event Deposit(address operator, address from, uint256 amountSent, uint256 amountReceived);
    event Withdraw(address operator, address to, uint256 amount);
    event WithdrawReflections(address operator, address to, uint256 amount);

    constructor(address _underlying, bool _burnMint) {
        underlying = IERC20(_underlying);
        burnMint = _burnMint;
    }

    modifier onlyWrapper() {
        if (!isWrapper[msg.sender]) revert OnlyWrapper();
        _;
    }

    function _setWrapper(address _wrapper, bool _isWrapper) internal {
        if (_wrapper == address(0) || isWrapper[_wrapper] == _isWrapper)
            revert InvalidWrapper();

        isWrapper[_wrapper] = _isWrapper;
        emit WrapperSet(_wrapper, _isWrapper);
    }

    /**
     * @dev Withdraw accumulated reflections, reflections is the amount of underlying
     * tokens, which were not deposited and is not withdrawable.
     * @param to address to send underlying tokens to
     */
    function _withdrawReflections(address to) internal {
        uint256 _reflections = reflections();
        if (_reflections == 0) revert NoReflections();

        underlying.transfer(to, _reflections);
        emit WithdrawReflections(msg.sender, to, _reflections);
    }

    /**
     * @dev Wrap `amount` tokens from `from`, minting deposited amount of this token to sender.
     */
    function deposit(address from, uint256 amount) external override onlyWrapper returns (uint256 deposited) {
        uint256 balance = underlying.balanceOf(address(this));
        underlying.transferFrom(from, address(this), amount);
        deposited = underlying.balanceOf(address(this)) - balance;

        if (burnMint) {
            IBurnable(address(underlying)).burn(deposited);
        } else {
            underlyingDeposit += deposited;
        }

        _mint(msg.sender, deposited);

        emit Deposit(msg.sender, from, amount, deposited);
    }

    /**
     * @dev Unwrap `amount` tokens from sender, burning amount of this token and withdrawing underlying token to `to`.
     */
    function withdraw(address to, uint256 amount) external override onlyWrapper {
        _burn(msg.sender, amount);
        
        if (burnMint) {
            IMintable(address(underlying)).mint(to, amount);
        } else {
            // this indicates a structural error, where more wrapped tokens 
            // were minted outside of this contract's scope
            if (amount > underlyingDeposit) revert InsufficientDeposit();
            underlyingDeposit -= amount;
            underlying.transfer(to, amount);
        }

        emit Withdraw(msg.sender, to, amount);
    }

    /**
     * @notice Get current amount of accumulated reflections.
     * Reflections is the amount of underlying tokens, 
     * which were not deposited and is not withdrawable.
     */
    function reflections() public view returns (uint256) {
        return burnMint ? 0 : underlying.balanceOf(address(this)) - underlyingDeposit;
    }

}
