// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ECDSA.sol";
import "./Counters.sol";
import "./Ownable.sol";

import "./ERC1155U.sol";
import "./Types.sol";

/*
   __           _      _        ___ _                __ _                 
  / /  __ _ ___| | ___( )__    / _ (_)__________ _  / _\ |__   ___  _ __  
 / /  / _` |_  / |/ _ \/ __|  / /_)/ |_  /_  / _` | \ \| '_ \ / _ \| '_ \ 
/ /__| (_| |/ /| | (_) \__ \ / ___/| |/ / / / (_| | _\ \ | | | (_) | |_) |
\____/\__,_/___|_|\___/|___/ \/    |_/___/___\__,_| \__/_| |_|\___/| .__/ 
                                                                   |_|    

LazlosIngredients is an ERC115 implementation for selling ingredients out of Lazlo's kitchen.
*/
contract LazlosIngredients is ERC1155U, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    modifier onlyPizzaShop() {
        require(msg.sender == pizzaShopContractAddress, 'Only the pizza shop can call this method.');
        _;
    }

    modifier onlyPizzaShopOrOwner() {
        require(msg.sender == pizzaShopContractAddress || msg.sender == owner(),
        'Only the pizza shop and owner can call this method.');
        _;
    }

    Counters.Counter public numIngredients;
    mapping(uint256 => Ingredient) public ingredients;
    address public pizzaShopContractAddress;
    address public renderingContractAddress;

    function setPizzaShopContractAddress(address addr) public onlyOwner {
        pizzaShopContractAddress = addr;
    }

    function setRenderingContractAddress(address addr) public onlyOwner {
        renderingContractAddress = addr;
    }

    function getIngredient(uint256 tokenId) external view returns (Ingredient memory) {
        return ingredients[tokenId];
    }

    function addIngredient(Ingredient memory ingredient) public onlyOwner {
        numIngredients.increment();
        uint256 tokenId = numIngredients.current();
        ingredients[tokenId] = ingredient;
    }

    function getNumIngredients() external view returns (uint256) {
        return numIngredients.current();
    }

    function increaseIngredientSupply(uint256 tokenId, uint256 amount) public onlyPizzaShop {
        unchecked {
            ingredients[tokenId].supply += uint256(amount);
        }
    }

    function decreaseIngredientSupply(uint256 tokenId, uint256 amount) public onlyPizzaShop {
        unchecked {
            ingredients[tokenId].supply -= uint256(amount);
        }
    }

    function increaseIngredientTotalSupply(uint256 tokenId, uint256 amount) public onlyOwner {
        ingredients[tokenId].supply += uint256(amount);
        ingredients[tokenId].initialSupply += uint256(amount);
    }

    function decreaseIngredientTotalSupply(uint256 tokenId, uint256 amount) public onlyOwner {
        ingredients[tokenId].supply -= uint256(amount);
        ingredients[tokenId].initialSupply -= uint256(amount);
    }

    function mintIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) public onlyPizzaShop {
        _batchMint(addr, tokenIds, amounts, '');
    }

    function burnIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external onlyPizzaShop {
        _batchBurn(addr, tokenIds, amounts);
    }

    function balanceOfAddress(address addr, uint256 tokenId) external view returns (uint256) {
        return balanceOf[addr][tokenId];
    }

    function uri(uint256 id) public view override returns (string memory) {
        return ILazlosRendering(renderingContractAddress).ingredientTokenMetadata(id);
    }
}
