// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Counters.sol";
import "./Ownable.sol";

import "./ERC721U.sol";
import "./Types.sol";

/*
   __           _      _        ___ _                __ _                 
  / /  __ _ ___| | ___( )__    / _ (_)__________ _  / _\ |__   ___  _ __  
 / /  / _` |_  / |/ _ \/ __|  / /_)/ |_  /_  / _` | \ \| '_ \ / _ \| '_ \ 
/ /__| (_| |/ /| | (_) \__ \ / ___/| |/ / / / (_| | _\ \ | | | (_) | |_) |
\____/\__,_/___|_|\___/|___/ \/    |_/___/___\__,_| \__/_| |_|\___/| .__/ 
                                                                   |_|    

LazlosPizzas is an ERC721 implementation for baking pizza's out of Lazlo's kitchen.
*/
contract LazlosPizzas is ERC721U, Ownable {
    using Counters for Counters.Counter;

    modifier onlyPizzaShop() {
        require(msg.sender == pizzaShopContractAddress, 'Only the pizza shop can call this method.');
        _;
    }

    address public pizzaShopContractAddress;
    address public renderingContractAddress;

    Counters.Counter public numPizzas;
    mapping(uint256 => Pizza) pizzas;

    constructor() ERC721U("Lazlo's Pizza", "LAZLO") {}

    function setPizzaShopContractAddress(address addr) public onlyOwner {
        pizzaShopContractAddress = addr;
    }

    function setRenderingContractAddress(address addr) public onlyOwner {
        renderingContractAddress = addr;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return ILazlosRendering(renderingContractAddress).pizzaTokenMetadata(id);
    }

    function bake(address baker, Pizza memory pizzaData) external onlyPizzaShop returns (uint256) {
        numPizzas.increment();
        uint256 tokenId = numPizzas.current();
        pizzas[tokenId] = pizzaData;

        _safeMint(baker, tokenId);

        return tokenId;
    }

    function rebake(address baker, uint256 pizzaTokenId, Pizza memory pizzaData) external onlyPizzaShop {
        require(baker == ownerOf[pizzaTokenId], "Baker doesn't own this pizza.");

        pizzas[pizzaTokenId] = pizzaData;
    }

    function pizza(uint256 tokenId) external view returns (Pizza memory) {
        return pizzas[tokenId];
    }

    function burn(uint256 tokenId) external onlyPizzaShop {
        _burn(tokenId);
    }
}
