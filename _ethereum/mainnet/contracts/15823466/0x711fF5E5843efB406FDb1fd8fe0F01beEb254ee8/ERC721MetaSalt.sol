// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC721Base.sol";
contract ERC721MetaSalt is ERC721Base {

    event CreateERC721MetaSalt(address owner, string name, string symbol);

    function __ERC721MetaSalt_init(string memory _name, string memory _symbol, string memory baseURI, address _erc20Token, uint256 _erc20CreateRewardValue) external initializer {
        __ERC721MetaSalt_init_unchained(_name, _symbol, baseURI, _erc20Token, _erc20CreateRewardValue);
        emit CreateERC721MetaSalt(_msgSender(), _name, _symbol);
    }

    function __ERC721MetaSalt_init_unchained(string memory _name, string memory _symbol, string memory baseURI, address _erc20Token, uint256 _erc20CreateRewardValue) internal {
        _setBaseURI(baseURI);
        __ERC721Lazy_init_unchained(_erc20Token, _erc20CreateRewardValue);        
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Ownable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Mint721Validator_init_unchained();        
        __ERC721_init_unchained(_name, _symbol);
    }
    uint256[50] private __gap;
}