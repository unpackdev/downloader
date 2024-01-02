// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IAcross.sol";

contract AcrossToArb is OwnableUpgradeable {
    address public constant BRIDGE = 0x269727F088F16E1Aea52Cf5a97B1CD41DAA3f02D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public feeMultiplier;
    uint256 public feeIncrementer;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
        feeMultiplier = 10 ** 6;
        feeIncrementer = 0.01 ether;
    }

    function setFeeMultiplier(uint256 newFeeMultiplier) public onlyOwner {
        feeMultiplier = newFeeMultiplier;
    }

    function setFeeIncrementer(uint256 newfeeIncrementer) public onlyOwner {
        feeIncrementer = newfeeIncrementer;
    }

    receive() external payable {
        int64 relayerFeePct = int64(
            int256((tx.gasprice * feeMultiplier) + feeIncrementer)
        );

        IAcross(BRIDGE).deposit{value: msg.value}(
            msg.sender,
            WETH,
            msg.value,
            42161,
            relayerFeePct,
            uint32(block.timestamp),
            "",
            type(uint256).max
        );
    }
}
