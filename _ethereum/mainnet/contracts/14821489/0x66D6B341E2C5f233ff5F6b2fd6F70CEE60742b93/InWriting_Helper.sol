// SPDX-License-Identifier: MIT

//               ____ ____ _________ ____ ____ ____ ____ ____ ____ ____ 
//              ||I |||n |||       |||W |||r |||i |||t |||i |||n |||g ||
//              ||__|||__|||_______|||__|||__|||__|||__|||__|||__|||__||
//              |/__\|/__\|/_______\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|

/*  restrictions at time of deployment:
*       wert can only use 8 decimal places of precision in eth price
*       there is a minimum credit card payment of $1.05 USD
*
*   compromises:
*       we decided to not send remaining rounded balances to the user because
*       it would cost more in gas than the user would be getting back (21,000 gwei / transfer -> 21000 gwei > 1e-8 eth)
*/


pragma solidity ^0.8.1;

import "./Ownable.sol";

interface InWriting {
    function mint_NFT(string memory str) external payable returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function get_minting_cost() external view returns (uint256);
    function buy(uint256 tokenId) external payable returns (bool);
    function mint_unlocked_NFT(string memory str) external payable returns (uint256);
    function get_price(uint256 tokenId) external view returns (uint256);
}

contract InWriting_Helper is Ownable{
    address InWriting_address = 0x4Ced71C6F18b112A36634eef5aCFA6156C6dADaD;
    InWriting write = InWriting(InWriting_address);

    constructor(){}

    function withdraw(uint256 amt) public onlyOwner {
        require(amt <= address(this).balance);
        payable(owner()).transfer(amt);
    }

    function mint_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function mint_unlocked_and_send(string memory str, address addr) public payable returns (uint256) {
        uint256 tokenId = write.mint_unlocked_NFT{value: write.get_minting_cost()}(str);
        write.transferFrom(address(this), addr, tokenId);
        return tokenId;
    }

    function buy_and_send(uint256 tokenId, address addr) public payable returns (bool) {
        write.buy{value: write.get_price(tokenId)}(tokenId);
        write.transferFrom(address(this), addr, tokenId);
        return true;
    }

}