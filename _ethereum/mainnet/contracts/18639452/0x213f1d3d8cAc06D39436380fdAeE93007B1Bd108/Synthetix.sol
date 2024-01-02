pragma solidity ^0.8.20;

interface Synthetix {
    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );
    
    function collateralisationRatio(address issuer) external view returns (uint);

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;
    function burnSynthsToTarget() external;
}