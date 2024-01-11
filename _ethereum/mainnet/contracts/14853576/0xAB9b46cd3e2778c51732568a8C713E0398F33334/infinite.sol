// SPDX-License-Identifier: MIT
/*
    ____      _____       _ __          ______           __   
   /  _/___  / __(_)___  (_) /____     / ____/_  _______/ /__ 
   / // __ \/ /_/ / __ \/ / __/ _ \   / /   / / / / ___/ / _ \
 _/ // / / / __/ / / / / / /_/  __/  / /___/ /_/ / /__/ /  __/
/___/_/ /_/_/ /_/_/ /_/_/\__/\___/   \____/\__, /\___/_/\___/ 
                                          /____/           

@creator:      @claramemNFT
@security:    info@infinitecycle.xyz
@website:     https://infinitecycle.xyz
*/

pragma solidity ^0.8.14;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract InfiniteCycle is ERC1155, Ownable {
    using SafeMath for uint256;

    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => uint256) public accountBalances;
    mapping(uint256 => address) public accountIndex;

    // Token details
    uint8 public constant WATER = 0;
    uint256 public totalHolders;
    // token mint price
    uint256 public mintRate = 0.007 ether;

    // token maks supply
    uint256 public supplies = 100000;

    bool public isWaterMintEnabled;

    string public name;
    string public symbol;

    constructor()
        ERC1155(
            "https://gateway.pinata.cloud/ipfs/QmVEoaBqmyzxVWg9ZsjdkzN2wSpVxdyQLh7qsHxrv2NYbh/{id}.json"
        )
    {
        name = "Infinite Cycle";
        symbol = "Water";
        totalHolders = 0;
    }

    // mint water
    function mintWater(uint256 amount) public payable {
        require(isWaterMintEnabled, "Mint is not started");
        require(amount <= 100, "You can only buy 100s WATER");
        require(
            balanceOf(msg.sender, WATER) + amount <= 1000,
            "You already have a 1000s Water"
        );
        require(msg.value >= (amount * mintRate), "Not enough ether sent");
        require(
            tokenSupply[WATER] + amount <= supplies,
            "Not enought supply left"
        );
        tokenSupply[WATER] = tokenSupply[WATER]+ 1;
        if (accountBalances[msg.sender] == 0) {
            accountIndex[totalHolders] = msg.sender;
            totalHolders = totalHolders + 1;
        }
        accountBalances[msg.sender] = accountBalances[msg.sender].add(amount);
        _mint(msg.sender, WATER, amount, "");
    }

    function burnWater(address _address)
        public
        onlyOwner
        returns (uint256 _burnAmount)
    {
        uint256 currBalance =  balanceOf(_address, WATER);
        require(
           currBalance > 9 && currBalance > 0,
            "Burn not allowed"
        );
        _burnAmount = currBalance.mod(9);
        accountBalances[_address] = accountBalances[_address].sub(_burnAmount);
        _burn(_address, WATER, _burnAmount);
        return _burnAmount;
    }

    function burnBatch() public onlyOwner {
        for (uint256 i = 0; i <= (totalHolders); i++) {
            if (accountIndex[i] != address(0)) {
                uint256 currBalance =  accountBalances[accountIndex[i]];
                if (
                    currBalance> 9 &&
                   currBalance % 9 > 0
                ) {
                    uint256 _burnAmount = currBalance.mod(
                        9
                    );
                    accountBalances[accountIndex[i]] = accountBalances[
                        accountIndex[i]
                    ].sub(_burnAmount);
                    _burn(accountIndex[i], WATER, _burnAmount);
                }
            }
        }
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    // toggle water mint
    function setIsWaterMintEnabled() external onlyOwner {
        isWaterMintEnabled = !isWaterMintEnabled;
    }

    // get current contract balances
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");
        payable(msg.sender).transfer(ownerBalance);
        
    }


}