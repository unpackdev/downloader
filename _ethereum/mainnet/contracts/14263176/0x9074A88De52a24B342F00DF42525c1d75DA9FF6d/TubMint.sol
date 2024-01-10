// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


// heyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
// don't worry about what's going on here. :)

import "./Ownable.sol";

contract TubMint is Ownable {
    TubbyContract TARGET;
    address public targetAddress;
    constructor(address _targetAddress) {
        targetAddress = _targetAddress;
        TARGET = TubbyContract(targetAddress);
    }

    uint256 public mintPrice = 0.5 ether;
    uint256 public mintAmount = 5;
    function execute(uint256 mintTimes) external payable onlyOwner {
        require(block.timestamp > 1645634753, "TUBBY_MINT_TIME_NOT_REACHED");
        for (uint256 i = 0; i < mintTimes; i++) {
            TARGET.mintFromSale{value: mintPrice}(mintAmount);
        }
    }    

    function transferTubby(address _to, uint[] calldata _tokenIds) external onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            TARGET.transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function changeMinPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function changeMintAmount(uint256 _newAmount) external onlyOwner {
        mintAmount = _newAmount;
    }
}

interface TubbyContract {
    function mintFromSale(uint256) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external;
}