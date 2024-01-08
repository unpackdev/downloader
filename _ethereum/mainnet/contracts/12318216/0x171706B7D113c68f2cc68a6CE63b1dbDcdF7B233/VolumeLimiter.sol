// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./SafeMath.sol";
import "./AccessControl.sol";

abstract contract VolumeLimiter is AccessControl {
    using SafeMath for uint256;

    // datetime start of uniswap lauch
    uint256 public launchStartTime;

    // duration of timespan after launch where trading volume is limited
    uint256 public launchVolumeLimitDuration;

    // maxiumum swappable amount of tokens - per transaction -between launch and launch + duration
    uint256 public maxInitialTransactionCap = 12000000 * 10**18;

    // minimum swappable amount of tokens - per account - between launch and launch + duration
    uint256 public initialMinCap = 1200000 * 10**18;

    // maxiumum swappable amount of tokens - per account - between launch and launch + duration
    uint256 public initialHardCap = 360000000 * 10**18;

    // record of contributions between launch and launch + duration
    mapping(address => uint256) public initialContributions;

    constructor (
        uint256 _launchStartTime,
        uint256 _launchVolumeLimitDuration
    ) {
        // Declare internal variables
        launchStartTime = _launchStartTime;
        launchVolumeLimitDuration = _launchVolumeLimitDuration;
    }

    function preValidateTransaction(address from, address to, address uniswapPool, uint256 amount) internal virtual {

        // If the sender or recipient is the uniswap pair and the time is before launch, block transfer
        if (block.timestamp < launchStartTime) {
            // require(from != uniswapRouterAddress || to != uniswapRouterAddress, '[V0]'); // Sender cannot be the uniswap router before launch
            require(from != uniswapPool);
            require(to != uniswapPool);
        }

        // If the sender or recipient is the uniswap pair and the time is between launch and launch + duration, limit transfers
        if (block.timestamp >= launchStartTime
        && block.timestamp <= launchStartTime.add(launchVolumeLimitDuration)
        ) {
            // if the sender is the pair - add to the recipient's contributions
            if (from == uniswapPool) {
                _updatePurchasingState(to, amount);
            }

            // if the recipient is the pair - add to the senders's contributions
            if (to == uniswapPool) {
                _updatePurchasingState(from, amount);
            }
        }
    }
    
    function _updatePurchasingState(address beneficiary, uint256 amount) private {

        require(amount < maxInitialTransactionCap, 'TXE'); // Cannot swap more tokens than the limit at this time

        uint256 _existingContribution = initialContributions[beneficiary];
        uint256 _newContribution = _existingContribution.add(amount);

        // solhint-disable-previous-line no-empty-blocks
        require(_newContribution >= initialMinCap && _newContribution <= initialHardCap, 'CE'); // Transaction amount outside acceptable bounds

        // increase contributions mapping by transferred amount
        initialContributions[beneficiary] = _newContribution; 

    }

    // function changeUniswapRouterAddress(address _uniswapRouterAddress) external {
    //     // require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), '[0]'); // Caller is not admin
    //     require(_uniswapRouterModCounter <= 1, '[V4]'); // can no longer change the uniswap router address
    //     uniswapRouterAddress = payable(_uniswapRouterAddress);
    //     _uniswapRouterModCounter += 1;
    // }

    function hasLaunched() public view returns (bool) {
        return block.timestamp > launchStartTime;
    }

    function isLimitedTrading() public view returns (bool) {
        return block.timestamp >= launchStartTime && block.timestamp <= launchStartTime.add(launchVolumeLimitDuration);
    }

    function isFreeTrading() public view returns (bool) {
        return block.timestamp > launchStartTime.add(launchVolumeLimitDuration);
    }

    // function changeLaunchStartTime(uint256 _launchStartTime) external {
    //     require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // Caller is not admin
    //     launchStartTime = _launchStartTime;
    // }

    // function changeVolumeLimitDuration(uint256 _launchvolumeLimitDuration) external {
    //     require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())); // Caller is not admin
    //     launchVolumeLimitDuration = _launchvolumeLimitDuration;
    // }
}