// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./ERC721Holder.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";


/// @title mLootSweeper for TemporalLoots
/// @notice This contract allows mLoot holders within a range to voluntarily and irrevocably send their mLoots to the contract, and receive the opportunity to participate in a winAmount draw
/// @notice This contract has not been audited. Use at your own risk.  

contract mLootSweeper is Context, ReentrancyGuard, ERC721Holder {
    
    struct DepositInfo {
        address depositor;
        uint256 mLootId;
    }
    
    DepositInfo[] public depositInfo;

    address public mLootContractAddress = 0x1dfe7Ca09e99d10835Bf73044a23B73Fc20623DF;
    
    IERC721Enumerable public mLootContract;

    uint256 public mLootIdStart = 8001;
    uint256 public mLootIdEnd = 16000;

    uint256 public depositPrice = 5 * 10**15;  //0.005 ETH
    uint256 public drawSize = 100; // Frequency of mLoot deposits to allow a draw to be triggered
    uint256 public drawCount = 1;

    event DepositSingle(address indexed user, uint256 mLootId);
    event DepositMulti(address indexed user, uint256[] mLootId);
    event Winner(address indexed user, uint256 amount);

    constructor() {
        mLootContract = IERC721Enumerable(mLootContractAddress);
    }

    function _deposit(uint256 mLootId) internal {
        require(mLootId >= mLootIdStart && mLootId <= mLootIdEnd, "mLoot not within range");

        mLootContract.safeTransferFrom(_msgSender(), address(this), mLootId);

        depositInfo.push(DepositInfo(_msgSender(), mLootId));
    }

    // mLoots deposited to this contract CANNOT be returned!
    function mLootDeposit(uint256 mLootId) external payable nonReentrant{
        require(depositPrice <= msg.value, "Ether value sent is not correct");
        _deposit(mLootId);
        emit DepositSingle(_msgSender(), mLootId);
    }

    // mLoots deposited to this contract CANNOT be returned!
    function mLootMultiDeposit(uint256[] memory mLootId) external payable nonReentrant{
        require(depositPrice * mLootId.length <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < mLootId.length; i++){
            _deposit(mLootId[i]);
        }
        emit DepositMulti(_msgSender(), mLootId);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pickWinner() external nonReentrant{
        require(mLootContract.balanceOf(address(this)) >= (drawSize * drawCount), "Insufficient number of mLoots deposited to draw");
        drawCount += 1;

        uint256 rand = random(string(abi.encodePacked(_msgSender(), tx.gasprice, mLootContract.tokenByIndex(mLootContract.balanceOf(address(this))))));

        address winner = depositInfo[rand % depositInfo.length].depositor;

        uint256 winAmount;
        
        if (mLootContract.balanceOf(address(this)) >= (mLootIdEnd - mLootIdStart)) {
            winAmount = address(this).balance; // send full balance if we have collected all the mLoots in range
        } else {
            winAmount = address(this).balance / 2; // send half balance if we have not collected all the mLoots in range
        }

        payable(winner).transfer(winAmount);

        emit Winner(winner, winAmount);
               
    }





}