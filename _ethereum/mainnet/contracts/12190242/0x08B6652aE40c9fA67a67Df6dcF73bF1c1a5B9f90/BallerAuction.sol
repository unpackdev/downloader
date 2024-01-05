// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./BallerFactory.sol";

contract BallerAuction is Ownable, PaymentSplitter {
    using Address for address;
    using SafeMath for uint256;

    // Baller Minting Contract
    BallerFactory public BALLER_FACTORY;
    
    // Base fee for a baller
    uint256 public baseBallerFee = 1e16; // 0.01 ETH ~ 1e16 WEI.;

    /**
    * Constructor function.
    * @param ballerFactoryAddress Address for the baller factory contract.
    */
    constructor(address ballerFactoryAddress, address[] memory treasuryWallets, uint256[] memory treasuryShares)
    PaymentSplitter(treasuryWallets, treasuryShares)
    {
        // Create instance of baller minting factory
        BALLER_FACTORY = BallerFactory(ballerFactoryAddress);
    }

    /**
    * Sets the address for the baller factory contract.  Can only be called by owner.
    * @param ballerFactoryAddress Address of the new baller factory contract.
    */
    function setBallerFactory(address ballerFactoryAddress) onlyOwner public {
        BALLER_FACTORY = BallerFactory(ballerFactoryAddress);
    }

    /**
    * Low level baller purchase function
    * @param beneficiary will recieve the tokens.
    * @param teamId Integer of the team the purchased baller plays for.
    * @param mdHash IPFS Hash of the metadata json file corresponding to the baller.
    */
    function buyBaller(address beneficiary, uint256 teamId, string memory mdHash) public payable {
        require(beneficiary != address(0), "BallerAuction: Cannot send to 0 address.");
        require(beneficiary != address(this), "BallerAuction: Cannot send to auction contract address.");

        uint256 weiAmount = msg.value;
        uint256 ballersInCirculation = BALLER_FACTORY.getBallersInCirculation(teamId);
    
        // Require exact cost
        require(
            weiAmount == SafeMath.mul(baseBallerFee, SafeMath.add(ballersInCirculation, 1)),
            "BallerAuction: Please send exact wei amount."
        );
        
        // Mint Baller
        BALLER_FACTORY.mintBaller(beneficiary, teamId, mdHash);
    }
}