// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IAssetManager.sol";
import "./ITwapOraclePriceFeed.sol";
import "./TribeOneHelper.sol";

contract AssetManager is Ownable, ReentrancyGuard, IAssetManager {
    event AddAvailableLoanAsset(address _sender, address _asset);
    event SetLoanTwapOracle(address _asset, address _twap);
    event RemoveAvailableLoanAsset(address _sender, address _asset);
    event AddAvailableCollateralAsset(address _sender, address _asset);
    event RemoveAvailableCollateralAsset(address _sender, address _asset);
    event SetConsumer(address _setter, address _consumer);
    event SetAutomaticLoanLimit(address _setter, uint256 _oldLimit, uint256 _newLimit);
    event TransferAsset(address indexed _requester, address _to, address _token, uint256 _amount);
    event WithdrawAsset(address indexed _to, address _token, uint256 _amount);
    event SetTwapOracle(address indexed _asset, address _twap, address _user);

    mapping(address => bool) private availableLoanAsset;
    mapping(address => bool) private availableCollateralAsset;
    address private _consumer;
    uint256 public automaticLoanLimit = 200; // For now we allows NFTs only below 200 usd price

    address public immutable WETH; // This should be uniswap WETH address
    address public immutable USDC; // This should be uniswap USDC address
    mapping(address => address) private twapOracles; // loanAsset => twapOracle

    constructor(address _WETH, address _USDC) {
        require(_WETH != address(0) && _USDC != address(0), "AssetManager: ZERO address");
        // Adding Native coins
        availableCollateralAsset[address(0)] = true;
        availableLoanAsset[address(0)] = true;
        WETH = _WETH;
        USDC = _USDC;
    }

    receive() external payable {}

    modifier onlyConsumer() {
        require(msg.sender == _consumer, "Not consumer");
        _;
    }

    function consumer() external view returns (address) {
        return _consumer;
    }

    function priceOracle(address asset) external view returns (address) {
        return twapOracles[asset];
    }

    function addAvailableLoanAsset(address _asset) external onlyOwner nonReentrant {
        require(!availableLoanAsset[_asset], "Already available");
        availableLoanAsset[_asset] = true;
        emit AddAvailableLoanAsset(msg.sender, _asset);
    }

    function removeAvailableLoanAsset(address _asset) external onlyOwner nonReentrant {
        require(availableLoanAsset[_asset], "Already removed");
        availableLoanAsset[_asset] = false;
        emit RemoveAvailableLoanAsset(msg.sender, _asset);
    }

    function addAvailableCollateralAsset(address _asset) external onlyOwner nonReentrant {
        require(!availableCollateralAsset[_asset], "Already available");
        availableCollateralAsset[_asset] = true;
        emit AddAvailableCollateralAsset(msg.sender, _asset);
    }

    function removeAvailableCollateralAsset(address _asset) external onlyOwner nonReentrant {
        require(availableCollateralAsset[_asset], "Already removed");
        availableCollateralAsset[_asset] = false;
        emit RemoveAvailableCollateralAsset(msg.sender, _asset);
    }

    function isAvailableLoanAsset(address _asset) external view override returns (bool) {
        return availableLoanAsset[_asset];
    }

    function isAvailableCollateralAsset(address _asset) external view override returns (bool) {
        return availableCollateralAsset[_asset];
    }

    function setConsumer(address _consumer_) external onlyOwner {
        require(_consumer_ != _consumer, "Already set as consumer");
        require(_consumer_ != address(0), "ZERO_ADDRESS");
        _consumer = _consumer_;

        emit SetConsumer(msg.sender, _consumer_);
    }

    function setLoanAssetTwapOracle(address _asset, address _twap) external onlyOwner nonReentrant {
        require(availableLoanAsset[_asset], "AssetManager: Invalid loan asset");
        address token0 = ITwapOraclePriceFeed(_twap).token0();
        address token1 = ITwapOraclePriceFeed(_twap).token1();
        if (_asset == address(0)) {
            require((token0 == WETH && token1 == USDC) || (token0 == USDC && token1 == WETH), "AssetManager: Invalid twap");
        } else {
            require((token0 == _asset && token1 == USDC) || (token0 == USDC && token1 == _asset), "AssetManager: Invalid twap");
        }

        twapOracles[_asset] = _twap;
        emit SetTwapOracle(_asset, _twap, msg.sender);
    }

    function setAutomaticLoanLimit(uint256 _newLimit) external onlyOwner {
        require(automaticLoanLimit != _newLimit, "AssetManager: New value is same as old");
        uint256 oldLimit = automaticLoanLimit;
        automaticLoanLimit = _newLimit;
        emit SetAutomaticLoanLimit(msg.sender, oldLimit, _newLimit);
    }

    function isValidAutomaticLoan(address _asset, uint256 _amountIn) external view override returns (bool) {
        require(availableLoanAsset[_asset], "AssetManager: Invalid loan asset");
        uint256 usdcAmount;
        if (_asset == USDC) {
            usdcAmount = _amountIn;
        } else {
            address _twap = twapOracles[_asset];
            require(_twap != address(0), "AssetManager: Twap oracle was not set");

            if (_asset == address(0)) {
                _asset = WETH;
            }
            usdcAmount = ITwapOraclePriceFeed(_twap).consult(_asset, _amountIn);
        }

        return usdcAmount <= automaticLoanLimit * (10**IERC20Metadata(USDC).decimals());
    }

    function requestETH(address _to, uint256 _amount) external override onlyConsumer {
        require(address(this).balance >= _amount, "Asset Manager: Insufficient balance");
        TribeOneHelper.safeTransferETH(_to, _amount);
        emit TransferAsset(msg.sender, _to, address(0), _amount);
    }

    function requestToken(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyConsumer {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Asset Manager: Insufficient balance");
        TribeOneHelper.safeTransfer(_token, _to, _amount);
        emit TransferAsset(msg.sender, _to, _token, _amount);
    }

    function withdrawAsset(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "ZERO Address");
        if (_token == address(0)) {
            _amount = address(this).balance;
            TribeOneHelper.safeTransferETH(msg.sender, _amount);
        } else {
            TribeOneHelper.safeTransfer(_token, msg.sender, _amount);
        }

        emit WithdrawAsset(_to, _token, _amount);
    }

    function collectInstallment(
        address _currency,
        uint256 _amount,
        uint256 _interest,
        bool _collateral
    ) external payable override onlyConsumer {
        if (_currency == address(0)) {
            require(msg.value == _amount, "Wrong msg.value");
        } else {
            TribeOneHelper.safeTransferFrom(_currency, msg.sender, address(this), _amount);
        }
        // We will supplement more detail in V2
        // 80% interest will go to Funding pool rewarder contract, 20% wil be burn
        // If _collateral is true, then we transfer whole amount to funding pool
    }
}
