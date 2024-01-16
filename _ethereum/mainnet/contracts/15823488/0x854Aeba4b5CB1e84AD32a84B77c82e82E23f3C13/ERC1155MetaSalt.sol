// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC1155Base.sol";
contract ERC1155MetaSalt is ERC1155Base {        
    function __ERC1155MetaSalt_init(string memory _name, string memory _symbol, string memory baseURI, address _erc20Token, uint256 _erc20CreateRewardValue) external virtual initializer {
        __ERC1155MetaSalt_init_unchained(_name, _symbol, baseURI, _erc20Token, _erc20CreateRewardValue);
    }
    
    function __ERC1155MetaSalt_init_unchained(string memory _name, string memory _symbol, string memory baseURI, address _erc20Token, uint256 _erc20CreateRewardValue) internal {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained(_erc20Token, _erc20CreateRewardValue);
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("");        
        __ERC1155Burnable_init_unchained();        
        __ERC1155Base_init_unchained(_name, _symbol);        
        _setBaseURI(baseURI);
    }

    uint256[49] private __gap;
}
