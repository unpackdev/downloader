// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./Initializable.sol";
import "./IERC721Enumerable.sol";

contract MintLogic is Initializable {

    address public storageAddr;

    mapping(address => mapping(address => bool)) public approves;

    constructor() public initializer {}

    function initialize(address _storage) public initializer {
        storageAddr = _storage;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC721Received.selector;
    }

    function execute(address _contolAddr, address _nftAddr, bytes memory _data) external payable {
        (bool success,) = _contolAddr.call{value : msg.value}(_data);
        require(success, "Call Contol Address Error");

        IERC721Enumerable nft = IERC721Enumerable(_nftAddr);
        try nft.tokenOfOwnerByIndex(address(this), 0) {
            uint256 nftBalance = nft.balanceOf(address(this));
            for(uint i = 0; i < nftBalance; i++){
                nft.transferFrom(address(this), tx.origin, nft.tokenOfOwnerByIndex(address(this), 0));
            }
        }catch {
            approves[_nftAddr][tx.origin] = true;
        }

        if(address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function fetchNft(address _nftAddr, uint256 _tokenId) external {
        require(approves[_nftAddr][tx.origin], "require approves");
        try IERC721Enumerable(_nftAddr).transferFrom(address(this), tx.origin, _tokenId) {} catch {}
    }
}