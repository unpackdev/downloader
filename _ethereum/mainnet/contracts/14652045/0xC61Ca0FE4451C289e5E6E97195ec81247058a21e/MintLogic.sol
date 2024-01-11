// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./Initializable.sol";
import "./IERC721Enumerable.sol";

contract MintLogic is Initializable {

    address public storageAddr;

    mapping(address => address) public projectOwner;

    constructor() public initializer {}

    modifier onlyStorage() {
        require(storageAddr == msg.sender, "MintProxy: caller is not the storage");
        _;
    }

    function initialize(address _storage) public initializer {
        storageAddr = _storage;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC721Received.selector;
    }

    function execute(address _contolAddr, address _nftAddr, bytes memory _data) external payable onlyStorage {
        require(projectOwner[_nftAddr] == address(0) || projectOwner[_nftAddr] == tx.origin, "The project already has an owner");

        (bool success,) = _contolAddr.call{value : msg.value}(_data);
        require(success, "Call Contol Address Error");

        if(projectOwner[_nftAddr] == address(0)){
            projectOwner[_nftAddr] = tx.origin;
        }

        if(address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function fetchNft(address _nftAddr, uint256 _tokenId) external onlyStorage {
        require(projectOwner[_nftAddr] == tx.origin, "require project owner");
        try IERC721Enumerable(_nftAddr).transferFrom(address(this), tx.origin, _tokenId) {} catch {}
    }
}