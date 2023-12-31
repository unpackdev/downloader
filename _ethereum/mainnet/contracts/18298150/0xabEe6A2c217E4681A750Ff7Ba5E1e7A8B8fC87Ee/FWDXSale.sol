// SPDX-License-Identifier: MIT

/*

███████╗░██╗░░░░░░░██╗██████╗░██╗░░██╗
██╔════╝░██║░░██╗░░██║██╔══██╗╚██╗██╔╝
█████╗░░░╚██╗████╗██╔╝██║░░██║░╚███╔╝░
██╔══╝░░░░████╔═████║░██║░░██║░██╔██╗░
██║░░░░░░░╚██╔╝░╚██╔╝░██████╔╝██╔╝╚██╗
╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚═════╝░╚═╝░░╚═╝

*/

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./TransferHelper.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

contract FWDXSale is ReentrancyGuard, Ownable, Pausable {
    mapping(address => bool) public allowedTokens;
    uint256 public pricePerToken = 15;
    uint256 public constant minPurchaseTokens = 10;
    address public saleToken;
    uint8 public constant decimals = 18;

    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        address payToken,
        uint256 cost
    );
    event PricePerTokenUpdated(uint256 newPrice);
    event FundsWithdrawn(
        address indexed owner,
        address tokenAddress,
        uint256 amount
    );

    constructor() {}

    receive() external payable {
        revert("ETH not allowed");
    }

    function buy(
        uint256 numTokens,
        address payToken
    ) external whenNotPaused nonReentrant {
        require(allowedTokens[payToken], "Buy :: Invalid payment token");
        require(
            numTokens >= minPurchaseTokens && numTokens % 10 == 0,
            "Buy :: Tokens must be at least 10 and in multiples of 10"
        );
        require(
            numTokens <= IERC20(saleToken).balanceOf(address(this)),
            "Buy :: Not enough tokens available"
        );
        uint256 cost = numTokens *
            pricePerToken *
            (10 ** IERC20Extended(payToken).decimals());
        TransferHelper.safeTransferFrom(
            payToken,
            msg.sender,
            address(this),
            cost
        );
        TransferHelper.safeTransfer(
            saleToken,
            msg.sender,
            numTokens * (10 ** decimals)
        );

        emit TokensPurchased(msg.sender, numTokens, payToken, cost);
    }

    function updatePricePerToken(uint256 newPrice) external onlyOwner {
        pricePerToken = newPrice;
        emit PricePerTokenUpdated(newPrice);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(owner(), balance);

        emit FundsWithdrawn(owner(), tokenAddress, balance);
    }

    function updateAllowedTokens(
        address tokenAddress,
        bool status
    ) external onlyOwner {
        require(
            tokenAddress != address(0),
            "UpdateAllowedTokens :: Invalid Address"
        );
        allowedTokens[tokenAddress] = status;
    }

    function setSaleToken(address _saleToken) external onlyOwner {
        require(_saleToken != address(0), "SetSaleToken :: Invalid Address");
        saleToken = _saleToken;
    }

    function getTokensPrice(
        uint256 numTokens,
        address payToken
    ) external view returns (uint256) {
        return
            numTokens *
            pricePerToken *
            (10 ** IERC20Extended(payToken).decimals());
    }
}
