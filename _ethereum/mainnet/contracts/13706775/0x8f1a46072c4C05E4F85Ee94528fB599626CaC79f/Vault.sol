//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IStrat.sol";
import "./IVault.sol";
import "./DividendToken.sol";
import "./Ownable.sol";

contract Vault is Ownable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    IERC20Detailed public underlying;
    IStrat public strat;
    address public harvester;
    uint constant MAX_FEE = 10000;
    uint public performanceFee = 1000; 
    uint public lastDistribution;
    bool private isStratInitialized = false;

    constructor(IERC20Detailed underlying_, IERC20 reward_, address harvester_, string memory name_, string memory symbol_)
    DividendToken(reward_, name_, symbol_, underlying_.decimals())
    {
        underlying = underlying_;
        harvester = harvester_;
    }

    function initializeStrat(IStrat strat_) public {
        require(msg.sender == owner(), "ONLY_OWNER");
        require(!isStratInitialized, "Vault: ALREADY_INITIALIZED");
        strat = strat_;
        isStratInitialized = true;
    }

    function deposit(uint amount) public {
        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();
        _mint(msg.sender, amount);
    }

    function withdraw(uint amount) public {
        _burn(msg.sender, amount);
        strat.divest(amount);
        underlying.safeTransfer(msg.sender, amount);
    }

    function claim() public {
        withdrawDividend(msg.sender);
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) public {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function harvest(uint amount) public onlyHarvester returns (uint afterFee) {
        require(amount <= underlyingYield(), "AMOUNT_LARGER_THAN_GENERATED_YIELD");
        strat.divest(amount);
        if(performanceFee > 0) {
            uint fee = amount.mul(performanceFee).div(MAX_FEE);
            afterFee = amount.sub(fee);
            underlying.safeTransfer(owner(), fee);
        } else {
            afterFee = amount;
        }
        underlying.safeTransfer(harvester, afterFee);
    }

    function distribute(uint amount) public onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

    function underlyingYield() public returns (uint) {
        return calcTotalValue().sub(totalSupply());
    }

    function calcTotalValue() public returns (uint underlyingAmount) {
        return strat.calcTotalValue();
    }

    function unclaimedProfit(address user) public view returns (uint256) {
        return withdrawableDividendOf(user);
    }
    
    modifier onlyHarvester {
        require(msg.sender == harvester);
        _;
    }
}