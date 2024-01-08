// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "./IERC20.sol";
import "./IDelegableERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";


contract TeamPoolPACT is Ownable{
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event Withdraw(uint tokensAmount);

    address public _PACT;
    uint constant oneYear = 365 days;

    uint[2][4] private annualSupplyPoints = [
        [block.timestamp, 12500000e18],
        [block.timestamp.add(oneYear.mul(1)), 12500000e18],
        [block.timestamp.add(oneYear.mul(2)), 12500000e18],
        [block.timestamp.add(oneYear.mul(3)), 12500000e18]
    ];
 
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner (`ownerAddress`) 
     * and pact contract address (`PACT`).
     */
    constructor (
        address ownerAddress,
        address PACT
    ) public {
        require (PACT != address(0), "PACT ADDRESS SHOULD BE NOT NULL");
        _PACT = PACT;
        transferOwnership(ownerAddress == address(0) ? msg.sender : ownerAddress);
        IDelegableERC20(_PACT).delegate(ownerAddress);
    }

    
    /**
     * @dev Returns the annual supply points of the current contract.
     */
    function getReleases() external view returns(uint[2][4] memory) {
        return annualSupplyPoints;
    } 

    /**
     * @dev Withdrawal tokens the address  (`to`) and amount (`amount`).
     * Can only be called by the current owner.
    */
    function withdraw(address to,uint amount) external onlyOwner {
        IERC20 PACT = IERC20(_PACT);
        require (to != address(0), "ADDRESS SHOULD BE NOT NULL");
        require(amount <= PACT.balanceOf(address(this)), "NOT ENOUGH PACT TOKENS ON TEAMPOOL CONTRACT BALANCE");
        for(uint i; i < 4; i++) {
            if(annualSupplyPoints[i][1] >= amount && block.timestamp >= annualSupplyPoints[i][0]) {
               annualSupplyPoints[i][1] = annualSupplyPoints[i][1].sub(amount);
               PACT.safeTransfer(to, amount);
               return ;
            }
        }
        require (false, "TokenTimelock: no tokens to release");              
    }

}