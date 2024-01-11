// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721Enumerable.sol";

contract LightbulbmanClaims {
    IERC721Enumerable immutable private token;
    uint256 immutable private claimLimit;
    mapping(uint256 => address) private claims;

    event ClaimAdded(address _user, uint256 _tokenId);

    constructor(IERC721Enumerable _token, uint256 _claimLimit) {
        token = _token;
        claimLimit = _claimLimit;
    }

    function addClaim(uint256[] calldata _tokenIds) external {
        require(_tokenIds.length <= claimLimit, "LBM list size exceeds the limit");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            try token.ownerOf(_tokenIds[i]) returns (address owner) {
                require(msg.sender == owner, "Not the owner of this LBM");
                require(claims[_tokenIds[i]] == address(0), "This LBM has already been claimed");
                claims[_tokenIds[i]] = msg.sender;
                emit ClaimAdded(msg.sender, _tokenIds[i]);
            }
            catch {
                revert("This LBM does not exist or has no owner");
            }
        }
    }

    function isClaimable(uint256 _tokenId) external view returns (bool) {
        return claims[_tokenId] == address(0);
    }

    function isTokenOwner(uint256 _tokenId) external view returns (bool) {
        try token.ownerOf(_tokenId) returns (address owner) {
           return msg.sender == owner; 
        }
        catch {
            return false;
        }
    }
}
