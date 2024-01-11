// SPDX-License-Identifier: MIT
// Cipher Mountain Contracts (last updated v0.0.1) (/Minter.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Mintable.sol";

contract Minter is Ownable {
    event Mint(address indexed owner, uint price, uint quantity);
    event Fallback(address indexed owner, uint price, uint quantity);

    uint private _price;
    uint256 private _limit;
    Mintable private _nftContract;

    /**
     * @dev Initializes the contract
     */
    constructor(address contractAddr, uint256 limit) {
        _limit = limit;
        _price = 5 * 10**16; // 0.05 ETH
        _nftContract = Mintable(contractAddr);
    }

    receive() external payable {
        require(msg.value == _price, 'value sent must equal price to mint one token');
        _mint(1);
    }

    fallback() external payable {
        require(msg.value == _price, 'value sent must equal price to mint one token');
        _mint(1);
    }

    function mint(uint8 quantity) external payable {
        require(quantity < 21 && quantity > 0, 'multiple minting limited to 10');
        require(msg.value == quantity*_price, 'value sent must equal price x quantity to mint');
        _mint(quantity);
    }

    function _mint(uint8 quantity) internal {
        require(quantity+_nftContract.totalSupply() <= _limit, 'must not exceed limit');
       
        _nftContract.mint(msg.sender, quantity);
        emit Mint(msg.sender, msg.value, quantity);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTo(address recipient) external onlyOwner {
        payable(recipient).transfer(address(this).balance);
    }

    function setLimit(uint256 limit) external onlyOwner {
        _limit = limit;
    }

    function setPrice(uint price) external onlyOwner {
        _price = price;
    }

    function setContractAddr(address _contract) external onlyOwner {
        _nftContract = Mintable(_contract);
    }
}
