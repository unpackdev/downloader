// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";

import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens

abstract contract BaseRoyalties is ERC165, IERC2981Royalties {

    struct RoyaltyInfo {
        address recipient;
        uint256 amount;
    }

    RoyaltyInfo private _royalties;

    ///@dev set Token Royalties
    ///@param recipient of the royalties
    ///@param value percentage (using 2 decimals. 10000 = 100%)

    function _setRoyalties(address recipient, uint256 value) internal {
        require(value < 10001, "ERC2981Rotalties, too high");
        _royalties = RoyaltyInfo(recipient, value);
    }

    ///@inheritdoc IERC2981Royalties
    function royaltyInfo(uint256 _tokenId, uint256 _value) external view override
        returns (address receiver, uint256 royaltyAmount){

        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (_value * royalties.amount) / 10000;
    }

    ///@inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        
        return
            interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }
}