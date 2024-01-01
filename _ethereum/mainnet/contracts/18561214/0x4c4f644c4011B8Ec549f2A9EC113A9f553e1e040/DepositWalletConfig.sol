pragma solidity ^0.8.9;

import "./Ownable.sol";

contract DepositWalletConfig is Ownable {
    address public hotWalletAddress;

    uint256 public whitelistedTokenLength;
    address[] public whitelistedTokens;
    mapping(address => bool) public isWhitelistedTokens;

    event NewHotWalletAddress(address newAddress);

    constructor(
        address hotWalletAddress_
    ) {
        hotWalletAddress = hotWalletAddress_;
    }

    /**
     * @notice Set hot wallet address
     * @param newAddress new hot wallet address
     */
    function setHotWalletAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "invalid address");

        hotWalletAddress = newAddress;

        emit NewHotWalletAddress(newAddress);
    }

    function addWhitelistedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");

        if (isWhitelistedTokens[tokenAddress] == true) {
            return;
        }

        isWhitelistedTokens[tokenAddress] = true;
        whitelistedTokens.push(tokenAddress);
        whitelistedTokenLength++;
    }

    function removeWhitelistedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");

        if (isWhitelistedTokens[tokenAddress] == false) {
            return;
        }

        isWhitelistedTokens[tokenAddress] = false;

        for (uint256 i = 0; i < whitelistedTokens.length; i++) {
            if (whitelistedTokens[i] == tokenAddress) {
                whitelistedTokens[i] = whitelistedTokens[whitelistedTokens.length-1];
                whitelistedTokens.pop();
                whitelistedTokenLength--;
                break;
            }
        }
    }
}