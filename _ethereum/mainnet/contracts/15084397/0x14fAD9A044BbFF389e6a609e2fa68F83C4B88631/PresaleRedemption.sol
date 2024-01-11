//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";

import "./Ownable.sol";

import "./console.sol";

interface IERC20WithMetadata is IERC20, IERC20Metadata {}

contract PresaleRedemption is Ownable {
    using SafeMath for uint256;

    IERC20WithMetadata public bash;
    IERC20WithMetadata public abash;
    address public presale;

    event Redeemed(address redeemer, uint256 bashAmount, uint256 totalBashLeftToRedeem);

    constructor(address abashAddress, address bashAddress, address presaleContractAddress) {
        require(abashAddress != address(0), "ABASH address");
        require(bashAddress != address(0), "BASH address");
        require(presaleContractAddress != address(0), "Atbash Presale address");

        abash = IERC20WithMetadata(abashAddress);
        bash = IERC20WithMetadata(bashAddress);
        presale = presaleContractAddress;
    }

    // amount in abash decimals
    function redeem(uint256 amount) public {    // todo: 
        require(amount > 0, "Invalid amount");

        // convert into bash decimals
        uint256 bashAmount = amount.mul(10 ** bash.decimals())
                                    .div(10 ** abash.decimals());

        require(bashAmount <= bash.balanceOf(address(this)), "Not enough funds to cover redemption");

        abash.transferFrom(msg.sender, address(this), amount);
        bash.transfer(msg.sender, bashAmount);

        uint256 totalBashLeftRedeemable = bash.balanceOf(address(this));
        emit Redeemed(msg.sender, bashAmount, totalBashLeftRedeemable);
    }

    function remaining() public view returns (uint256 amount) {
        // todo: abash total supply - abash.balanceOf(this.address)
        amount = abash.totalSupply()
                    .sub(abash.balanceOf(presale))
                    .sub(abash.balanceOf(address(this)));
    }

    function removeERC20(address tokenAddress) public onlyOwner {
        require(
            IERC20(tokenAddress).transfer(
                msg.sender,
                IERC20(tokenAddress).balanceOf(address(this))
            ),
            "Failed to remove ERC20"
        );
    }
}
