// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./ATokenInterface.sol";
import "./PEther.sol";
import "./PERC20.sol";

contract ATokenMigrator {
    address public breeder;
    uint256 public notBeforeBlock;
    address payable targetToken;

    constructor (address _breeder, uint256 _notBeforeBlock, address payable _targetToken) public {
        breeder = _breeder;
        notBeforeBlock = _notBeforeBlock;
        targetToken = _targetToken;
    }


    function replaceMigrate(ATokenInterface oldLpToken) external payable returns (PToken, uint){

        uint mintBal = 0;

        require(msg.sender == breeder, "not from breeder");
        require(block.number >= notBeforeBlock, "too early to migrate");

        address sender = msg.sender;
        uint256 lp = oldLpToken.balanceOf(sender);

        require(lp > 0, "balance must bigger than 0");

        // 从aToken中赎回相应的代币
        oldLpToken.transferFrom(sender, address(this), lp);
        oldLpToken.redeem(lp);

        address underlyingAssetAddress = oldLpToken.underlyingAssetAddress();
        if (underlyingAssetAddress == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {

            address self = address(this);
            address sender = msg.sender;
            uint256 lp = oldLpToken.balanceOf(sender);

            PEther newLpToken = PEther(targetToken);
            if (lp == 0) {
                return (newLpToken, 0);
            }

            // 从cToken中赎回相应的代币
            oldLpToken.transferFrom(sender, self, lp);
            oldLpToken.redeem(lp);

            //获得赎回了多少代币
            uint redeemBal = self.balance;

            // 将赎回的代币，抵押到wePiggy中，生成pToken
            newLpToken.mintForMigrate.value(redeemBal)(lp);

            // 获得抵押生成的pToken有多少
            uint mintBal = newLpToken.balanceOf(self);

            //将余额转到挖矿合约
            newLpToken.transferFrom(self, sender, mintBal);

            //返回占比
            return (newLpToken, mintBal);

        } else {

            PERC20 newLpToken = PERC20(targetToken);
            require(underlyingAssetAddress == newLpToken.underlying(), "not match");

            address sender = msg.sender;
            uint256 lp = oldLpToken.balanceOf(sender);

            if (lp == 0) {
                return (newLpToken, 0);
            }

            // 从cToken中赎回相应的代币
            oldLpToken.transferFrom(sender, address(this), lp);
            oldLpToken.redeem(lp);

            //获得赎回了多少代币
            uint redeemBal = 0;
            IERC20 token = IERC20(underlyingAssetAddress);
            redeemBal = token.balanceOf(address(this));

            // 将赎回的代币，抵押到wePiggy中，生成pToken
            token.approve(address(newLpToken), redeemBal);
            newLpToken.mintForMigrate(redeemBal, lp);

            // 获得抵押生成的pToken有多少
            uint mintBal = newLpToken.balanceOf(address(this));

            //将余额转到挖矿合约
            newLpToken.transferFrom(address(this), sender, mintBal);

            return (newLpToken, mintBal);
        }

    }


    function migrate(ATokenInterface oldLpToken) external payable returns (PToken, uint){

        uint mintBal = 0;

        require(msg.sender == breeder, "not from breeder");
        require(block.number >= notBeforeBlock, "too early to migrate");

        address sender = msg.sender;
        uint256 lp = oldLpToken.balanceOf(sender);

        require(lp > 0, "balance must bigger than 0");

        // 从aToken中赎回相应的代币
        oldLpToken.transferFrom(sender, address(this), lp);
        oldLpToken.redeem(lp);

        address underlyingAssetAddress = oldLpToken.underlyingAssetAddress();
        if (underlyingAssetAddress == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {

            address self = address(this);
            address sender = msg.sender;
            uint256 lp = oldLpToken.balanceOf(sender);

            PEther newLpToken = PEther(targetToken);
            if (lp == 0) {
                return (newLpToken, 0);
            }

            // 从cToken中赎回相应的代币
            oldLpToken.transferFrom(sender, self, lp);
            oldLpToken.redeem(lp);

            //获得赎回了多少代币
            uint redeemBal = self.balance;

            // 将赎回的代币，抵押到wePiggy中，生成pToken
            newLpToken.mint.value(redeemBal)();

            // 获得抵押生成的pToken有多少
            uint mintBal = newLpToken.balanceOf(self);

            //将余额转到挖矿合约
            newLpToken.transferFrom(self, sender, mintBal);

            //返回占比
            return (newLpToken, mintBal);

        } else {

            PERC20 newLpToken = PERC20(targetToken);
            require(underlyingAssetAddress == newLpToken.underlying(), "not match");

            address sender = msg.sender;
            uint256 lp = oldLpToken.balanceOf(sender);

            if (lp == 0) {
                return (newLpToken, 0);
            }

            // 从cToken中赎回相应的代币
            oldLpToken.transferFrom(sender, address(this), lp);
            oldLpToken.redeem(lp);

            //获得赎回了多少代币
            uint redeemBal = 0;
            IERC20 token = IERC20(underlyingAssetAddress);
            redeemBal = token.balanceOf(address(this));

            // 将赎回的代币，抵押到wePiggy中，生成pToken
            token.approve(address(newLpToken), redeemBal);
            newLpToken.mint(redeemBal);

            // 获得抵押生成的pToken有多少
            uint mintBal = newLpToken.balanceOf(address(this));

            //将余额转到挖矿合约
            newLpToken.transferFrom(address(this), sender, mintBal);

            return (newLpToken, mintBal);
        }

    }

    receive() external payable {
    }

}
