/*
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Receiver.sol";

interface ICryptid {
    function ownerMint(uint256 numberOfTokens) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function getLastTokenId() external view returns (uint256);
    function transferOwnership(address newOwner) external;


}

contract CryptidsFreeMint is Ownable, IERC721Receiver {


    ICryptid public constant CRYPTID = ICryptid(0x0B68BE2e1072204E68c6C0b8b46ac108E3E3dDd0);

    bool public isPublicSaleActive;

    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    // ---  PUBLIC MINTING FUNCTIONS ---

    // mint allows for regular minting while the supply does not exceed maxCryptids.
    function mint()
        external
    {
        require(claimed[msg.sender] == false, "already claimed");
        claimed[msg.sender] = true;
        CRYPTID.ownerMint(2);
        CRYPTID.transferFrom(address(this), msg.sender, (CRYPTID.getLastTokenId() - 1));
        CRYPTID.transferFrom(address(this), msg.sender, CRYPTID.getLastTokenId());
    }

    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data ) public override returns (bytes4) {
            return this.onERC721Received.selector;
    }

    function returnOwnership() public onlyOwner {
        CRYPTID.transferOwnership(owner());
    }
}