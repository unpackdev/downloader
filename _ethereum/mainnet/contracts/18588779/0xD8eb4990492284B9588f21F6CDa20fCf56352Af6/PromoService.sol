// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma abicoder v2;

import "./Ownable.sol";
import "./IWildlandCards.sol";

contract PromoService is Ownable(msg.sender) {

    mapping(address => uint256) claimable; // cardID = value - 1 if value > 0 to safe gas
    IWildlandCards public wmc;

    constructor() {
        wmc = IWildlandCards(0x62061b764EC66FE1Bd8910b1Af780043976A6c68);
        wmc.balanceOf(address(this));
    }

    function grant(address[] calldata _recipients, uint256[] calldata _ids) public onlyOwner {
        uint256 length = _recipients.length;
        require(_recipients.length == length);
        for (uint i = 0; i < length; i++) {
            claimable[_recipients[i]] = _ids[i];
        }
    }

    function claim () external {
        require(claimable[msg.sender] > 0, "claim: already claimed or not eligible");
        uint256 cardId = getID(msg.sender);
        claimable[msg.sender] = 0;
        wmc.mint(msg.sender, cardId);
    }

    function hasClaim(address _address) external view returns (bool) {
        return claimable[_address] > 0;
    }

    function getID(address _address) public view returns (uint256) {
        for (uint256 i = claimable[_address]; i > 1; i-- )
         if (wmc.isCardAvailable(i - 1))
            return i - 1;
        // default 0
        return 0;
    }
}