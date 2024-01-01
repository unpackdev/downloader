// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IMembership.sol";
import "./console.sol";


contract CoinCircle is ERC20, Ownable {
    uint256 constant private INITIAL_SUPPLY = 120_000 ether;
    uint256 constant private PRICE = 1000;
    uint256 constant private TAX_FEE = 4;

    ERC20 public paymentToken;
    IMembership public membership;

    constructor(address initialSupplyReceiver, ERC20 _paymentToken, IMembership _membership) ERC20("CoinCircle Community Token", "COCC") {
        _mint(initialSupplyReceiver, 120000 * 10 ** decimals());
        paymentToken = _paymentToken;
        membership = _membership;
    }

    function setPaymentToken(ERC20 _paymentToken) external onlyOwner {
        paymentToken = _paymentToken;
    }

    function setMembership(IMembership _membership) external onlyOwner {
        membership = _membership;
    }

    function buyTokens(uint256 membershipId, uint256 amount) external {
        _buyTokens(msg.sender, membershipId, msg.sender, amount);
    }

    function buyTokensTo(address account, uint256 membershipId, uint256 amount) external onlyOwner {
        require(membership.ownerOf(membershipId) == account, "[buyTokensTo]: receiver has no membership");
        _mint(address(this), amount);
        _approve(address(this), address(membership), amount);
        membership.deposit(membershipId, address(this), amount);
    }

    function _buyTokens(address buyer, uint256 membershipId, address receiver, uint256 amount) internal {
        require(membership.ownerOf(membershipId) == receiver, "[_buyTokens]: receiver has no membership");
        uint256 decimalDifference = 10 ** (uint256(decimals()) - uint256(paymentToken.decimals()));

        uint256 price = amount * PRICE / decimalDifference;

        paymentToken.transferFrom(buyer, address(this), price);

        _mint(address(this), amount);
        _approve(address(this), address(membership), amount);
        membership.deposit(membershipId, address(this), amount);
    }

    function withdrawTokens() external onlyOwner {
        paymentToken.transfer(owner(), paymentToken.balanceOf(address(this)));
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);

    }


}