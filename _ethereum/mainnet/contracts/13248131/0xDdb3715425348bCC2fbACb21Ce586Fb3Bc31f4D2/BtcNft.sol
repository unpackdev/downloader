// SPDX-License-Identifier: UNLICENSED
/// @title BtcNft
/// @notice BTC NFT
/// @author CyberPnk <cyberpnk@btcnft.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IBtcNftRender.sol";

contract BtcNft is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint public totalSatoshisSacrificed = 0;
    uint public totalSatoshisLocked = 0;
    IBtcNftRender render;
    IERC20 wbtc;
    bool isDestroyDisabled = false;
    bool isChangeRenderDisabled = false;

    constructor(address renderContract, address wbtcContract) ERC721("BTCNFT", "BTCNFT") Ownable() {
        render = IBtcNftRender(renderContract);
        wbtc = IERC20(wbtcContract);
    }

    // Irreversible.
    function disableDestroy() public onlyOwner {
        isDestroyDisabled = true;
    }

    // Irreversible.
    function disableChangeRender() public onlyOwner {
        isChangeRenderDisabled = true;
    }

    // In case there's a bug, but eventually disabled
    function setRender(address renderContract) public onlyOwner () {
        require(!isChangeRenderDisabled);
        render = IBtcNftRender(renderContract);
    }

    // In case there's a really bad mistake, but eventually disabled
    function destroy() public onlyOwner {
        require(!isDestroyDisabled);
        selfdestruct(payable(owner()));
    }

    modifier validSats(uint sats) {
        require(sats >= 100000 && 
            wbtc.balanceOf(msg.sender) >= sats && 
            wbtc.allowance(msg.sender, address(this)) >= sats, "Not enough sats");
        _;
    }

    function sacrificeWbtcForNftDoNotDoThisYouLoseMoney(uint sats) public nonReentrant validSats(sats) {
        wbtc.transferFrom(msg.sender, address(0xdEaD), sats);
        uint newTotal = totalSupply() + 1;
        uint newItemId = (10**42) + newTotal * (10**18) + sats;
        totalSatoshisSacrificed += sats;
        _safeMint(msg.sender, newItemId);
    }

    function mintLockingWbtc(uint sats) public nonReentrant validSats(sats) {
        wbtc.transferFrom(msg.sender, address(this), sats);
        uint newTotal = totalSupply() + 1;
        uint newItemId = newTotal * (10**18) + sats;
        totalSatoshisLocked += sats;
        _safeMint(msg.sender, newItemId);
    }

    function unlockWbtcBurningNft(uint itemId) public nonReentrant {
        require(ownerOf(itemId) == msg.sender && itemId / (10**40) == 0, "Invalid id");
        uint sats = itemId % (10**16);
        _burn(itemId);
        totalSatoshisLocked -= sats;
        wbtc.transfer(msg.sender, sats);
    }

    function tokenURI(uint256 itemId) public view override returns (string memory) {
        return render.getTokenURI(itemId);
    }

    function contractURI() public view returns(string memory) {
        return render.getContractURI(owner());
    }

}
