// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

/// @title Grayscale Bitcoin Trust Token
/// @dev Implements an ERC20 token with features for trading control and a variable tax system during the initial trading period.
/// Revenue generated from the tax is directed to the designated treasury.
contract GBTCToken is ERC20, Ownable {
    /// @notice Status of trading activity
    bool public tradingActive = false;

    /// @notice The moment when trading commenced
    uint256 private tradeStartTime;

    /// @notice Treasury's address for collecting tax
    address public treasuryWallet;

    /// @notice Address allocated for development and marketing
    address public devAndMarketingWallet;

    /// @notice WETH Token address for Uniswap trades
    address public wethTokenAddress;

    /// @notice UniswapV2 Router used for trades
    IUniswapV2Router02 public uniswapV2Router;

    /// @notice UniswapV2 Pair address for this token and WETH
    address public uniswapV2Pair;

    /// @notice Token's capped supply
    uint256 public constant MAX_TOKEN_SUPPLY = 10_000_000_000 * 10 ** 18;

    /// @notice Standard tax rate after initial trading period
    uint256 private constant STANDARD_TAX_RATE = 1;

    /// @notice Elevated tax rate for initial trading period
    uint256 private constant INITIAL_TAX_RATE = 99;

    /// @notice Addresses exempt from paying tax
    mapping(address => bool) private exemptFromTax;

    /// @notice Wallets marked as blacklisted
    mapping(address => bool) public blacklistedWallet;

    /// @dev Sets up the token distribution and the Uniswap pair
    /// @param _router Address of UniswapV2 Router
    /// @param _treasury Address for the treasury
    /// @param _devAndMarketing Address for development and marketing
    /// @param _WETH WETH Token address
    constructor(
        address _router,
        address _treasury,
        address _devAndMarketing,
        address _WETH
    ) ERC20("Grayscale Bitcoin Trust", "GBTC") {
        treasuryWallet = _treasury;
        devAndMarketingWallet = _devAndMarketing;
        wethTokenAddress = _WETH;

        // Assign 94% of total supply to the owner for liquidity provision
        uint256 ownerSupply = (MAX_TOKEN_SUPPLY * 90) / 100;
        _mint(msg.sender, ownerSupply);

        // Assign remaining 6% to marketing wallet
        uint256 marketingAllocation = MAX_TOKEN_SUPPLY - ownerSupply;
        _mint(devAndMarketingWallet, marketingAllocation);

        uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            _WETH
        );

        exemptFromTax[owner()] = true;
        exemptFromTax[address(this)] = true;
        exemptFromTax[_router] = true;
        exemptFromTax[treasuryWallet] = true;
    }

    /// @dev Modifies _transfer to implement tax and trading rules
    /// @param from Origin address
    /// @param to Destination address
    /// @param amount Token amount to transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "Cannot send from zero address");
        if (!tradingActive) {
            require(exemptFromTax[from], "Trading is not activated");
        }

        require(!blacklistedWallet[from], "Origin wallet is blacklisted");
        require(!blacklistedWallet[to], "Destination wallet is blacklisted");

        if (exemptFromTax[from] || exemptFromTax[to]) {
            super._transfer(from, to, amount);
        } else {
            uint256 taxAmount = 0;
            uint256 appliedTaxRate = (block.timestamp <
                (tradeStartTime + 5 minutes))
                ? INITIAL_TAX_RATE
                : STANDARD_TAX_RATE;

            if (to == uniswapV2Pair || from == uniswapV2Pair) {
                // Tax applicable on buy/sell transactions
                taxAmount = (amount * appliedTaxRate) / 100;
                uint256 taxedAmount = amount - taxAmount;
                super._transfer(from, treasuryWallet, taxAmount);
                super._transfer(from, to, taxedAmount);
            } else {
                super._transfer(from, to, amount);
            }
        }
    }

    /// @dev Permit the contract owner to activate trading
    function enableTrade() external onlyOwner {
        tradingActive = true;
        tradeStartTime = block.timestamp;
    }

    /// @dev Allow the owner to update the treasury address
    /// @param _newTreasuryWallet New treasury address
    function updateTreasuryWallet(
        address _newTreasuryWallet
    ) external onlyOwner {
        treasuryWallet = _newTreasuryWallet;
    }

    /// @dev Owner can withdraw all tokens and ETH
    /// @param _destination Address to send assets
    function withdrawEverything(address _destination) external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        transfer(_destination, contractTokenBalance);

        (bool sent, ) = payable(_destination).call{
            value: address(this).balance
        }("");
        require(sent, "ETH transfer failed");
    }

    /// @dev Owner can mark a wallet as blacklisted
    /// @param _wallet Address to blacklist
    /// @param _status Blacklist status
    function blacklistWallet(address _wallet, bool _status) external onlyOwner {
        blacklistedWallet[_wallet] = _status;
    }

    /// @dev Owner can blacklist multiple wallets at once
    /// @param _wallets List of addresses
    /// @param _status Blacklist status
    function blacklistMultipleWallets(
        address[] memory _wallets,
        bool _status
    ) external onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            blacklistedWallet[_wallets[i]] = _status;
        }
    }

    /// @dev Enables the contract to receive ETH
    receive() external payable {}
}
