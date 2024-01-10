// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SupplyTreasuryFundForCompound.sol";
import "./ISupplyBooster.sol";

interface ISupplyRewardFactoryExtra is ISupplyRewardFactory {
    function addOwner(address _newOwner) external;
}

contract SupplyPoolManager {
    address public supplyBooster;
    address public supplyRewardFactory;
    address public compoundComptroller;

    address public owner;
    address public governance;

    event SetOwner(address owner);
    event SetGovernance(address governance);

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "SupplyPoolManager: caller is not the owner"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "SupplyPoolManager: caller is not the governance"
        );
        _;
    }

    constructor(
        address _owner,
        address _supplyBooster,
        address _supplyRewardFactory,
        address _compoundComptroller
    ) public {
        owner = _owner;
        governance = _owner;
        supplyBooster = _supplyBooster;
        supplyRewardFactory = _supplyRewardFactory;
        compoundComptroller = _compoundComptroller;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function addSupplyPool(address _compoundCToken) public onlyGovernance {
        SupplyTreasuryFundForCompound supplyTreasuryFund = new SupplyTreasuryFundForCompound(
                supplyBooster,
                _compoundCToken,
                compoundComptroller,
                supplyRewardFactory
            );

        address underlyToken;

        // 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 = cEther
        if (_compoundCToken == 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5) {
            underlyToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        } else {
            underlyToken = ICompoundCErc20(_compoundCToken).underlying();
        }

        ISupplyRewardFactoryExtra(supplyRewardFactory).addOwner(
            address(supplyTreasuryFund)
        );

        ISupplyBooster(supplyBooster).addSupplyPool(
            underlyToken,
            address(supplyTreasuryFund)
        );
    }
}
