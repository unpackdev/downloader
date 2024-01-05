// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
import "./IDeltaToken.sol";
import "./IDeltaDistributor.sol";
import "./SafeMath.sol";

contract DELTA_Deep_Vault_Withdrawal {
    // masterCopy always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private masterCopy;
    uint256 private ______gap;
    using SafeMath for uint256;

    /// @notice The person who owns this withdrawal and can withdraw at any moment
    address public OWNER;
    /// @notice Seconds it takes to mature anything above the principle
    uint256 public MATURATION_TIME_SECONDS;
    /// @notice Principle DELTA which is the withdrawable amount without maturation
    /// Because we just mature stuff thats above claim
    uint256 public PRINCIPLE_DELTA;
    uint256 public VESTING_DELTA;
    bool public everythingWithdrawed;
    bool public principleWithdrawed;
    bool public emergency;

    // Those variables are private and only gotten with getters, to not shit up the etherscan page
    /// @dev address of the delta token
    IDeltaToken private DELTA_TOKEN;
    /// @dev address of the rlp token
    /// @dev the block timestamp at the moment of calling the constructor
    uint256 private CONSTRUCTION_TIME;

    constructor () {
        // Renders the master copy unusable
        // Proxy does not call the constructor
        OWNER = address(0x1);
    }

    function intitialize (
        address _owner,
        uint256 _matuartionTimeSeconds,
        uint256 _principledDelta, // Principle means the base amount that doesnt mature.
        IDeltaToken delta
    ) public {
        require(OWNER == address(0), "Already initialized");
        require(_owner != address(0), "Owner cannot be 0");
        require(_matuartionTimeSeconds > 0, "Maturation period is nessesary");

        DELTA_TOKEN = delta;
        OWNER = _owner;

        uint256 deltaBalance = delta.balanceOf(address(this));
        require(deltaBalance >= _principledDelta, "Did not get enough DELTA");
        VESTING_DELTA = deltaBalance - _principledDelta;
        MATURATION_TIME_SECONDS = _matuartionTimeSeconds; 

        PRINCIPLE_DELTA = _principledDelta;
        CONSTRUCTION_TIME = block.timestamp;
    } 

    function deltaDistributor() public view returns(IDeltaDistributor distributor) {
        distributor = IDeltaDistributor(DELTA_TOKEN.distributor());
        require(address(distributor) != address(0), "Distributor is not set");
    }

    function secondsLeftToMature() public view returns (uint256) {
        uint256 targetTime = CONSTRUCTION_TIME + MATURATION_TIME_SECONDS;
        if(block.timestamp > targetTime) { return 0; }
        return targetTime - block.timestamp;
    }

    function secondsLeftUntilPrincipleUnlocked() public view returns (uint256) {
        uint256 targetTime = CONSTRUCTION_TIME + 14 days;
        if(block.timestamp > targetTime) { return 0; }
        return targetTime - block.timestamp;
    }

    function onlyOwner() internal view {
        require(msg.sender == OWNER, "You are not the owner of this withdrawal contract");
    }

    // Allows the owner of this contract to grant permission to delta governance to withdraw 
    function toggleEmergency(bool isInEmergency) public {
        onlyOwner();
        emergency = isInEmergency;
    }

    function withdrawTokensWithPermissionFromOwner(address token, address recipent, uint256 amount) public {
        require(msg.sender == DELTA_TOKEN.governance()); // Only delta governance can call this
        require(emergency); // Checks the owner activated emergency
        IERC20(token).transfer(recipent, amount);
    }

    function withdrawPrinciple() public {
        onlyOwner();
        require(!principleWithdrawed, "Principle was already withdrawed");
        require(block.timestamp > CONSTRUCTION_TIME + 14 days, "You need to wait 14 days to withdraw principle");
        // Send the principle
        DELTA_TOKEN.transfer(msg.sender, PRINCIPLE_DELTA);

        principleWithdrawed = true;
    }

    /// @notice this will check the matured tokens and remove the balance that isnt matured back to the deep farming vault to pickup spread across all farmers
    function withdrawEverythingWithdrawable() public {
        onlyOwner();
        require(!everythingWithdrawed, "Already withdrawed");
        uint256 deltaDue = withdrawableTokens();
        // deltaDue has to be above becase it checks if principle was withdrawed. 
        // This fixes a bug where principle tokens were potentially burned
        if(!principleWithdrawed && PRINCIPLE_DELTA > 0) {
            require(block.timestamp > CONSTRUCTION_TIME + 14 days, "You need to wait 14 days to withdraw principle");
            principleWithdrawed = true;
        }

        DELTA_TOKEN.transfer(msg.sender, deltaDue);
        uint256 leftOver = DELTA_TOKEN.balanceOf(address(this));

        IDeltaDistributor distributor = deltaDistributor();//Reverts if its not set.

        if(leftOver > 0) { 
            DELTA_TOKEN.approve(address(distributor), leftOver);
            distributor.addDevested(msg.sender, leftOver);
        }
        everythingWithdrawed = true;
    }

    function withdrawableTokens() public view returns (uint256) {
        if(!principleWithdrawed) { // Principle was not extracted
            return maturedVestingTokens().add(PRINCIPLE_DELTA);
        } else {
            return maturedVestingTokens();
        }
    }

    function maturedVestingTokens() public view returns (uint256) {
        return VESTING_DELTA.mul(percentMatured()) / 100;
    }

    function percentMatured() public view returns (uint256) {
        // This function can happen only once and is irreversible
        // So we get the maturation here
        uint256 secondsToMaturity = secondsLeftToMature();
        uint256 percentMaturation =  100 - (((secondsToMaturity * 1e8) / MATURATION_TIME_SECONDS) / 1e6);
        /// 1000 seconds left to mature 
        /// Maturing time 10,000
        /// 1000 * 1e8 = 100000000000
        /// 100000000000/10,000 = 10000000
        /// we are left with float 0.1 percentage, which we would have to *100, so we divide by 1e6 to multiply by 100
        /// With 0 its 100 - 0

        /// @dev we mature 5% immidietly 
        if(percentMaturation < 5) {
            percentMaturation = 5;
        }

        return percentMaturation;
    }

    receive() external payable {
        revert("ETH not allowed");
    }

}


