// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IWETH.sol";

interface INPC {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract NPCTreasury is ReentrancyGuard {
    INPC public npc; // nft contract address
    address public weth; // weth address for situations where token holder cant accept ETH, i.e contract without payable fallback function

    uint256 immutable dissolutionTime;
    uint256 public lastTransferred;
    Status public dissolutionStatus;

    enum Status { Pending, InProgress, Completed }
    event Dissolution ( Status indexed statusOfDissolution);

    constructor(INPC _npcAddress, address _weth) {
        npc = _npcAddress;
        weth = _weth;
        dissolutionTime = block.timestamp + 266 days;
    }

    function dissolution() external nonReentrant returns(Status status) {
        require(block.timestamp >= dissolutionTime, "Dissolution time not reached");
        require(dissolutionStatus != Status.Completed, "Dissolution completed");

        uint256 totalNPCs = npc.totalSupply();
        uint256 balance = address(this).balance;

        if(balance > 0){
            uint256 payout = balance / (totalNPCs - lastTransferred);
            uint256 i = lastTransferred > 0 ? lastTransferred : 0;

            while (gasleft() > 60000 && i < totalNPCs){
                _safeTransferETHWithFallback(npc.ownerOf(npc.tokenByIndex(i)), payout);
                i++;
            }

            if (i == totalNPCs){
                dissolutionStatus = Status.Completed;
                emit Dissolution(dissolutionStatus);
                return dissolutionStatus;
            }

            lastTransferred = i;
            dissolutionStatus = Status.InProgress;
            emit Dissolution(dissolutionStatus);
            return dissolutionStatus;
        }
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    receive() external payable {}
}