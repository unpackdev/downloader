pragma solidity ^0.8.4;

import "./IERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";

interface Staking {
    function getUser(address userAddress) view external returns(uint[] memory, uint, uint);
}

contract Faker is Ownable {
    
    IERC20 suckerToken;
    IERC721A suckerContract;
    IERC721A saviorContract;
    Staking suckerStaking;
    Staking saviorStaking;

    uint256 amountForSavior = 1000000000 * 10 ** 18;
    uint256 amountForSuckers = 4000000000 * 10 ** 18;

    uint256 suckerNeeded = 2;
    uint256 saviorNeeded = 1;

    constructor(IERC721A _suckerContract, IERC721A _saviorContract, Staking _suckerStaking, Staking _saviorStaking, IERC20 _suckerToken) {
        suckerContract = _suckerContract; // 0xfcaecb01d2e095b2cf3e5293afd83bea5e9ff259
        saviorContract = _saviorContract; // 0xc92528b4ab6fd7c1f5012cd049c2a48e6a0400de
        suckerStaking = _suckerStaking; // 0x9bcedaeb7c087eb9328a2fffccfd2624fb54102a
        saviorStaking = _saviorStaking; // 0x7061d8654288d0bde0db559784dbabaf7e00a869
        suckerToken = _suckerToken; // 0x35bcf2b1c21562579c3d88ceb9d7149c96397545
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        bool checkSavior = saviorCheck(owner);
        bool checkSucker = suckerCheck(owner);
        if(checkSavior || checkSucker) {
            return 1;
        } else {
            return 0;
        }
    }

    function saviorCheck(address owner) internal view returns (bool) {
        uint256 balanceSuck = suckerToken.balanceOf(owner);
        uint256 balanceSaviors = saviorContract.balanceOf(owner);
        (uint[] memory amountStaked,,) = saviorStaking.getUser(owner);

        if((balanceSuck >= amountForSavior && balanceSaviors >= saviorNeeded) || (balanceSuck >= amountForSavior && amountStaked.length >= saviorNeeded)) {
            return true;
        } else {
            return false;
        }
    }

    function suckerCheck(address owner) internal view returns (bool) {
        uint256 balanceSuck = suckerToken.balanceOf(owner);
        uint256 balanceSuckers = suckerContract.balanceOf(owner);
        (uint[] memory amountStaked,,) = suckerStaking.getUser(owner);

        if((balanceSuck >= amountForSuckers && balanceSuckers >= suckerNeeded) || (balanceSuck >= amountForSuckers && amountStaked.length >= suckerNeeded)) {
            return true;
        } else {
            return false;
        }
    }

    function changeRequirements(uint256 _savior, uint256 _sucker, uint256 _saviorReq, uint256 _suckerReq) external onlyOwner {
        amountForSavior = _savior;
        amountForSuckers = _sucker;
        suckerNeeded = _suckerReq;
        saviorNeeded = _saviorReq;
    }

    function editCurrentTokens(IERC721A _suckerContract, IERC721A _saviorContract, Staking _suckerStaking, Staking _saviorStaking, IERC20 _suckerToken) external onlyOwner {
        suckerContract = _suckerContract; 
        saviorContract = _saviorContract; 
        suckerStaking = _suckerStaking; 
        saviorStaking = _saviorStaking;
        suckerToken = _suckerToken; 
    }
}