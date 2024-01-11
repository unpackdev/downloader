// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./IERC20deployer.sol";
import "./ILERC20deployer.sol";
import "./Icontroller.sol";

contract Deployer  {
    IController public immutable controller;
    address public bridge;
    bool losslessEnabled = true;
    address public losslessRecoveryAdmin_;
    address public lossless_;
    uint256 public timelockPeriod_;

    event LosslessUpdated(
        address previousRecoveryAdmin,
        address indexed newRecoveryAdmin,
        uint256 previousTimeLockPeriod,
        uint256 newTimeLockPeriod,
        address previousLosslessAddress,
        address indexed newRecoveryLosslessAddress
    );
    event BridgeUpdated(address indexed oldBridgeAddress, address indexed newBridgeAddress);
    event lossLessEnableStateUpdated(bool status);

    modifier onlyOwner {
    require(controller.owner() == msg.sender, " caller is not the owner");
        _;
    
    }
    modifier Admin {
    require(controller.owner() == msg.sender || controller.isAdmin(msg.sender), " caller is not the admin");
        _;
    
    }
    constructor(IController _controller ) {
        controller = _controller;
    }
    

    function deployerWrappedAsset(string calldata _name , string calldata _symbol, uint256 lossless) external  returns(address) {
        require(msg.sender == bridge ,"U_A");
        if (lossless == 1 && losslessEnabled) {
            LERC20 lossless_asset = new LERC20(0 ,string(abi.encodePacked( "br", _name)) , string(abi.encodePacked("br" , _symbol)) ,bridge, losslessRecoveryAdmin_ ,timelockPeriod_,lossless_ );
            lossless_asset.transferOwnership(bridge);
            return address(lossless_asset);
        } else {
            WrappedToken default_asset =    new WrappedToken(string(abi.encodePacked( "br", _name)) , string(abi.encodePacked("br" , _symbol)));
            default_asset.transferOwnership(bridge);
            return address(default_asset);
        }
    }


   function  udpadateBridge(address _bridge) external onlyOwner {
       require(_bridge != address(0) , "zero Address");
       emit BridgeUpdated(bridge , _bridge);
       bridge = _bridge;

   }
   
   function enableLossLess(bool status) external onlyOwner {
       require(losslessEnabled != status, "same State");
       emit lossLessEnableStateUpdated(status);
       losslessEnabled = status;
   }

   function  updateLossless(address recoveryAdmin ,uint256 timelockPeriod ,address  lossless) external Admin {
    emit LosslessUpdated(
        losslessRecoveryAdmin_,
        recoveryAdmin,
        timelockPeriod_,
        timelockPeriod,
        lossless_,
        lossless
    );

     losslessRecoveryAdmin_ = recoveryAdmin;
     lossless_ = lossless;
     timelockPeriod_ = timelockPeriod;

   }
}
       
