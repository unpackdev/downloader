//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint wad) external returns (bool);
}

contract PaymentCall {
    function transfer(bytes calldata paymentData) external payable {
        (
            address wethAddress,
            address paymentReceiver,
            address feeWallet,
            uint256 price,
            uint8 mintFeePct
        ) = abi.decode(
                paymentData,
                (address, address, address, uint256, uint8)
            );

        require(msg.value >= price, "Insufficient purchase ammount");

        uint256 mintFee = (price * mintFeePct) / 100;
        uint256 earned = price - mintFee;
        payable(paymentReceiver).transfer(earned);

        WETH weth = WETH(wethAddress);
        weth.deposit{value: mintFee}();
        weth.transfer(feeWallet, mintFee);

        if (msg.value > earned) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
}
