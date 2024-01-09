//    _________________________________________________
//   /                              SUDOPASS o-+       \
//  |___    SUDOSIX 2k22    ____________________________|
//  |   \   o(*￣▽￣*)ブ   /                   _    _   |
//  |    \                / o             /          /  |
//   \    \______________/ o      ,_______      _// /   |
//    |o--    \\\\         o         ____.\  o  __ o    |
//    |  o      \  ====   O    + - _/    \\\   -----/   |
//    |   \___      S                     \\\______/  o |
//    | ///   \     D  [ *6* ]             \\___/    o  |
//    |     o o o   6  #      __________________________|
//   /       o o o           /                          |
//  |    * \\\    ____.     /        <--INSERT---       |
//   \_____________________/___________________________/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract SUDOPASS is ERC1155, Ownable, ERC1155Burnable { 
    using SafeMath for uint256;
    uint256 tokenId = 0;
    string cURI;
    uint256 amountMinted = 0;
    uint256 limitAmount = 200;
    string name_ = "SUDOSIX SUDOPASS";
    string symbol_ = "PASS";
    bool dynamicURI = false;
    
    constructor() ERC1155("") {}

    // Mints index sequentially -sd6
    function mintPasses(address[] memory userAddresses) public onlyOwner { 
        require(userAddresses.length + amountMinted <= limitAmount, "Limit reached");
        for(uint256 i = 0; i < userAddresses.length; i++) {
            tokenId++;
            amountMinted = tokenId;
            _mint(userAddresses[i], tokenId, 1, "");
        }
    }

    // Set dynamic URI root -sd6
    function setcURI(string memory newuri) public onlyOwner {
        cURI = newuri;
    }

    // Toggle between static and dynamic URI
    function toggleURI() public onlyOwner {
        dynamicURI = !dynamicURI;
    }

    // Dynamic URI return: switches to an API that can show the PASS's 
    // redeemability for future projects. The API will always be derivative
    // of the IPFS hash hardcoded below. This ensures collectors can value
    // tokens with a full display on what project it has been redeemed for. -sd6
    function uri(uint256 id) override public view returns (string memory) {
        if (dynamicURI == true) {
            string memory val = SUDOPASS.cURI;
            return string(abi.encodePacked(val,Strings.toString(id)));
        } else {
            return "ipfs://QmVHEFYVbbDfqgUcERp8ZJiMUdcCxbiVvx9X91bNH7R3S1"; 
        }
    }

    //ownerBalance - 721 style -sd6
    function ownerBalance(address _owner) public view returns(uint256){
        uint256 i;
        uint256 result = 0;
        for (i = 0; i < tokenId + 1 ; i++) {
            if (balanceOf(_owner, i) == 1) {
                result++;
            }
        }
        return result;
    }

    //returns all SUDOPASS's of owner address -sd6
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 i;
        uint256 d = 0;
        uint256[] memory result = new uint256[](ownerBalance(_owner));
        for (i = 0; i <= tokenId ; i++) {
            if (balanceOf(_owner, i) == 1) {
                result[d] = i;
                d++;
            }
        }
        return result;
    }

    // Get amount of 1155 minted -sd6
    function totalSupply() view public returns(uint256) {
        return amountMinted;
    }

    // Get name -sd6
    function name() external view returns(string memory) {
        return name_;
    }
    // Get sym -sd6
    function symbol() external view returns(string memory) {
        return symbol_;
    }
}