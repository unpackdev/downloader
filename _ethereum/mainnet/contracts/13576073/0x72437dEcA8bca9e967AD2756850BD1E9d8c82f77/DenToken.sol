// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./IWolfPack.sol";
import "./Ownable.sol";

contract DenToken is Ownable, ERC20Capped {

    // total den tokens released (that were deposited to this contract)
    uint private _totalReleased;

    // wolf Id => last claim timestamp
    mapping(uint16 => uint64) private _lastClaimTimestamp; // seconds in 24 hours: 86400

    // wolf Id => amount minted per wolf
    mapping(uint16 => uint) private mintedPerWolf;

    // wolf ID => released amount
    mapping(uint16 => uint) private _released;
    
    // implementing the Wolf Pack genesis tokens contract:
    IWolfPack wolfPackContract;

    constructor() ERC20("Den Token", "DEN") ERC20Capped(62_050_000e18) { }

    /**
     * @dev sets the Wolf Pack contract address (genesis wolfs)
     */
    function setWolfPackContractAddress(address _contractAddress) public onlyOwner {
        wolfPackContract = IWolfPack(_contractAddress);
    }

    /**
     * @dev getter function to get the last claim timestamp for a specific wolf ID
     */
    function getLastClaimTimestampForWolf(uint16 wolfId) external view returns(uint64) {
        return _lastClaimTimestamp[wolfId];
    }

    function claimDen(uint16 wolfId) external {
        address wolfOwner = wolfPackContract.ownerOf(wolfId);
        require(wolfOwner == msg.sender, "Only the owner of the wolf can call this function");

        (uint amountToClaim, uint denAvalibleToRelease) = availableDenForWolf(wolfId);

        if (mintedPerWolf[wolfId] < 36_500e18) { // 36500 den  // if there are tokens avalible to mint for that specific wolf so:
            require(amountToClaim != 0, "No tokens avalible to claim!");
            if (denAvalibleToRelease >= amountToClaim) { // if there are more tokens to release than the amount to claim so release the amount to claim
                _released[wolfId] += amountToClaim;
                _totalReleased += amountToClaim;
                _lastClaimTimestamp[1] = uint16(block.timestamp);
                bool success = transfer(wolfOwner, amountToClaim);
                require(success, "Payment didn't go through!");
            } else { // if the there are less tokens to release than the amount to claim:
                if (denAvalibleToRelease >= 10e18) { // if there are 10 or more tokens avalible to release:
                    // (amount to release) = (amount of 10 den avalible to release)
                    uint denAmountToRelease = (denAvalibleToRelease - (denAvalibleToRelease % 10e18));
                    // (amount to mint) = (amount to claim) - (amount of 10 den avalible to release)
                    uint amountToMint = amountToClaim - denAmountToRelease;
                    /**
                     * this is calculated like this to prevent complications with minting less than 10 den tokens at a time
                     */

                    _mintDen(wolfOwner, amountToMint, wolfId); // mint the amount tokens required to mint
                    _released[wolfId] += denAmountToRelease;
                    _totalReleased += denAmountToRelease;
                    bool success = transfer(wolfOwner, denAmountToRelease);
                    require(success, "Payment didn't go through!");
                } else { // if there are no 10 den tokens avalible to release so mint them
                    _mintDen(wolfOwner, amountToClaim, wolfId);
                }
            }
        } else { // if all the tokens that can be minted for a wolf were minted so release the avalible tokens to release for that wolf
            require(denAvalibleToRelease != 0, "There is nothing to release");
            _released[wolfId] += denAvalibleToRelease;
            _totalReleased += denAvalibleToRelease;
            bool success = transfer(wolfOwner, denAvalibleToRelease);
            require(success, "Payment didn't go through!");
        }
    }

    function availableDenForWolf(uint16 _wolfId) public view returns(uint amountToClaim, uint denAvalibleToRelease) {
        uint totalReceived = balanceOf(address(this)) + _totalReleased;
        uint amountMinted = mintedPerWolf[_wolfId];
        denAvalibleToRelease = (totalReceived / 1700) - _released[_wolfId];

        if (amountMinted < 36_500e18) { // 36500 den  // if there are tokens avalible to mint for that specific wolf so:
            uint numberOfDays = uint((block.timestamp - _lastClaimTimestamp[_wolfId]) / 1 days); // *change to minutes for testing
            if (numberOfDays == block.timestamp / (1 days)) { // checks if nothing was claimed yet
                amountToClaim = 10e18; // 10 den
            } else {
                amountToClaim = numberOfDays * 10e18; // 10 den * days
                if (amountToClaim + amountMinted >= 36_500e18) { // if amountToClaim exeeds the amount a wolf can generate so it returns the correct amount
                    amountToClaim = 36_500e18 - mintedPerWolf[_wolfId];
                }
            }
            
            // gets the amount of full den tokens that can be released from the contract balance to that specific wolf \/\/\/
            denAvalibleToRelease = (denAvalibleToRelease - (denAvalibleToRelease % 1e18)); // full den tokens
        } // if there are no tokens to mint, so the amount of den that can be released to that specific wolf will be return what is calculated on the top
    }

    function _mintDen(address _address, uint _amount, uint16 _wolfId) private {
        _mint(_address, _amount);
        mintedPerWolf[_wolfId] += _amount;
        _lastClaimTimestamp[_wolfId] = uint64(block.timestamp);
    }

}