// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract CRR is ERC20, ERC20Burnable, Ownable {
    uint256 public tokenPrice;
    address public feeAddress;

    error NotEnoughTokensOnContract();
    error NotEnoughNativeSent();
    error WithdrawNativeFailed();
    error NotFeeAddress();

    /// @param initialMintAmount_ How many tokens to mint to this contract for public sale initially.
    constructor(uint256 tokenPrice_, address feeAddress_, uint256 initialMintAmount_, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        tokenPrice = tokenPrice_;
        feeAddress = feeAddress_;
        _mint(address(this), initialMintAmount_);
    }

    /// @dev (floor(amount * tokenPrice / (10**decimals())) + 1) or more wei should be sent along with the call to buy.
    function buyTokens(uint256 amount) external payable {
        if (amount > balanceOf(address(this))) revert NotEnoughTokensOnContract();

        uint256 totalPrice = (amount * tokenPrice / (10**decimals())) + 1;
        if (msg.value < totalPrice) revert NotEnoughNativeSent();

        // Send the tokens
        _transfer(address(this), msg.sender, amount);

        // Send the value to fee address
        (bool success,) = feeAddress.call{value: msg.value}("");
        if (!success) revert WithdrawNativeFailed();
    }

    /* Owner functions */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Allows owner to change the token buy price.
    function changeTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    // Allows owner to change the fee address.
    function changeFeeAddress(address newFeeAddress) external onlyOwner {
        feeAddress = newFeeAddress;
    }

    // Allows the fee address to withdraw all native currency from the contract to the fee address.
    function withdrawAllNative() external {
        address feeAddr = feeAddress;
        if (msg.sender != feeAddr) revert NotFeeAddress();

        (bool success,) = feeAddr.call{value: address(this).balance}("");
        if (!success) revert WithdrawNativeFailed();
    }

    // Allows owner to withdraw erc20 tokens from the contract.
    function recoverErc20(IERC20 token, uint256 amount) external {
        address feeAddr = feeAddress;
        if (msg.sender != feeAddr) revert NotFeeAddress();

        token.transfer(feeAddr, amount);
    }

    function decimals() public view override returns (uint8) {
        return 9;
    }
}