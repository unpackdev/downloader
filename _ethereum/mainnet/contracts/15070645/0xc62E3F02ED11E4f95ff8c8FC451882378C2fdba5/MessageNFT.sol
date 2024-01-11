// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
         ___      ,----.    ,-,--.    ,-,--.   ,---.          _,---.      ,----.         .-._           _,---.  ,--.--------.  
  .-._ .'=.'\  ,-.--` , \ ,-.'-  _\ ,-.'-  _\.--.'  \     _.='.'-,  \  ,-.--` , \       /==/ \  .-._ .-`.' ,  \/==/,  -   , -\ 
 /==/ \|==|  ||==|-  _.-`/==/_ ,_.'/==/_ ,_.'\==\-/\ \   /==.'-     / |==|-  _.-`       |==|, \/ /, /==/_  _.-'\==\.-.  - ,-./ 
 |==|,|  / - ||==|   `.-.\==\  \   \==\  \   /==/-|_\ | /==/ -   .-'  |==|   `.-.       |==|-  \|  /==/-  '..-. `--`\==\- \    
 |==|  \/  , /==/_ ,    / \==\ -\   \==\ -\  \==\,   - \|==|_   /_,-./==/_ ,    /       |==| ,  | -|==|_ ,    /      \==\_ \   
 |==|- ,   _ |==|    .-'  _\==\ ,\  _\==\ ,\ /==/ -   ,||==|  , \_.' )==|    .-'        |==| -   _ |==|   .--'       |==|- |   
 |==| _ /\   |==|_  ,`-._/==/\/ _ |/==/\/ _ /==/-  /\ - \==\-  ,    (|==|_  ,`-._       |==|  /\ , |==|-  |          |==|, |   
 /==/  / / , /==/ ,     /\==\ - , /\==\ - , |==\ _.\=\.-'/==/ _  ,  //==/ ,     /       /==/, | |- /==/   \          /==/ -/   
 `--`./  `--``--`-----``  `--`---'  `--`---' `--`        `--`------' `--`-----``        `--`./  `--`--`---'          `--`--`  
*/

import "./Counters.sol";
import "./ERC721URIStorage.sol";

contract MessageNFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    // State variables
    Counters.Counter private _tokenIds;
    uint256 _tokenSupply = 0;

    constructor()
        ERC721("MessageNFT", "MNFT")
    {}

    function mint(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenSupply += 1;

        return newItemId;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not owner nor approved"
        );

        // We can't use the Counter, cause we would lose track of the next
        // token ID to mint
        _tokenSupply -= 1;

        _burn(tokenId);
    }
}
