// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC721.sol";

contract TestERC721 is ERC721("TEST ERC721", "testerc721") {

    uint256 public minted;
    uint256 public maximumSupply = 100;
    uint256 public maxMintsPerTrx = 5;

    modifier doesNotExceedMaxSupply(uint256 amount) {
        require(minted+amount <= maximumSupply);
        _;
    }

    modifier hasAccurateValue(uint256 amount) {
        uint256 price = getMintPrice();
        require(price*amount == msg.value);
        _;
    }

    function _returnEth(address to, uint256 amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function mint(
        address to, uint256 amount
    ) public payable doesNotExceedMaxSupply(amount) hasAccurateValue(amount) {
        for (uint256 i = minted; i < minted+amount; i++) {
            _mint(to, i);
        }
        minted = minted + amount;
        _returnEth(msg.sender, msg.value);
    }

    function batchMint(address[] memory addrs) public payable {
        uint256 amount = addrs.length;
        require(minted+amount <= maximumSupply);
        
        uint256 price = getMintPrice();
        require(price*amount == msg.value);

        for (uint256 i = minted; i < amount; i++) {
            _mint(addrs[i], i);
        }
        minted = minted + amount;
        _returnEth(msg.sender, msg.value);
    }

    function totalSupply() public view returns(uint256) {
        return minted;
    }

    function getMintPrice() public view returns(uint256) {
        return (minted / 10) * 10 ** 14;
    }
}