//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";

contract RainerHoschMinter is Ownable {
    address public rainerHoshAddress = 0x6dDdB0D63f5E12fdb18113916Bb3C6d67688024A;
    
    uint256 public mintTokenId = 47;
    uint256 public mintTokenPrice = 52000000 gwei;
    uint256 public mintTokenMaxAmount = 5;

    constructor() {
    }


    function mint(uint256 amount) public payable {
        require(msg.value >= mintTokenPrice * amount, "RainerHoschMinter: Not enough funds");
        require(amount >= 1, "RainerHoschMinter: Amount must be >= 1");
        require(amount <= mintTokenMaxAmount, "RainerHoschMinter: Amount must be <= 5");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(rainerHoshAddress);
        token.mint(msg.sender, mintTokenId, amount, "");
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }



    function setRainerHoschAddress(address newAddress) public onlyOwner {
        rainerHoshAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setMintTokenPrice(uint256 tokenPrice) public onlyOwner {
        mintTokenPrice = tokenPrice;
    }

     function setMintTokenMaxAmount(uint256 amount) public onlyOwner {
        mintTokenMaxAmount = amount;
    }
}