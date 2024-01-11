// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;

import "./BLXMRewardProvider.sol";
import "./IBLXMRouter.sol";
import "./Initializable.sol";

import "./TransferHelper.sol";
import "./BLXMLibrary.sol";


contract BLXMRouter is Initializable, BLXMRewardProvider, IBLXMRouter {

    using SafeMath for uint;

    address public override BLXM;


    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    function initialize(address _BLXM) public initializer {
        __ReentrancyGuard_init();
        __BLXMMultiOwnable_init();
        
        updateRewardFactor(30, 1100000000000000000); // 1.1
        updateRewardFactor(60, 1210000000000000000); // 1.21
        updateRewardFactor(90, 1331000000000000000); // 1.331
        
        exclude[_BLXM] = true;
        BLXM = _BLXM;
    }

    function addRewards(address token, uint totalBlxmAmount, uint16 supplyDays) external override returns (uint amountPerHours) {
        TransferHelper.safeTransferFrom(BLXM, msg.sender, getTreasury(token), totalBlxmAmount);
        amountPerHours = _addRewards(token, totalBlxmAmount, supplyDays);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin
    ) private view returns (uint amountBlxm, uint amountToken) {
        _validateToken(token);

        uint ratio = getRatio(token);
        uint amountTokenOptimal = amountBlxmDesired.wdiv(ratio);
        if (amountTokenOptimal <= amountTokenDesired) {
            require(amountTokenOptimal >= amountTokenMin, 'INSUFFICIENT_BLXM_AMOUNT');
            (amountBlxm, amountToken) = (amountBlxmDesired, amountTokenOptimal);
        } else {
            uint amountBlxmOptimal = amountTokenDesired.wmul(ratio);
            assert(amountBlxmOptimal <= amountBlxmDesired);
            require(amountBlxmOptimal >= amountBlxmMin, 'INSUFFICIENT_TOKEN_AMOUNT');
            (amountBlxm, amountToken) = (amountBlxmOptimal, amountTokenDesired);
        }
    }

    function addLiquidity(
        address token,
        uint amountBlxmDesired,
        uint amountTokenDesired,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint16 lockedDays
    ) external override ensure(deadline) returns (uint amountBlxm, uint amountToken, uint liquidity) {
        (amountBlxm, amountToken) = _addLiquidity(token, amountBlxmDesired, amountTokenDesired, amountBlxmMin, amountTokenMin);
        address treasury = getTreasury(token);
        TransferHelper.safeTransferFrom(BLXM, msg.sender, treasury, amountBlxm);
        TransferHelper.safeTransferFrom(token, msg.sender, treasury, amountToken);
        liquidity = _mint(to, token, amountBlxm, amountToken, lockedDays);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        uint liquidity,
        uint amountBlxmMin,
        uint amountTokenMin,
        address to,
        uint deadline,
        uint idx
    ) public override ensure(deadline) returns (uint amountBlxm, uint amountToken, uint rewards) {
        // the reserves only can be transferred to the position owner right now
        require(msg.sender == to, 'WRONG_ADDRESS');
        (amountBlxm, amountToken, rewards) = _burn(to, liquidity, idx);
        require(amountBlxm >= amountBlxmMin, 'INSUFFICIENT_BLXM_AMOUNT');
        require(amountToken >= amountTokenMin, 'INSUFFICIENT_TOKEN_AMOUNT');
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}