// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProviderAwareOracle.sol";
import "./Ownable.sol";

contract SimpleOracle is ProviderAwareOracle {
    mapping(address => mapping(address => bool)) public tokenAdmins;

    mapping(address => uint256) private _currentPrices;

    event PriceUpdated(address indexed token, uint256 indexed price);
    event AdminStatusApproved(address indexed token, address indexed admin, bool indexed isApproved);

    modifier onlyAdmin(address token) {
        require(msg.sender == owner() || tokenAdmins[token][msg.sender], "Unauthorized!");
        _;
    }

    constructor(address _provider) ProviderAwareOracle(_provider) {}

    function getSafePrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external view returns (uint256 _amountOut) {
        return _currentPrices[token];
    }

    function updatePrice(address token, uint256 price) external onlyAdmin(token) {
        _currentPrices[token] = price;
        emit PriceUpdated(token, price);
    }

    function setAdminStatus(address token, address admin, bool isApproved) external onlyOwner {
        tokenAdmins[token][admin] = isApproved;
        emit AdminStatusApproved(token, admin, isApproved);
    }
}
