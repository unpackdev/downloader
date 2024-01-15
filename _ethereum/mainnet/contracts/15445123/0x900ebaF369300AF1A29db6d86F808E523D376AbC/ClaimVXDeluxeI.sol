pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";

abstract contract ClaimVXDeluxeI is Ownable, IERC721 {
    function claimBearsDeluxe(uint16[] calldata _tokenIds, bool _forfeith) external payable virtual;

    function claimWhitelist(uint256 _amount, uint16 _whitelistedAmount, bytes32[] calldata _merkleProof) external payable virtual;

    function getAllForfeithIds() external view virtual returns (uint16[] memory);
}
