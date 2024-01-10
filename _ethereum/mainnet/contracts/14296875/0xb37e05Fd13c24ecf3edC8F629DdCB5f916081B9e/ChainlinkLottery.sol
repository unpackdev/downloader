// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract ChainlinkLottery is VRFConsumerBase, Ownable {
    using SafeERC20 for IERC20;

    event RequestSent(uint256 indexed day, bytes32 requestId);
    event NumberDrawn(uint256 indexed day, bytes32 requestId, uint256 number);

    bytes32 private immutable keyHash;
    uint256 internal immutable fee;

    mapping(bytes32 => uint256) public requestIdToDay;
    mapping(uint256 => uint256) public draw;

    constructor(
        address _coordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_coordinator, _link) {
        keyHash = _keyHash;
        fee = _fee;
    }

    /// @dev this could be called multiple times and overwrite requestIdToDay. Intentionally left so in case something went wrong
    function getRandomNumber(uint256 day) public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, 'Not enough LINK');
        requestId = requestRandomness(keyHash, fee);
        requestIdToDay[requestId] = day;
        emit RequestSent(day, requestId);
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(msg.sender, LINK.balanceOf(address(this)));
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }('');
        require(success, 'Could not send eth back');
    }

    function withdrawERC20(address erc20) external onlyOwner {
        IERC20(erc20).safeTransfer(msg.sender, IERC20(erc20).balanceOf(address(this)));
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 day = requestIdToDay[requestId];
        draw[day] = randomness;
        emit NumberDrawn(day, requestId, randomness);
    }
}
