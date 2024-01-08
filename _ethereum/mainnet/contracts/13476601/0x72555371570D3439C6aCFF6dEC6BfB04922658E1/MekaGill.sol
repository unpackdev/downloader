//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract MekaGill is Context, ERC20, Ownable, ERC20Permit {

    address public mekaContractAddress;
    uint256 public mekaGillPerTokenId = 10000 * (10**decimals());
    uint256 public mekaTokenIdStart = 1;
    uint256 public mekaTokenIdEnd = 8888;
    mapping(uint256 => bool) public claimedByTokenId;

    IERC721Enumerable public mekaContract;
    
    constructor(address _mekaverseAddress) Ownable() ERC20("Meka Gill", "MGILL") ERC20Permit("MGILL")  {
        mekaContractAddress = _mekaverseAddress;
        mekaContract = IERC721Enumerable(mekaContractAddress);
    }

    /// @notice Claim Meka Gill for the specified Meka token id
    /// @param tokenId The tokenId of the Meka NFT
    function claimById(uint256 tokenId) external {
        require(_msgSender() == mekaContract.ownerOf(tokenId), "MUST_OWN_TOKEN_ID");
        _claim(tokenId, _msgSender());
    }

    /// @notice Claim Meka Gill for all tokens owned by the sender
    function claimAllForOwner() external {
        uint256 mekasOwned = mekaContract.balanceOf(_msgSender());
        require(mekasOwned > 0, "NO_MEKAS_OWNED");

        for (uint256 i = 0; i < mekasOwned; i++) {
            _claim(mekaContract.tokenOfOwnerByIndex(_msgSender(), i), _msgSender());
        }
    }

    /// @dev Internal function to mint
    function _claim(uint256 tokenId, address tokenOwner) internal {
        
        require(tokenId >= mekaTokenIdStart && tokenId <= mekaTokenIdEnd, "TOKEN_ID_OUT_OF_RANGE");
        require(!claimedByTokenId[tokenId], "MGILL_CLAIMED_FOR_TOKEN_ID");
        
        claimedByTokenId[tokenId] = true;
        
        _mint(tokenOwner, mekaGillPerTokenId);
    } 
}
