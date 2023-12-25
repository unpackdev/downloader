// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./Ownable.sol";

contract HolidayCollectible2023 is ERC1155, Ownable {
    bool public mintOpen = true; 
    uint256 public nextId = 0;
    string public name = "ETHChi Holiday Collectible 2023";


    modifier canMint() {
        require(mintOpen, "Minting is not open");
        _; 
    }

    constructor(address initialOwner)
        ERC1155("https://ipfs.io/ipfs/bafkreiahhnk2nn4lybphh4yj2b2swvp5uvzmpzv3xvfd45fsritoqgcq44")
        Ownable(initialOwner)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function toggleMinting() public onlyOwner {
        mintOpen = !mintOpen;
    }

    function mint(address account)
        public
        canMint
    {
        _mint(account, nextId, 1, "");
        nextId = nextId + 1;
    }

    function mintBatch(address to, uint256 amount)
        public
        onlyOwner
    {

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            // the array of ids should increment by 1 from nextId  to nextId + amount
            ids[i] = nextId + i;
            // amounts should all be 1
            amounts[i] = 1;
        }
        

        _mintBatch(to, ids, amounts, "");
        nextId = nextId + amount;
    }

    // this can be cheaper than batch minting and then transferring
    function airdrop(address[] memory recipients)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i]);
        }
    }

}