//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

/// @title A simple stable vault
/// @author @gcosmintech
contract StablesInvestor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public paused;
    mapping(address => bool) public supportedTokens;
    address[] tokens;
    uint256 public cap;

    uint256 private constant _decimals = 18;
    uint256 private _withdrawnTvl;

    event CapChanged(address indexed user, uint256 oldCap, uint256 newCap);
    event AddedNewToken(
        address indexed user,
        address indexed token,
        uint256 timestamp
    );
    event RemovedToken(
        address indexed user,
        address indexed token,
        uint256 timestamp
    );
    event Withdrawn(
        address indexed user,
        address indexed token,
        address indexed destination,
        uint256 timestamp,
        uint256 amount,
        uint256 capAmount
    );
    event Deposit(
        address indexed user,
        address indexed token,
        uint256 timestamp,
        uint256 amount,
        uint256 capAmount
    );

    constructor() {
        cap = 15000000 * (10**_decimals);
        paused = false;
    }

    //
    //---------
    //  Configuration
    //---------
    //

    function pauseDeposit() external onlyOwner {
        paused = true;
    }

    function unpauseDeposit() external onlyOwner {
        paused = false;
    }

    /// @notice Set current strategy cap
    /// @dev Use 18 decimals
    /// @param newCap New cap
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "invalid cap amount");
        emit CapChanged(msg.sender, cap, newCap);
        cap = newCap;
    }

    /// @notice Add a new token in the supported list
    /// @param token Token's address
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "invalid token address");
        require(supportedTokens[token] == false, "token already registered");
        supportedTokens[token] = true;
        tokens.push(token);
        emit AddedNewToken(msg.sender, token, block.timestamp);
    }

    /// @notice Removes an existing token from the supported list
    /// @param token Token's address
    function removeSupportedToken(address token) external onlyOwner {
        require(token != address(0), "invalid token address");
        require(supportedTokens[token] == true, "token not registered");
        supportedTokens[token] = false;
        (uint256 index, bool found) = _find(token);
        if (found == true) {
            _remove(index);
        }
        emit RemovedToken(msg.sender, token, block.timestamp);
    }

    /// @notice Withdraws balance of a specific token
    /// @param token Token's address
    /// @param destination Destination address
    function withdraw(address token, address destination) external onlyOwner {
        uint256 crtBalance = IERC20(token).balanceOf(address(this));
        require(crtBalance > 0, "nothing to withdraw");

        if (destination == address(0)) {
            destination = msg.sender;
        }

        IERC20(token).safeTransfer(destination, crtBalance);

        uint256 capValue = 0;
        if (supportedTokens[token] == true) {
            capValue = _getCapValue(token, crtBalance);
            _withdrawnTvl = _withdrawnTvl + capValue;
        }

        emit Withdrawn(
            msg.sender,
            token,
            destination,
            block.timestamp,
            crtBalance,
            capValue
        );
    }

    //
    //---------
    //  Getters
    //---------
    //

    /// @notice Get total strategy TVL
    /// @return Total TVL (current + withdrawn)
    function getTotalTVL() public view returns (uint256) {
        return _getCurrentBalance() + _withdrawnTvl;
    }

    /// @notice Get current strategy TVL
    /// @return Current TVL
    function getCurrentTVL() public view returns (uint256) {
        return _getCurrentBalance();
    }

    /// @notice Get withdrawn TVL
    /// @return Withdrawn TVL
    function getWithdrawnTVL() public view returns (uint256) {
        return _withdrawnTvl;
    }

    //
    //---------
    //  Interactions
    //---------
    //

    function deposit(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "amount not valid");
        require(supportedTokens[token] == true, "token not registered");
        require(paused == false, "deposits are paused");

        uint256 capValue = _getCapValue(token, amount);
        require(getTotalTVL() + capValue <= cap, "amount exceeds cap");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, token, block.timestamp, amount, capValue);
    }

    //
    //---------
    //  Helpers
    //---------
    //
    function _getCurrentBalance() private view returns (uint256) {
        uint256 balance = 0;
        if (tokens.length == 0) return balance;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (supportedTokens[tokens[i]] == true) {
                uint256 tokenBalance = _getCapValue(
                    tokens[i],
                    IERC20(tokens[i]).balanceOf(address(this))
                );

                balance = balance + tokenBalance;
            }
        }
        return balance;
    }

    function _getCapValue(address token, uint256 amount)
        private
        view
        returns (uint256)
    {
        uint256 capValue = 0;
        uint256 tokenDecimals = ERC20(token).decimals();
        if (tokenDecimals < _decimals) {
            capValue = amount * (10**(_decimals - tokenDecimals));
        } else {
            capValue = amount;
        }

        return capValue;
    }

    function _find(address token) private view returns (uint256, bool) {
        uint256 index = 0;
        bool found = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (token == tokens[i] && found == false) {
                index = i;
                found = true;
            }
        }
        return (index, found);
    }

    function _remove(uint256 index) private {
        if (index >= tokens.length) return;

        for (uint256 i = index; i < tokens.length - 1; i++) {
            tokens[i] = tokens[i + 1];
        }
        tokens.pop();
    }
}
