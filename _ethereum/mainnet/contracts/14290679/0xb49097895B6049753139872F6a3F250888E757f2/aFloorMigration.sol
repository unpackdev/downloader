// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./FloorAccessControlled.sol";

contract AlphaFloorMigration is FloorAccessControlled {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public FLOOR;
    IERC20 public aFLOOR;
    
    bool public isInitialized;

    modifier onlyInitialized() {
        require(isInitialized, "not initialized");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized, "already initialized" );
        _;
    }

    constructor(
        address _authority
    ) FloorAccessControlled(IFloorAuthority(_authority)) {}

    function initialize (
        address _FLOOR,
        address _aFLOOR
    ) public notInitialized() onlyGovernor {
        require(_FLOOR != address(0), "_FLOOR: Zero address");
        require(_aFLOOR != address(0), "_aFLOOR: Zero address");

        FLOOR = IERC20(_FLOOR);
        aFLOOR = IERC20(_aFLOOR);
        isInitialized = true;
    }

    /**
      * @notice swaps aFLOOR for FLOOR
      * @param _amount uint256
      */
    function migrate(uint256 _amount) external onlyInitialized() {
        require(
            aFLOOR.balanceOf(msg.sender) >= _amount,
            "amount above user balance"
        );

        aFLOOR.safeTransferFrom(msg.sender, address(this), _amount);
        FLOOR.transfer(msg.sender, _amount);
    }

    /**
      * @notice governor can withdraw any remaining FLOOR.
      */
    function withdraw() external onlyGovernor {
        uint256 amount = FLOOR.balanceOf(address(this));
        FLOOR.transfer(msg.sender, amount);
    }
}