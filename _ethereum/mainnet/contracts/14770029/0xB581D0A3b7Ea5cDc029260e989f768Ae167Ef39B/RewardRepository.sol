// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract RewardRepository is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // CONTRACTS
    mapping(address => address) public farms;

    /* ========== MODIFIER ========== */

    modifier onlyFarms() {
        require(farms[msg.sender] != address(0), "Only farm can request transfer");
        _;
    }

    /* ========== VIEWS ================ */

    function balance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyFarms {
        require(_receiver != address(0), "Invalid address");
        require(farms[msg.sender] == _token, "Invalid request token");
        if (_amount > 0) {
            uint8 missing_decimals = 18 - ERC20(_token).decimals();
            IERC20(_token).safeTransfer(_receiver, _amount.div(10**missing_decimals));
        }
    }

    function ownerTransferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyOwner {
        require(_receiver != address(0), "Invalid address");
        if (_amount > 0) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    // Add new farm
    function addFarm(address farm_address, address reward_token) public onlyOwner {
        require(farms[farm_address] == address(0), "farmExisted");
        require(reward_token != address(0), "invalid reward token");
        farms[farm_address] = reward_token;
        emit FarmAdded(farm_address);
    }

    // Remove a farm
    function removeFarm(address farm_address) public onlyOwner {
        require(farms[farm_address] != address(0), "!farm");
        // Delete from the mapping
        delete farms[farm_address];
        emit FarmRemoved(farm_address);
    }

    function rescueToken(address _token) public onlyOwner {
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    event FarmAdded(address farm);
    event FarmRemoved(address farm);
    
}