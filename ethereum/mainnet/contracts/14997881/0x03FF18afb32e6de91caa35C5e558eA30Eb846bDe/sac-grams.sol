// SPDX-License-Identifier: MIT

//███████╗ █████╗  ██████╗
//██╔════╝██╔══██╗██╔════╝
//███████╗███████║██║
//╚════██║██╔══██║██║
//███████║██║  ██║╚██████╗
//╚══════╝╚═╝  ╚═╝ ╚═════╝

// $GRAMS ERC-20 Token System created by MisterSausage NFT Elite Consulting x SausageLabs.io for STONER APE CLUB
// This ERC-20 Token has NO FINANCIAL VALUE. Its main and only purpose is to be allowed to be used inside the Stoner Ape Club ecosystem.

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract SACGrams is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    address public treasuryWallet;
    address public rewardsWallets;
    address public developmentWallet;
    address public teamWallet;

    bool initAddress;
    bool initMint;

    constructor() ERC20("SACGrams", "SACGRAMS") ERC20Permit("SACGrams") {}

    receive() external payable {}

    //set wallet addresses, can be executed only once
    function setWalletAddresses(address _treasuryWallet, address _rewardsWallets, address _developmentWallet, address _teamWallet) external onlyOwner {
        require(!initAddress, "Addresses have already been set");
        treasuryWallet = _treasuryWallet;
        rewardsWallets = _rewardsWallets;
        developmentWallet = _developmentWallet;
        teamWallet = _teamWallet;
        initAddress = true;
    }

    //mint the total supply, can be executed only once
    function mint() external onlyOwner {
        require(!initMint, "Supply have already been minted");
        require(initAddress, "Recepient wallet addresses have not been set");
        _mint(treasuryWallet, 209999950 * 10 ** decimals());
        _mint(rewardsWallets, 209999950 * 10 ** decimals());
        _mint(developmentWallet, 50 * 10 ** decimals());
        _mint(teamWallet, 50 * 10 ** decimals());
        initMint = true;
    }
}
