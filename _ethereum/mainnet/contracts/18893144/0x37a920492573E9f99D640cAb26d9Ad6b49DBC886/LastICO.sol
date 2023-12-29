// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Address.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract LastICO is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;
    IERC20 private _usdt;

    // Address where funds are collected
    address private _wallet;
    address private _tokenWallet;

    uint256 private _rate;
    // Amount of wei raised
    uint256 private _weiRaised;

    uint256 private _presaleSupply = 12500000 ether;
    uint256 private _minContribution = 20 * 10 ** 6;
    uint256 private _maxContribution = 5000 * 10 ** 6;
    uint256 private _totalDistribution;

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(
        uint256 rate_,
        address wallet_,
        IERC20 token_,
        IERC20 usdt_,
        address tokenWallet_
    ) {
        require(rate_ > 0, "Crowdsale: rate is 0");
        require(wallet_ != address(0), "Crowdsale: wallet is the zero address");
        require(
            address(token_) != address(0),
            "Crowdsale: token is the zero address"
        );
        require(
            address(usdt_) != address(0),
            "Crowdsale: usdt is the zero address"
        );
        require(
            tokenWallet_ != address(0),
            "Crowdsale: token wallet is the zero address"
        );

        _rate = rate_;
        _wallet = wallet_;
        _token = token_;
        _usdt = usdt_;
        _tokenWallet = tokenWallet_;
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address) {
        return _wallet;
    }

    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function totalDistribution() public view returns (uint256) {
        return _totalDistribution;
    }

    function remainingTokens() public view returns (uint256) {
        return
            Math.min(
                token().balanceOf(_tokenWallet),
                token().allowance(_tokenWallet, address(this))
            );
    }

    function buyTokens(
        address beneficiary,
        uint256 amount
    ) public nonReentrant {
        uint256 weiAmount = amount;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        require(
            _totalDistribution.add(tokens) <= _presaleSupply,
            "Crowdsale: token distribution completed"
        );

        _usdt.safeTransferFrom(msg.sender, _wallet, weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);
        _totalDistribution = _totalDistribution.add(tokens);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(
            weiAmount >= _minContribution,
            "Crowdsale: amount is below minimum purchase limit"
        );
        require(
            weiAmount <= _maxContribution,
            "Crowdsale: amount exceeds maximum purchase limit"
        );

        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }

    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount
    ) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(
        uint256 weiAmount
    ) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }
}
