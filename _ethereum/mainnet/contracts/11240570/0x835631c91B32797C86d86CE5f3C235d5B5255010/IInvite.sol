pragma solidity ^0.6.0;

interface IInvite{
    /**
        validate the invite code when user trigger pull
     */
    function validCode(address user) external;

    /**
        calculate the valid users the inviter invite
     */
    function calValidNum(address user) external view returns(uint256);

        /**
        calculate the valid users the inviter invite
     */
    function calValidNum2(address user) external view returns(uint256);

    /**
        calculate the total ratio of stake claim
     */
    function calRatioUpdate(address user) external view returns(uint256);

    /**
        generate an invite code when user trigger pull
     */
    function generateCode(address user) external;
}