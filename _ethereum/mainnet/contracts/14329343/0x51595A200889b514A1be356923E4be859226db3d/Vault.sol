// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Address.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IOwnable.sol";
import "./ITreasury.sol";
import "./IBondingCalculator.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Mintable {
    function transfer(address to, uint value) external returns (bool);
    function mint(uint256 amount_) external;
    function mint(uint256 amount_, address account_, bool isEscrowed) external;
}

contract Vault is ITreasury, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event TimelockStarted(uint timelockEndBlock);

    bool public isInitialized;
    uint public timelockDurationInBlocks;
    bool public isTimelockSet;
    uint public override getTimelockEndBlock;

    address public daoWallet;
    address public LPRewardsContract;
    address public stakingContract;

    uint public LPProfitShare;

    uint public getPrincipleTokenBalance;

    address public override getManagedToken;
    address public getReserveToken;
    address public getPrincipleToken;

    address public override getBondingCalculator;

    mapping(address => bool) public isReserveToken;
    mapping(address => bool) public isPrincipleToken;
    mapping(address => bool) public isPrincipleDepositor;
    mapping(address => bool) public isReserveDepositor;

    constructor(address owner) public Ownable(owner) {
        isInitialized = false;
    }

    modifier notInitialized {
        require(!isInitialized);
        _;
    }

    modifier onlyReserveToken(address reserveTokenChallenge_) {
        require(isReserveToken[reserveTokenChallenge_] == true, "Vault: reserveTokenChallenge_ is not a reserve Token.");
        _;
    }

    modifier onlyPrincipleToken(address PrincipleTokenChallenge_) {
        require(isPrincipleToken[PrincipleTokenChallenge_] == true, "Vault: PrincipleTokenChallenge_ is not a Principle token.");
        _;
    }

    modifier notTimelockSet {
        require(!isTimelockSet);
        _;
    }

    modifier isTimelockExpired {
        require(getTimelockEndBlock != 0);
        require(isTimelockSet);
        require(block.number >= getTimelockEndBlock);
        _;
    }

    modifier isTimelockStarted() {
        if (getTimelockEndBlock != 0) {
            emit TimelockStarted(getTimelockEndBlock);
        }
        _;
    }

    function setDAOWallet(address newDAOWallet_) external onlyOwner returns (bool) {
        daoWallet = newDAOWallet_;
        return true;
    }

    function setStakingContract(address newStakingContract_) external onlyOwner returns (bool) {
        stakingContract = newStakingContract_;
        return true;
    }

    function setLPRewardsContract(address newLPRewardsContract_) external onlyOwner returns (bool) {
        LPRewardsContract = newLPRewardsContract_;
        return true;
    }

    function setLPProfitShare(uint newDAOProfitShare_) external onlyOwner returns (bool) {
        LPProfitShare = newDAOProfitShare_;
        return true;
    }

    function initialize(
        address newManagedToken_,
        address newReserveToken_,
        address newBondingCalculator_,
        address newLPRewardsContract_
    )
        external
        onlyOwner
        notInitialized
        returns (bool)
    {
        getManagedToken = newManagedToken_;
        getReserveToken = newReserveToken_;
        isReserveToken[newReserveToken_] = true;
        getBondingCalculator = newBondingCalculator_;
        LPRewardsContract = newLPRewardsContract_;
        isInitialized = true;
        return true;
    }

    function setPrincipleToken(address newPrincipleToken_)
        external
        onlyOwner
        returns (bool)
    {
        getPrincipleToken = newPrincipleToken_;
        isPrincipleToken[newPrincipleToken_] = true;
        return true;
    }

    function setPrincipleDepositor(address newDepositor_)
        external
        onlyOwner
        returns (bool)
    {
        isPrincipleDepositor[newDepositor_] = true;
        return true;
    }

    function setReserveDepositor(address newDepositor_)
        external
        onlyOwner
        returns (bool)
    {
        isReserveDepositor[newDepositor_] = true;
        return true;
    }

    function removePrincipleDepositor(address depositor_)
        external
        onlyOwner
        returns (bool)
    {
        isPrincipleDepositor[depositor_] = false;
        return true;
    }

    function removeReserveDepositor(address depositor_)
        external
        onlyOwner
        returns (bool)
    {
        isReserveDepositor[depositor_] = false;
        return true;
    }

    function rewardsDepositPrinciple( uint depositAmount_ ) external returns ( bool ) {
        require(isReserveDepositor[msg.sender], "Not allowed to deposit");
        address principleToken = getPrincipleToken;
        IERC20(principleToken).safeTransferFrom(msg.sender, address(this), depositAmount_);
        uint value = IBondingCalculator(getBondingCalculator).principleValuation(principleToken, depositAmount_) / 1e9;
        uint forLP = value / LPProfitShare;
        IERC20Mintable(getManagedToken).mint(value - forLP, stakingContract, false);
        IERC20Mintable(getManagedToken).mint(forLP, LPRewardsContract, false);
        return true;
    }

    function depositReserves(uint amount_, address dst) external returns (bool) {
        require(isReserveDepositor[msg.sender] == true, "Not allowed to deposit");
        IERC20(getReserveToken).transferFrom( msg.sender, address(this), amount_);
        uint mintable = amount_.div(1e9);
        IERC20Mintable(getManagedToken).mint(mintable, dst, false);
        return true;
    }
 
    function depositPrinciple(uint depositAmount_) external returns (bool) {
        require(isPrincipleDepositor[msg.sender], "Not allowed to deposit");
        address principleToken = getPrincipleToken;
        IERC20(principleToken).safeTransferFrom(msg.sender, address(this), depositAmount_);
        uint value = IBondingCalculator(getBondingCalculator).principleValuation(principleToken, depositAmount_) / 1e9;
        IERC20Mintable(getManagedToken).mint(value, msg.sender, false);
        return true;
    }

    function migrateReserves()
        external
        onlyOwner
        //isTimelockExpired
        returns (bool saveGas_)
    {
        uint reserveTokenBalance = IERC20(getReserveToken).balanceOf(address(this));
        
        if (reserveTokenBalance > 0) {
            IERC20(getReserveToken).safeTransfer(daoWallet, reserveTokenBalance);
        }

        return true;
    }

    function migratePrinciple()
        external
        onlyOwner
        //isTimelockExpired
        returns (bool saveGas_)
    {
        uint principleTokenBalance = IERC20(getPrincipleToken).balanceOf(address(this));

        if (principleTokenBalance > 0) {
            IERC20(getPrincipleToken).safeTransfer(daoWallet, principleTokenBalance);
        }
        return true;
    }

    function setTimelock(uint newTimelockDurationInBlocks_)
        external
        onlyOwner
        notTimelockSet
        returns (bool)
    {
        timelockDurationInBlocks = newTimelockDurationInBlocks_;
        return true;
    }

    function startTimelock()
        external
        onlyOwner
        returns (bool)
    {
        getTimelockEndBlock = block.number + timelockDurationInBlocks;
        isTimelockSet = true;
        emit TimelockStarted(getTimelockEndBlock);
        return true;
    }
}