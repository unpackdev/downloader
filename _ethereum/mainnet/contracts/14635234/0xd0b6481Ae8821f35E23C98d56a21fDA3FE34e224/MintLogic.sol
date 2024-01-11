// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./MintStorage.sol";
import "./Initializable.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";

contract MintLogic is Initializable {

    address public storageAddr;

    constructor() public initializer {}

    function initialize(address _storage) public initializer {
        storageAddr = _storage;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function execute(address _contolAddr, address _nftAddr, uint256 _price, bytes memory _data) external payable {
        _contolAddr.call{value : _price}(_data);

        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        uint256 nftBalance = nft.balanceOf(address(this));
        for(uint i = 0; i < nftBalance; i++){
            nft.transferFrom(address(this), tx.origin, nft.tokenOfOwnerByIndex(address(this), 0));
        }
    }
}