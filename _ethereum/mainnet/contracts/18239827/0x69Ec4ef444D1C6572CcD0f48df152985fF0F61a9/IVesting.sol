// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IVesting {

    event RegisterUser(uint256 totalTokens, address userAddress, uint8 choice);
    
    event ClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        uint32 timestamp,
        uint8 claimCount,
        uint8 choice
    );

    function registerUserByICO(
        uint256 _amount,
        uint8 _choice,
        address _to
    ) external returns (bool);
}
