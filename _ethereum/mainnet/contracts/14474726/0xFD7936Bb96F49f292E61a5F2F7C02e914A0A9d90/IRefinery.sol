// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IRefinery {
    
     struct RefineryInfo {
        uint8 inputType; // raw input typeID
        uint8 outputType; // refined resourse typeID
        uint8 burnRate; // rate of input burn to refined per block
        uint8 refineRate; // rate cut of raw to refined
    }
    
    function getRefineryInfo(uint256 _rid) 
    external 
    view 
    returns(RefineryInfo memory);

    function pendingRefine(uint256 _rid, address _user)
        external
        returns (uint256 refining, uint256 refined);

    function depositRaw(
        uint256 _rid,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function withdrawRaw(uint256 _rid) external;
}
