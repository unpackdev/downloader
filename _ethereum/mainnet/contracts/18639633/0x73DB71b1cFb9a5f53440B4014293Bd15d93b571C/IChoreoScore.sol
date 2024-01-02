pragma solidity ^0.8.17;

import "./ChoreoLibraryConfig.sol";

interface IChoreoScore is ChoreoLibraryConfig {
    function renderTokenURI(
        uint256 tokenId,
        ChoreographyParams memory choreoToRender
    ) external view returns (string memory);
}
