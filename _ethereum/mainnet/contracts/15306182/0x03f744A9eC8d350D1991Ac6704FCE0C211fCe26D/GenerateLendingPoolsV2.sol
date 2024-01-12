// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SupplyTreasuryFundForCompound.sol";
import "./IConvexBoosterV2.sol";
import "./ISupplyBooster.sol";

interface ILendingMarket {
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) external;
}

interface ISupplyRewardFactoryExtra is ISupplyRewardFactory {
    function addOwner(address _newOwner) external;
}

contract GenerateLendingPoolsV2 {
    address public convexBooster;
    address public lendingMarket;

    address public supplyBooster;
    address public supplyRewardFactory;

    address public compoundComptroller;

    address public deployer;

    constructor(address _deployer) public {
        deployer = _deployer;
    }

    function setLendingContract(
        address _supplyBooster,
        address _convexBooster,
        address _lendingMarket,
        address _supplyRewardFactory,
        address _compoundComptroller
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        supplyBooster = _supplyBooster;
        convexBooster = _convexBooster;
        lendingMarket = _lendingMarket;
        supplyRewardFactory = _supplyRewardFactory;
        compoundComptroller = _compoundComptroller;
    }

    function addConvexBoosterPool(uint256 _originConvexPid) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(_originConvexPid);
    }

    function addConvexBoosterPool(
        uint256 _originConvexPid,
        address _curveSwapAddress,
        address _curveZapAddress,
        address _basePoolAddress,
        bool _isMeta,
        bool _isMetaFactory
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        IConvexBoosterV2(convexBooster).addConvexPool(
            _originConvexPid,
            _curveSwapAddress,
            _curveZapAddress,
            _basePoolAddress,
            _isMeta,
            _isMetaFactory
        );
    }

    function addLendingMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds
    ) public {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        ILendingMarket(lendingMarket).addMarketPool(
            _convexBoosterPid,
            _supplyBoosterPids,
            _curveCoinIds,
            100,
            50
        );
    }

    function addSupplyPoolForCEther(address _compoundCToken) public {
        _addSupplyPool(_compoundCToken, false);
    }

    function addSupplyPoolForCToken(address _compoundCToken) public {
        _addSupplyPool(_compoundCToken, true);
    }

    function _addSupplyPool(address _compoundCToken, bool _isErc20) internal {
        require(deployer == msg.sender, "!authorized auth");

        require(supplyBooster != address(0), "!supplyBooster");
        require(convexBooster != address(0), "!convexBooster");
        require(lendingMarket != address(0), "!lendingMarket");
        require(supplyRewardFactory != address(0), "!supplyRewardFactory");

        SupplyTreasuryFundForCompound supplyTreasuryFund = new SupplyTreasuryFundForCompound(
                supplyBooster,
                _compoundCToken,
                compoundComptroller,
                supplyRewardFactory
            );

        address underlyToken;

        // 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5 = cEther
        if (_isErc20) {
            underlyToken = ICompoundCErc20(_compoundCToken).underlying();
        } else {
            underlyToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
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
