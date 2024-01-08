// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";

interface BaseToken {
    function mint(address to) external;
    function totalMinted() external returns (uint256);
    function maxSupply() external returns (uint256);
}

contract Reserver is Ownable{

    address public tokenContract;      // Token to be minted.

    /* ------------------------------- Constructor ------------------------------ */

    constructor(
        address _tokenContract
    ) {
        tokenContract = _tokenContract;
    }


    /* ------------------------------ Owner Methods ----------------------------- */

    function reserveTokens(uint256 num, address receiver) public onlyOwner {
        for (uint256 i = 0; i < num; i++) {
            BaseToken(tokenContract).mint(receiver);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function sweep(address token, address to, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {    
        return IERC20(token).transfer(to, amount);
    }

}