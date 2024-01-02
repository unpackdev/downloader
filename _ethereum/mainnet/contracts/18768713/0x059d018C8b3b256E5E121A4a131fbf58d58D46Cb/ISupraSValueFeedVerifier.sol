pragma solidity ^0.8.19;


interface  ISupraSValueFeedVerifier {

    function isPairAlreadyAddedForHCC(uint256[] calldata _pairIndexes)
        external
        view
        returns (bool);

    function isPairAlreadyAddedForHCC(uint256 _pairId)
        external
        view
        returns (bool);

    function requireHashVerified(bytes memory message, uint256[2] memory signature) 
        external
        view ;
}