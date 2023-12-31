// SPDX-License-Identifier: Mit
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ILandingPage.sol";

contract MLM is Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant VISE_TOKEN_DECIMALS = 10 ** 18;
    uint256 public discountPercentage;

    IERC20 public usdt;
    IERC20 public viseToken;
    ILandingPage public landingPage;

    event EtherWithdrawn(address to, uint256 amount);
    event ERC20Withdrawn(IERC20 token, address to, uint256 amount);
    event BoughtWithUsdt(
        address buyer,
        uint256 usdtAmount,
        uint256 tokenAmount
    );

    /// @dev Initializes the contract with the given parameters.
    /// @param _usdt The address of the USDT token contract.
    constructor(
        address _owner,
        IERC20 _viseToken,
        IERC20 _usdt,
        ILandingPage _landingPage
    ) {
        viseToken = _viseToken;
        usdt = _usdt;
        landingPage = _landingPage;
        discountPercentage = 5;
        _transferOwnership(_owner);
    }

    /// @dev Retrieves the current price of 1 token in USDT (Tether) with a discount applied.
    /// @return The discounted price of 1 token in USDT, represented as a uint256.
    function getPriceInUsdt() public view returns (uint256) {
        // Calculate the discounted price by multiplying the original price with (100 - discountPercentage) / 100.
        return
            (landingPage.getPriceInUsdt() * (100 - discountPercentage)) / 100;
    }

    ///@dev Allows the owner to change the discount percentage for community purchases.
    ///
    ///This function allows the contract owner to adjust the discount percentage within a specified range
    ///(5% to 15%). The discount percentage is used to calculate the discounted prices for community purchases.
    ///
    ///Requirements:
    ///- The caller must be the contract owner.
    ///- The new percentage must be within the valid range (5% to 15%).
    ///
    ///@param _newPercentage The new discount percentage to set.
    ////
    function changeDiscountPercentage(
        uint256 _newPercentage
    ) external onlyOwner {
        require(
            _newPercentage >= 5 && _newPercentage <= 15,
            "Out of range: must be 5-15%"
        );
        discountPercentage = _newPercentage;
    }

    ///@dev Allows a user to buy tokens with USDT for community purposes at a discounted price.
    ///@param _usdtAmount The amount of USDT to spend on tokens.
    ///@dev Requires that the sent USDT amount is equal to or greater than the discounted price.
    function buyWithUsdt(uint256 _usdtAmount) external {
        require(_usdtAmount >= getPriceInUsdt(), "Not paid enough");
        usdt.safeTransferFrom(msg.sender, address(this), _usdtAmount);
        uint256 xTokenAmount = (_usdtAmount * VISE_TOKEN_DECIMALS) /
            getPriceInUsdt();
        viseToken.safeTransfer(msg.sender, xTokenAmount);
        emit BoughtWithUsdt(msg.sender, _usdtAmount, xTokenAmount);
    }

    ///@dev Distributes commissions, including tokens and USDT to the specified address.
    ///@param _to The address to which commissions will be distributed.
    ///@param _tokenAmount The amount of tokens to be minted and sent.
    ///@param _usdtAmount The amount of USDT to be transferred.
    ///@dev Only the contract owner can call this function.
    function distributeCommission(
        address _to,
        uint256 _tokenAmount,
        uint256 _usdtAmount
    ) external onlyOwner {
        if (_tokenAmount > 0) {
            viseToken.safeTransfer(_to, _tokenAmount);
        }
        if (_usdtAmount > 0) {
            usdt.safeTransfer(_to, _usdtAmount);
        }
    }

    /// @dev Allows the owner to withdraw ETH from the contract.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient founds");
        address payable to = payable(msg.sender);
        to.transfer(_amount);
        emit EtherWithdrawn(to, _amount);
    }

    /// @dev Allows the owner to withdraw a specified amount of ERC20 tokens from the contract.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    /// @param _amount The amount of ERC20 tokens to withdraw.
    function withdrawERC20(
        IERC20 _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        _tokenAddress.safeTransfer(msg.sender, _amount);
        emit ERC20Withdrawn(_tokenAddress, msg.sender, _amount);
    }
}
