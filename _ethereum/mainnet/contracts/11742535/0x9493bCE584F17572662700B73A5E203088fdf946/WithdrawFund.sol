pragma solidity ^0.5.9;

contract WithdrawFund {
    

    function withdraw() external {
        address payable companyWallet = address(0xc326DF3Bec90f94887d2756E03B51a222F2b0de4);
        uint256 value = address(this).balance;
        companyWallet.transfer(value);
    }
    
    function () external payable{}  
}