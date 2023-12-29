// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

/// @title ARK 21Shares Bitcoin ETF Token
/// @dev ERC20 Token with trading control and dynamic tax rate for the first 5 minutes after trading opens.
/// Tax is distributed to the treasury address.
contract ARKBToken is ERC20, Ownable {
    /// @notice Indicates if trading is open
    bool public isTradingOpen = false;

    /// @notice Timestamp when trading was opened
    uint256 private tradingOpenTime;

    /// @notice Address of the treasury
    address public treasuryAddress;

    /// @notice Address used for marketing purposes
    address public marketingAddress;

    /// @notice WETH Address for Uniswap trading
    address public wethAddress;

    /// @notice UniswapV2 Router for trading
    IUniswapV2Router02 public uniswapRouter;

    /// @notice Uniswap Pair for this token and WETH
    address public uniswapPair;

    /// @notice Maximum supply of the token
    uint256 public constant MAX_SUPPLY = 10_000_000_000 * 10 ** 18;

    /// @notice Default tax percentage after first 5 minutes of trading
    uint256 private constant TAX_PERCENTAGE = 1;

    /// @notice High tax percentage for the first 5 minutes of trading
    uint256 private constant HIGH_TAX_PERCENTAGE = 99;

    /// @notice Mapping to keep track of addresses excluded from tax
    mapping(address => bool) private isExcludedFromFee;

    /// @notice Mapping to track blacklisted addresses
    mapping(address => bool) public isBlacklisted;

    /// @dev Constructor sets initial token distribution and Uniswap pair
    /// @param _uniswapRouterAddress Address of the UniswapV2 Router
    /// @param _treasuryAddress Address for the treasury
    /// @param _marketingAddress Address for marketing
    /// @param _WETHAddress Address of WETH token
    constructor(
        address _uniswapRouterAddress,
        address _treasuryAddress,
        address _marketingAddress,
        address _WETHAddress
    ) ERC20("ARK 21Shares Bitcoin ETF", "ARKB") {
        treasuryAddress = _treasuryAddress;
        marketingAddress = _marketingAddress;
        wethAddress = _WETHAddress;

        // 94% to the owner for liquidity
        uint256 initialSupply = (MAX_SUPPLY * 94) / 100;
        _mint(msg.sender, initialSupply);

        // 6% to the marketing address
        uint256 marketingSupply = MAX_SUPPLY - initialSupply;
        _mint(marketingAddress, marketingSupply);

        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
            address(this),
            _WETHAddress
        );

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_uniswapRouterAddress] = true;
        isExcludedFromFee[treasuryAddress] = true;
    }

    /// @dev Overrides the _transfer function to include tax and trading control logic
    /// @param from Sender address
    /// @param to Recipient address
    /// @param value Amount of tokens to transfer
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(from != address(0), "Cannot transfer from 0 wallet");
        if (!isTradingOpen) {
            require(isExcludedFromFee[from], "Trading not yet open");
        }

        require(!isBlacklisted[from], "Sender is blacklisted");
        require(!isBlacklisted[to], "Recipient is blacklisted");

        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            super._transfer(from, to, value);
        } else {
            uint256 tax = 0;
            uint256 taxPercentage = (block.timestamp < (tradingOpenTime + 5 minutes))
                ? HIGH_TAX_PERCENTAGE
                : TAX_PERCENTAGE;

            if (to == uniswapPair || from == uniswapPair) {
                // Apply tax on buy and sell transactions
                tax = (value * taxPercentage) / 100;
                uint256 taxedValue = value - tax;
                super._transfer(from, treasuryAddress, tax);
                super._transfer(from, to, taxedValue);
            } else {
                super._transfer(from, to, value);
            }
        }
    }

    /// @dev Allows the owner to open trading
    function openTrading() external onlyOwner {
        isTradingOpen = true;
        tradingOpenTime = block.timestamp;
    }

    /// @dev Allows the owner to set a new treasury address
    /// @param _newTreasuryAddress New treasury address
    function setTreasuryAddress(
        address _newTreasuryAddress
    ) external onlyOwner {
        treasuryAddress = _newTreasuryAddress;
    }

    /// @dev Allows the owner to withdraw all tokens and ETH from the contract
    /// @param _to Address where the assets are withdrawn to
    function withdrawAll(address _to) external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        transfer(_to, contractBalance);

        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        require(success, "Transfer ETH failed");
    }

    /// @dev Allows the owner to blacklist a specific address
    /// @param _address Address to be blacklisted
    /// @param _value True to blacklist, false to remove from blacklist
    function blacklistAddress(
        address _address,
        bool _value
    ) external onlyOwner {
        isBlacklisted[_address] = _value;
    }

    /// @dev Allows the owner to blacklist multiple addresses
    /// @param _addresses Array of addresses to be blacklisted
    /// @param _value True to blacklist, false to remove from blacklist
    function blacklistAddresses(
        address[] memory _addresses,
        bool _value
    ) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            isBlacklisted[_addresses[i]] = _value;
        }
    }

    /// @dev Contract must be able to receive ETH
    receive() external payable {}
}
