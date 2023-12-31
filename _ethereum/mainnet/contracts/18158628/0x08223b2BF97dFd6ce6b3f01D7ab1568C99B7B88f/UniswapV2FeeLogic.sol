// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.8;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

import "./IFeeLogic.sol";

contract UniswapV2FeeLogic is IFeeLogic, Initializable, OwnableUpgradeable {
    IUniswapV2Factory public uniswapV2Factory;
    address public tokenAddress;
    uint256 public feePercentage;

    function initialize(address _uniswapV2Factory, address _tokenAddress) public initializer {
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
        tokenAddress = _tokenAddress;
        feePercentage = 500;
    }

    function shouldApplyFees(address from, address to) external view override returns (bool) {
        if (isUniswapV2Pair(from) || isUniswapV2Pair(to)) {
            return true;
        }
        return false;
    }

    function isUniswapV2Pair(address addr) public view returns (bool) {
        if (!isContract(addr)) {
            return false;
        }
        // Check if the contract at 'addr' implements the IUniswapV2Pair interface
        try IUniswapV2Pair(addr).factory() returns (address) {
            // If the call succeeds, it's a valid Uniswap V2 pair contract
            return true;
        } catch {
            // If the call reverts, it's not a valid Uniswap V2 pair contract
            return false;
        }
    }

    function isContract(address _addr) internal view returns (bool) {
        return _addr.code.length > 0;
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Invalid fee percentage");
        feePercentage = _feePercentage;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
}