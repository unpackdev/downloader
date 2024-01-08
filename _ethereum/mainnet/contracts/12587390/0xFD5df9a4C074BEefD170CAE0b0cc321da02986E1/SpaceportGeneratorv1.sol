// SPDX-License-Identifier: MIT

// Generates SpacePort contracts and registers them in the SpaceFactory 

pragma solidity 0.6.12;

import "./Spaceportv1.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SpaceportHelper.sol";

interface ISpaceportFactory {
    function registerSpaceport (address _spaceportAddress) external;
    function spaceportIsRegistered(address _spaceportAddress) external view returns (bool);
}

interface IPlasmaswapLocker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _withdrawer) external payable;
}

contract SpaceportGeneratorv1 is Ownable {
    using SafeMath for uint256;
    
    ISpaceportFactory public SPACEPORT_FACTORY;
    ISpaceportSettings public SPACEPORT_SETTINGS;
    
    struct SpaceportParams {
        uint256 amount; // the amount of spaceport tokens up for presale
        uint256 tokenPrice; // 1 base token = ? s_tokens, fixed pricev
        uint256 maxSpendPerBuyer; // maximum base token BUY amount per account
        uint256 hardcap;
        uint256 softcap;
        uint256 liquidityPercent; // divided by 1000
        uint256 listingRate; // sale token listing price on plasmaswap
        uint256 startblock;
        uint256 endblock;
        uint256 lockPeriod; // unix timestamp -> e.g. 2 weeks
    }
    
    constructor() public {
        SPACEPORT_FACTORY = ISpaceportFactory(0x67019Edf7E115d17086e1660b577CAdccc57dFf3);
        SPACEPORT_SETTINGS = ISpaceportSettings(0x90De443BDC372f9aA944cF18fb6c82980807Cb0a);
    }
    
    /**
     * @notice Creates a new Spaceport contract and verify it in the SpaceportFactory.sol.
     */
    function createSpaceport (
      address payable _spaceportOwner,
      IERC20 _spaceportToken,
      IERC20 _baseToken,
      uint256[10] memory uint_params,
      uint256[2] memory vesting_params
      ) public payable {
        
        SpaceportParams memory params;
        params.amount = uint_params[0];
        params.tokenPrice = uint_params[1];
        params.maxSpendPerBuyer = uint_params[2];
        params.hardcap = uint_params[3];
        params.softcap = uint_params[4];
        params.liquidityPercent = uint_params[5];
        params.listingRate = uint_params[6];
        params.startblock = uint_params[7];
        params.endblock = uint_params[8];
        params.lockPeriod = uint_params[9];
        
        if (params.lockPeriod < 4 weeks) {
            params.lockPeriod = 4 weeks;
        }
        
        // Charge ETH fee for contract creation
        require(msg.value == SPACEPORT_SETTINGS.getEthCreationFee(), 'FEE NOT MET');
        SPACEPORT_SETTINGS.getEthAddress().transfer(SPACEPORT_SETTINGS.getEthCreationFee());
        
        
        require(params.amount >= 10000, 'MIN DIVIS'); // minimum divisibility
        require(params.endblock.sub(params.startblock) <= SPACEPORT_SETTINGS.getMaxSpaceportLength());
        require(params.tokenPrice.mul(params.hardcap) > 0, 'INVALID PARAMS'); // ensure no overflow for future calculations
        require(params.liquidityPercent >= 300 && params.liquidityPercent <= 1000, 'MIN LIQUIDITY'); // 30% minimum liquidity lock
        
        uint256 tokensRequiredForSpaceport = SpaceportHelper.calculateAmountRequired(params.amount, params.tokenPrice, params.listingRate, params.liquidityPercent, SPACEPORT_SETTINGS.getTokenFee());
      
        Spaceportv1 newSpaceport = new Spaceportv1(address(this));
        TransferHelper.safeTransferFrom(address(_spaceportToken), address(msg.sender), address(newSpaceport), tokensRequiredForSpaceport);
        newSpaceport.init1(_spaceportOwner, params.amount, params.tokenPrice, params.maxSpendPerBuyer, params.hardcap, params.softcap, 
        params.liquidityPercent, params.listingRate, params.startblock, params.endblock, params.lockPeriod);
        newSpaceport.init2(_baseToken, _spaceportToken, SPACEPORT_SETTINGS.getBaseFee(), SPACEPORT_SETTINGS.getTokenFee(), SPACEPORT_SETTINGS.getEthAddress(), SPACEPORT_SETTINGS.getTokenAddress(), vesting_params[0], vesting_params[1]);
        SPACEPORT_FACTORY.registerSpaceport(address(newSpaceport));
    }
    
}