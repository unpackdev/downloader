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

pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155PresetMinterPauser.sol";
import "./EditionsByRainerHosch.sol";

contract EditionsByRainerHoschMinterBurner is Ownable {
    address public rainerHoschEditionsAddress = 0xadB4eCDABeeD8eBC69fA02F60cD43e8A2ce511e1;
    address public rainerHoschAddress = 0x6dDdB0D63f5E12fdb18113916Bb3C6d67688024A;
    uint256 public mintTokenId = 6;
    uint256 public mintTokenAmount = 1;

    uint256 public burnTokenId = 47; 
    uint256 public burnTokenAmount = 1;

    bool public isMintEnabled = true;

    constructor() {}

    function mint(uint256 amount) public {
        require(isMintEnabled, "Mint not enabled");
        
        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        ERC1155PresetMinterPauser burnTokenToken = ERC1155PresetMinterPauser(rainerHoschAddress);
        
        require(burnTokenToken.balanceOf(msg.sender, burnTokenId) >= burnTokenAmount * amount, "No tokens");
        require(burnTokenToken.isApprovedForAll(msg.sender, address(this)), "Not approved");
        burnTokenToken.burn(msg.sender, burnTokenId, burnTokenAmount * amount);

        address[] memory senderArray = new address[](1);
        senderArray[0] = msg.sender;

        uint256[] memory mintTokenIdArray = new uint256[](1);
        mintTokenIdArray[0] = mintTokenId;

        uint256[] memory mintTokenAmountArray = new uint256[](1);
        mintTokenAmountArray[0] = amount;

        token.airdrop(senderArray, mintTokenIdArray, mintTokenAmountArray);
    }

    function returnOwnership() public onlyOwner {
        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        token.transferOwnership(msg.sender);
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setRainerHoschEditionsAddress(address newAddress) public onlyOwner {
        rainerHoschEditionsAddress = newAddress;
    }
    
    function setRainerHoschAddress(address newAddress) public onlyOwner {
        rainerHoschAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setMintTokenAmount(uint256 amount) public onlyOwner {
        mintTokenAmount = amount;
    }

    function setBurnTokenId(uint256 tokenId) public onlyOwner {
        burnTokenId = tokenId;
    }

     function setBurnTokenAmount(uint256 amount) public onlyOwner {
        burnTokenAmount = amount;
    }
}