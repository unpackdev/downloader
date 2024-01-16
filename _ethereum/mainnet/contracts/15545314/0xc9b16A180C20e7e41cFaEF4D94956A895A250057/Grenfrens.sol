//SPDX-License-Identifier: MIT
/*
    Grenfrens
    https://twitter.com/grenfrens

    ######  ### ######  #     #    #          #    ######   #####  
    #     #  #  #     # #     #    #         # #   #     # #     # 
    #     #  #  #     # #     #    #        #   #  #     # #       
    ######   #  ######  #     #    #       #     # ######   #####  
    #        #  #   #   #     #    #       ####### #     #       # 
    #        #  #    #  #     #    #       #     # #     # #     # 
    #       ### #     #  #####     ####### #     # ######   #####  
*/

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./ERC721BurningERC20OnMint.sol";

contract Grenfrens is ERC721BurningERC20OnMint, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint public MAX_SUPPLY = 3000;
    string private _baseURIBackingField;
    string private _contractURIBackingField;


    constructor() ERC721("Grenfrens", "GFS") {
        _baseURIBackingField = "ipfs://QmPwPovDq2R43D3oGSGGneCxgnouAYxE1XB9WXYoKb82qo/";
        _contractURIBackingField = "ipfs://QmPHuQL4FMMjGyc4mAaQY5D1hD8JtTo3PKBeck2zwUgnLH";
    }

    function mint() public nonReentrant returns (uint256) {
        require(totalSupply() < MAX_SUPPLY, 'Fully minted out.');
        uint256 tokenId = _tokenIds.current();
        _mint(address(this), _msgSender(), tokenId);
        _tokenIds.increment();
        return tokenId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIBackingField;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        _baseURIBackingField = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURIBackingField;
    }

    function setContractURI(string memory newURI) external onlyOwner() {
        _contractURIBackingField = newURI;
    }
}