// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./OwnablePausable.sol";
import "./IDepositaryBalanceView.sol";
import "./Issuer.sol";

contract BuybackDepositaryBalanceView is IDepositaryBalanceView, OwnablePausable {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @notice Balance decimals.
    uint256 public override constant decimals = 18;

    /// @notice Address of product token.
    ERC20 public immutable product;

    /// @notice Address of issuer contract.
    Issuer public issuer;

    /// @notice An event that is emitted when an issuer contract address changed.
    event IssuerChanged(address newIssuer);

    /// @notice An event that is emitted when an account buyback stable token.
    event Buyback(address indexed customer, uint256 amount, uint256 buy);

    /**
     * @param _issuer Issuer contract address.
     * @param _product Product token address.
     */
    constructor(address _issuer, address _product) public {
        require(ERC20(_product).decimals() <= decimals, "BuybackDepositaryBalanceView::constructor: invalid decimals of product token");

        issuer = Issuer(_issuer);
        product = ERC20(_product);
    }

    /**
     * @notice Change issuer contract address.
     * @param _issuer New issuer contract address.
     */
    function changeIssuer(address _issuer) external onlyOwner {
        require(_issuer != address(0), "BuybackDepositaryBalanceView::changeIssuer: invalid issuer address");

        issuer = Issuer(_issuer);
        emit IssuerChanged(_issuer);
    }

    /**
     * @dev Transfer token to recipient.
     * @param token Transferred token.
     * @param recipient Address of recipient.
     * @param amount Amount of transferred token.
     */
    function _transfer(
        ERC20 token,
        address recipient,
        uint256 amount
    ) internal {
        require(recipient != address(0), "BuybackDepositaryBalanceView::_transfer: cannot transfer to the zero address");

        token.safeTransfer(recipient, amount);
    }

    /**
     * @notice Transfer product token.
     * @param recipient Address of recipient.
     * @param amount Amount of transferred token.
     */
    function transferProductToken(address recipient, uint256 amount) external onlyOwner {
        _transfer(product, recipient, amount);
    }

    /**
     * @notice Transfer stable token.
     * @param recipient Address of recipient.
     * @param amount Amount of transferred token.
     */
    function transferStableToken(address recipient, uint256 amount) external onlyOwner {
        _transfer(ERC20(issuer.stableToken()), recipient, amount);
    }

    /**
     * @notice Buyback stable token.
     * @param amount Amount of payment token.
     */
    function buy(uint256 amount) external whenNotPaused {
        uint256 productAmount = amount.div(10**(decimals.sub(product.decimals())));
        require(productAmount > 0, "BuybackDepositaryBalanceView::buy: invalid product amount");
        require(productAmount <= product.balanceOf(address(this)), "BuybackDepositaryBalanceView::buy: product amount exceeds balance");

        ERC20 stableToken = ERC20(issuer.stableToken());
        stableToken.safeTransferFrom(_msgSender(), address(this), amount);
        product.safeTransfer(_msgSender(), productAmount);

        uint256 stableTotalSupply = stableToken.totalSupply();
        uint256 collateralBalance = issuer.balance();
        if (stableTotalSupply > collateralBalance) {
            uint256 issuerInbalance = stableTotalSupply.sub(collateralBalance);
            uint256 burningAmount = issuerInbalance.min(stableToken.balanceOf(address(this)));
            if (burningAmount > 0) {
                stableToken.safeTransfer(address(issuer), burningAmount);
                issuer.rebalance();
            }
        }

        emit Buyback(_msgSender(), amount, productAmount);
    }

    function balance() external view override returns (uint256) {
        uint256 productBalance = product.balanceOf(address(this));

        return productBalance.mul(10**(decimals.sub(product.decimals())));
    }
}
