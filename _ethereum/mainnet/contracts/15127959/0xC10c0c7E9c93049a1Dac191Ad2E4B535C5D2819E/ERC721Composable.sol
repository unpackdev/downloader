// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Ownable.sol";
import "./ERC721Wrapper.sol";
import "./IERC721Composable.sol";

contract ERC721Composable is Ownable, IERC721Composable {

    function transferCollectionOwnership(address _collection, address _composable) public override onlyOwner {
        require(_collection != address(0) && _collection != address(this),
            'ERC721Composable: collection address needs to be different than zero and current address!');
        require(_composable != address(0) && _composable != address(this),
            'ERC721Composable: new address needs to be different than zero and current address!');
        ERC721Wrapper(_collection).transferOwnership(_composable);
        emit CollectionOwnershipTransferred(_collection, address(this), _composable);
    }
}