
pragma solidity 0.7.5;

import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IElysian.sol";

interface IVault {
    function depositReserves(uint value, address to) external returns (bool);
}

interface IPLYS {
    function burn(uint amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract ExercisePLYS is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // in hundreths i.e. 50 = 0.5%
    mapping(address => uint256) public percentCanVest;
    mapping(address => uint256) public amountClaimed;
    mapping(address => uint256) public maxAllowedToClaim;

    address public pLYS;
    address public LYS;
    address public DAI;
    address public treasury;

    constructor(address pLYS_, address lys_, address dai_, address treasury_) {
        pLYS = pLYS_;
        LYS = lys_;
        DAI = dai_;
        treasury = treasury_;
    }

    function setTreasury(address treasury_) external onlyOwner returns (bool) {
        treasury = treasury_;
        return true;
    }

    function setTerms(address vester, uint256 amountCanClaim, uint256 rate) external onlyOwner returns (bool) {
        require(amountCanClaim >= maxAllowedToClaim[vester], "Cannot lower amount claimable");
        require(rate >= percentCanVest[vester], "Cannot lower vesting rate");
        maxAllowedToClaim[vester] = amountCanClaim;
        percentCanVest[vester] = rate;
        return true;
    }

    function exercisePLYS(uint256 amountToExercise) external nonReentrant returns (bool) {
        require(getPLYSAbleToClaim(_msgSender()) >= amountToExercise, 'Not enough LYS vested');
        require(maxAllowedToClaim[_msgSender()] >= amountClaimed[_msgSender()].add(amountToExercise), 'Claimed over max');
        
        IERC20(DAI).transferFrom(_msgSender(), address(this), amountToExercise);
        IERC20(DAI).approve(treasury, amountToExercise);
        
        IVault(treasury).depositReserves( amountToExercise, _msgSender());
        require(IERC20(pLYS).balanceOf(_msgSender()) >= amountToExercise, "Not enough balance");

        IPLYS(pLYS).burnFrom(_msgSender(), amountToExercise);
        amountClaimed[_msgSender()] += amountToExercise;
        
        return true;
    }

    function getPLYSAbleToClaim(address vester) public view returns (uint256) {
        uint totalSupply = IElysian(LYS).totalSupply();
        uint firstTerm = percentCanVest[vester].mul(1e9);
        return totalSupply.mul(firstTerm.div(10000)).sub(amountClaimed[vester]);
    }
 
    
    function getTotalSupply() public view returns (uint) {
        uint totalSupply = IElysian(LYS).totalSupply();
        return totalSupply;
    }

    function getVestingTerms(address vester) public view returns (uint[2] memory) {
        return [maxAllowedToClaim[vester], percentCanVest[vester]];
    }
}