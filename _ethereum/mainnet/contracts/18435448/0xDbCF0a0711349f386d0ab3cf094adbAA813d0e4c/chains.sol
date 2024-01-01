// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./console.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract CHAINS is ERC20, ReentrancyGuard {
    using Address for address payable;

    mapping(address => bool) public noMaxWalletLimit;
    mapping(address => bool) public isDexPair;

    address private immutable _feeReceiver;
    address private immutable _weth9;
    address private immutable _pair;
    address private _owner;

    IUniswapV2Router02 private immutable _router;

    bool private _trading = false;
    uint8 private _taxFee = 1; 
    uint8 public constant MAX_TAX_FEE = 30; 
    uint256 public maxWalletToken = 20_000_000 * 10 ** decimals();

    event DexPairAdded(address pairAddress);
    event DexPairRemoved(address pairAddress);

    event WalletUpdated(string name, address newAddress);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the contract owner");
        _;
    }

    constructor(
        address feeReceiver_
        , address router_ 
    ) ERC20("Chainswap", "CHAINS") {
         _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
        _feeReceiver = feeReceiver_;
        _router = IUniswapV2Router02(router_);
        _weth9 = _router.WETH();
        _owner = msg.sender;
        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _weth9);

        noMaxWalletLimit[_owner] = true;
    }

    function enableTrading() external {
        _trading = true;
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) internal virtual override {

        if (!noMaxWalletLimit[recipient_]) {
            uint256 newBalance = balanceOf(recipient_) + amount_;
            require(newBalance <= maxWalletToken, "Max wallet amount exceeded.");
        }

        if (sender_ == address(this) || !_trading) {
            super._transfer(sender_, recipient_, amount_);
        } else {
            uint fee = (amount_ * _taxFee) / 100;
            uint amt = amount_ - fee;
            
            super._transfer(sender_, address(this), fee);

            if (sender_ != _pair) {
                _distributeFee();
            }

            super._transfer(sender_, recipient_, amt);
        }
    }

    function setTaxFee(uint8 taxFee) external onlyOwner {
        require(taxFee <= MAX_TAX_FEE, "Tax fee too high");
        _taxFee = taxFee;
    }

    function getTaxFee() external view returns (uint8) {
        return _taxFee;
    }

    function _distributeFee() internal nonReentrant {
        uint amount = balanceOf(address(this));
        if (amount >= 0) {
            _swapTokensForETH(amount);
        }
    } 

    function setNoMaxWalletLimit(
        address account,
        bool value
    ) external onlyOwner {
        noMaxWalletLimit[account] = value;
    }

    function addDexPair(address pairAddress) external onlyOwner {
        require(!isDexPair[pairAddress], "Pair already added");
        isDexPair[pairAddress] = true;
        emit DexPairAdded(pairAddress);
    }

    function removeDexPair(address pairAddress) external onlyOwner {
        require(isDexPair[pairAddress], "Pair not present");
        isDexPair[pairAddress] = false;
        emit DexPairRemoved(pairAddress);
    }

    function _swapTokensForETH(uint256 amount_) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _weth9;
        _approve(address(this), address(_router), amount_);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_,
            0,
            path,
            _feeReceiver,
            block.timestamp
        );
    }
}