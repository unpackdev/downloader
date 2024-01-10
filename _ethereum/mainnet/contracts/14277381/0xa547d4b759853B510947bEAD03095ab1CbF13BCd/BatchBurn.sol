
pragma solidity 0.8.11;

import "./ARBOArtifacts.sol";

contract BatchBurn { 
    function batchBurn(
        address token,
        address[] calldata recipients,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external {
        for (uint256 i = 0; i < recipients.length; ++i){
            ARBOArtifacts(token).batchBurn(
                recipients[i],
                tokenIds[i],
                amounts[i]
            );
        }
    }
}