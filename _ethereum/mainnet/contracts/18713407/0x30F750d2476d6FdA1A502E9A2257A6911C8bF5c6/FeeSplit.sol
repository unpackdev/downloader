pragma solidity 0.8.18;
//SPDX-License-Identifier: MIT

contract FeeSplit {

    address public admin;
    address public wallet_1;
    address public wallet_2;

    error NotAuthorized();
    error NoBalance();

    modifier onlyAuth() {
        if(msg.sender != wallet_1 && msg.sender != wallet_2 && msg.sender != admin){
            revert NotAuthorized();
        }
        _;
    }

    constructor(address _wallet_1, address _wallet_2){
        wallet_1 = _wallet_1;
        wallet_2 = _wallet_2;
        admin = msg.sender;
    }
    
    receive() external payable{}

    function claim() external onlyAuth{
        uint256 nativeBalance = address(this).balance;
        uint256 amount_1 = nativeBalance * 60 / 100;
        uint256 amount_2 = nativeBalance - amount_1;
        payable(wallet_1).call{value: amount_1}("");
        payable(wallet_2).call{value: amount_2}("");
    }

    function claimErc20(address tokenAddr, uint256 amount) external onlyAuth{
        uint256 amount_1 = amount * 60 / 100;
        uint256 amount_2 = amount - amount_1;
        tokenAddr.call(abi.encodeWithSignature("transfer(address,uint256)", wallet_1, amount_1));
        tokenAddr.call(abi.encodeWithSignature("transfer(address,uint256)", wallet_2, amount_2));
    }


    function setWallet_1(address newWallet) external{
        if(msg.sender != admin) revert NotAuthorized();
        wallet_1 = newWallet;
    }

    function setWallet_2(address newWallet) external{
        if(msg.sender != admin) revert NotAuthorized();
        wallet_2 = newWallet;
    }
}