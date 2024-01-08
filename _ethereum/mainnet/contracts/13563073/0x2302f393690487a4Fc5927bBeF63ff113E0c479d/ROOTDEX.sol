// SPDX-License-Identifier: Unlicense

/* 
    Name: Rootkit-EmpireDEX
    Ticker: ROOTDEX
    Max supply: 10,000 ROOTDEX
    LGE: 5,000 ROOTDEX 
    LGE bonus: 250 ROOTDEX
    Farming: 2,750 ROOTDEX (over 12 months) 
    Team tokens: 500 ROOTDEX (for Rootkit team), 500 ROOTDEX for EmpireDEX team) 
    Snapshots: 500 ROOTDEX airdropped to ROOT holders, 500 ROOTDEX airdropped to EMPIRE holders (tokens dispersed after 6 month vesting period)

    https://rookit.finance + https://empiredex.org
    
*/

pragma solidity =0.6.8;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./DSMath.sol";

import "./IEmpireFactory.sol";
import "./IEmpirePair.sol";
import "./IEmpireRouter.sol";
import "./IWETH.sol";

contract ROOTDEX is ERC20, Ownable {
    using DSMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    enum MigrationPhase {
        SETUP,
        STARTED,
        ENDED
    }

    IEmpireFactory public factory;

    uint256 public totalRaised;
    mapping(address => uint256) public contributions;
    address public empireWethPair;
    uint256 public end;
    MigrationPhase public migrationPhase;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant empireTeam = address(0x5ABBd94bb0561938130d83FdA22E672110e12528);
    address public constant rootkitTeam = address(0x804CC8D469483d202c69752ce0304F71ae14ABdf);

    address public constant REWARD_TREASURY = address(0x3F9B7da1d832199b2dD23670F2623193636f2e88);
    uint256 private constant EMPIRE_PERCENTAGE = 0.05 ether; // 5%
    uint256 private constant ROOTKIT_PERCENTAGE = 0.05 ether; // 5% 
    uint256 private constant BURN_FEE = 0.001 ether; // 0.1% burn on each transfer

    event Contribution(address indexed contributor, uint256 contribution);

    modifier correctPhase(MigrationPhase phase) {
        require(migrationPhase == phase, "EmpireV2::correctPhase: Invalid Phase!");
        _;
    }

    modifier saleActive() {
        require(
            end != 0,
            "Empire::saleActive: Sale hasn't started yet!"
        );
        require(
            block.timestamp <= end,
            "Empire::saleActive: Sale has ended!"
        );
        _;
    }

    modifier onlyPair() {
        require(
            msg.sender == empireWethPair,
            "Empire::onlyPair: Insufficient Privileges"
        );
        _;
    }

    constructor() public ERC20("Rootkit-EmpireDEX", "ROOTDEX") Ownable() {
    }

    function replayDeposits(address[] calldata contributors, uint256[] calldata amounts) external onlyOwner() {
        require(contributors.length == amounts.length, "Empire::replayDeposits: Incorrect Arguments");
        for (uint256 i = 0; i < contributors.length; i++) {
            contributions[contributors[i]] = amounts[i];
            emit Contribution(contributors[i], amounts[i]);
        }
    }

    function beginLGE(IEmpireFactory _factory) external onlyOwner() {
        factory = _factory;
        end = block.timestamp + 6 days;
        PairType pairType =
            address(this) < WETH
                ? PairType.SweepableToken1
                : PairType.SweepableToken0;
        empireWethPair = _factory.createPair(WETH, address(this), pairType, 0);
    }

    function deposit() public payable saleActive() {
        contributions[msg.sender] += msg.value;
        emit Contribution(msg.sender, msg.value);
    }

    function migrateETH() external payable onlyOwner() correctPhase(MigrationPhase.SETUP) {
        migrationPhase = MigrationPhase.STARTED;
    }

    function complete() external onlyOwner() {
        require(
            block.timestamp > end && end != 0,
            "Empire::complete: Sale not complete yet!"
        );
        uint256 _totalRaised = totalRaised = address(this).balance;
        uint256 empireAllocation = _totalRaised.wmul(EMPIRE_PERCENTAGE); // 5%
        uint256 rootkitAllocation = _totalRaised.wmul(ROOTKIT_PERCENTAGE); // 5%

        payable(empireTeam).sendValue(empireAllocation);
        payable(rootkitTeam).sendValue(rootkitAllocation);

        _totalRaised = address(this).balance;

        IWETH(WETH).deposit{value: _totalRaised}();

        _mint(empireWethPair, 5000 * 1 ether); //  50% / 5000 for LGE

        IERC20(WETH).safeTransfer(empireWethPair, _totalRaised);

        IEmpirePair(empireWethPair).mint(address(this));

        _mint(address(this), 250 * 1 ether); // 2.5% / 250 bonus ROOTDEX tokens for contributors

        _mint(empireTeam, 500 * 1 ether); // 5% / 500 for the EMPIRE team

        _mint(rootkitTeam, 1000 * 1 ether); // 5% / 1000 for the ROOTKIT team and airdrop

        _mint(REWARD_TREASURY, 3250 * 1 ether); // 27.5% / 3250 Reserved for future rewards and airdrop
    
        if (totalRaised == 0) migrationPhase = MigrationPhase.ENDED;
    }

    function claim() external {
        require(
            contributions[msg.sender] > 0,
            "Empire::claim: No contribution detected!"
        );
        uint256 _totalRaised = totalRaised;
        uint256 _contribution = contributions[msg.sender];

        totalRaised = totalRaised.sub(_contribution);
        delete contributions[msg.sender];

        IERC20(empireWethPair).safeTransfer(
            msg.sender,
            IERC20(empireWethPair)
                .balanceOf(address(this))
                .mul(_contribution)
                .div(_totalRaised)
        );

        _transfer(
            address(this),
            msg.sender,
            balanceOf(address(this)).mul(_contribution).div(_totalRaised)
        );
    }

    function sweep(uint256 amount, bytes calldata data) external onlyOwner() {
        IEmpirePair(empireWethPair).sweep(amount, data);
    }

    function empireSweepCall(uint256 amount, bytes calldata) external onlyPair() {
        IERC20(WETH).safeTransfer(owner(), amount);
    }

    function unsweep(uint256 amount) external onlyOwner() {
        IERC20(WETH).approve(empireWethPair, amount);
        IEmpirePair(empireWethPair).unsweep(amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 burned;
        if (from != empireWethPair && to != empireWethPair) {
            burned = amount.wmul(BURN_FEE);
            _burn(from, burned);
        }
        _transfer(from, to, amount - burned);
        _approve(from, msg.sender, allowance(from, msg.sender).sub(amount, "ERC20: transfer amount exceeds"));
        return true;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        if (msg.sender != empireWethPair && to != empireWethPair) {
            uint256 burned = amount.wmul(BURN_FEE);
            amount -= burned;
            _burn(msg.sender, burned);
        }
        return super.transfer(to, amount);
    }

    function upgradePair(IEmpireFactory _factory) external onlyOwner() {
        PairType pairType =
            address(this) < WETH
                ? PairType.SweepableToken1
                : PairType.SweepableToken0;
        empireWethPair = _factory.createPair(WETH, address(this), pairType, 0);
    }

    receive() external payable {
        deposit();
    }
}
