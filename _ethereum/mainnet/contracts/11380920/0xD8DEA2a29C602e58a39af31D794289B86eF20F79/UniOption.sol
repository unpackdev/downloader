// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

// Main collectible contract, wrapping NFT-compatible options

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IOptionChef.sol";

contract UniOption is ERC721, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    //storage
    IOptionChef public optionChef;

    constructor(IOptionChef _optionChef, string memory _base) ERC721("UniOption", "UOPT") public {
        optionChef = _optionChef;
        transferOwnership(address(_optionChef));
        _setBaseURI(_base);
    }

    /**
     * @notice Mint shiny UniOption, Chef only
     * @param _to Beneficiary
     */
    function mintUniOption(address _to) public onlyOwner returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        //meta will be automatically set to BASE_URL/newItemId
        // _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    /**

     * @notice Burn option shell, Chef only
     * @notice Might be removed in favour of off-chain metadata-based deprecation
     * @param _id Token ID
     */
    function burnUniOption(uint _id) public onlyOwner {
        _burn(_id);
    }

    /**
     * @notice Overcoming Hegic absence of approval mechanism to mint in one tx
     * @notice Lock token transfers unless (un)wrapping
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(optionChef.isDelegated(_tokenId) || _from == address(0) || _to == address(0), "UOPT:ownership/deleg");
    }

}
