// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./FeeDistributorLike.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";
import "./ABDKMathQuad.sol";
import "./PriceOracle.sol";

contract LiquidVault is Ownable {
    using SafeMath for uint;
    using ABDKMathQuad for bytes16;

    LiquidVaultConfig public config;
    BuyPressureVariables public calibration;
    LockPercentageVariables public lockPercentageCalibration;

    address public treasury;
    mapping(address => LPbatch[]) public lockedLP;
    mapping(address => uint) public queueCounter;

    bool private locked;
    bool public forceUnlock;
    bool public batchInsertionFinished;

    // lock period constants
    bytes16 internal constant LMAX_LMIN = 0x4014d010000000000000000000000000; // Lmax - Lmin
    bytes16 internal constant BETA = 0xc03a4d1120d7b1600000000000000000; // // -beta = -0.75
    bytes16 internal constant LMIN = 0x400f5180000000000000000000000000; // Lmin

    // buy pressure constants
    bytes16 internal constant MAX_FEE = 0x40044000000000000000000000000000; // 40%

    // lock percentage constants
    bytes16 internal constant ONE_BYTES = 0x3fff0000000000000000000000000000; // 1
    bytes16 internal constant ONE_TOKEN_BYTES = 0x403abc16d674ec800000000000000000; // 1e18

    struct LPbatch {
        address holder;
        uint amount;
        uint timestamp;
        bool claimed;
    }

    struct LiquidVaultConfig {
        IERC20 R3T;
        IUniswapV2Router02 uniswapRouter;
        IUniswapV2Pair tokenPair;
        FeeDistributorLike feeDistributor;
        PriceOracle uniswapOracle;
        IWETH weth;
    }

    struct PurchaseLPVariables {
        uint ethFee;
        uint netEth;
        uint reserve1;
        uint reserve2;
    }

    struct BuyPressureVariables {
        bytes16 a;
        bytes16 b;
        bytes16 c;
        bytes16 d;
        uint maxReserves;
    }

    struct LockPercentageVariables {
        bytes16 dMax; // maximum lock percentage
        bytes16 p0; // normal price
        bytes16 d0; // normal permanent lock percentage
        bytes16 beta; // сalibration coefficient
    }

    // a user can hold multiple locked LP batches
    event LPQueued(
        address holder,
        uint amount,
        uint eth,
        uint r3t,
        uint timeStamp,
        uint lockPeriod
    );

    event LPClaimed(
        address holder,
        uint amount,
        uint timestamp,
        uint blackholeDonation,
        uint lockPeriod
    );

    constructor() {
        calibrate(
            0xbfcb59e05f1e2674d208f2461d9cb64e, // a = -3e-16
            0x3fde33dcfe54a3802b3e313af8e0e525, // b = 1.4e-10
            0x3ff164840e1719f7f8ca8198f1d3ed52, // c = 8.5e-5
            0x00000000000000000000000000000000, // d = 0
            500000e18 // maxReserves
        );

        calibrateLockPercentage(
            0x40014000000000000000000000000000, // dMax =  5
            0x3ff7cac083126e978d4fdf3b645a1cac, // p0 = 7e-3
            0x40004000000000000000000000000000, // d0 = 2.5
            0x40061db6db6db5a1484ad8a787aa1421 // beta = 142.857142857
        );
    }

    modifier lock {
        require(!locked, 'R3T: reentrancy violation');
        locked = true;
        _;
        locked = false;
    }

    function seed(
        IERC20 r3t,
        FeeDistributorLike _feeDistributor,
        IUniswapV2Router02 _uniswapRouter,
        IUniswapV2Pair _uniswapPair,
        address _treasury,
        PriceOracle _uniswapOracle
    ) public onlyOwner {
        require(address(config.R3T) == address(0), 'Already initiated');
        config.R3T = r3t;
        config.feeDistributor = _feeDistributor;
        config.tokenPair = _uniswapPair;
        config.uniswapRouter = _uniswapRouter;
        config.weth = IWETH(config.uniswapRouter.WETH());
        treasury = _treasury;
        config.uniswapOracle = _uniswapOracle;
    }

    function setOracleAddress(PriceOracle _uniswapOracle) external onlyOwner {
        require(address(_uniswapOracle) != address(0), 'Zero address not allowed');
        config.uniswapOracle = _uniswapOracle;
    }

    // Dev note: increase gasLimit to be able run up to 100 iterations
    function insertUnclaimedBatchFor(address[] memory _holders, uint[] memory _amounts, uint[] memory _timestamps) public onlyOwner {
        require(!batchInsertionFinished, "R3T: Manual batch insertion is no longer allowed.");
        require(
            _holders.length == _holders.length && _timestamps.length == _holders.length,
            "R3T: Batch arrays should have same length"
        );
        require(_holders.length <= 100, 'R3T: loop limitations reached');

        for (uint i = 0; i < _holders.length; i++) {
            lockedLP[_holders[i]].push(
                LPbatch({
                    holder: _holders[i],
                    amount: _amounts[i],
                    timestamp: _timestamps[i],
                    claimed: false
                })
            );
        }
    }

    function finishBatchInsertion() public onlyOwner {
        batchInsertionFinished = true;
    }

    function getLockedPeriod() external view returns (uint) {
        return _calculateLockPeriod();
    }

    function flushToTreasury(uint amount) public onlyOwner {
        require(treasury != address(0),'R3T: treasury not set');
        require(config.R3T.transfer(treasury, amount), 'Treasury transfer failed');
    }

    // splits the amount of ETH according to a buy pressure formula, swaps the splitted fee, 
    // and pools the remaining ETH with R3T to create LP tokens
    function purchaseLPFor(address beneficiary) public payable lock {
        require(msg.value > 0, 'R3T: eth required to mint R3T LP');
        config.feeDistributor.distributeFees();
        PurchaseLPVariables memory vars;
        uint ethFeePercentage = feeUINT();
        vars.ethFee = msg.value.mul(ethFeePercentage).div(1000);
        vars.netEth = msg.value.sub(vars.ethFee);

        (vars.reserve1, vars.reserve2, ) = config.tokenPair.getReserves();

        uint r3tRequired;
        if (address(config.R3T) < address(config.weth)) {
            r3tRequired = config.uniswapRouter.quote(
                vars.netEth,
                vars.reserve2,
                vars.reserve1
            );
        } else {
            r3tRequired = config.uniswapRouter.quote(
                vars.netEth,
                vars.reserve1,
                vars.reserve2
            );
        }

        uint balance = config.R3T.balanceOf(address(this));
        require(balance >= r3tRequired, 'R3T: insufficient R3T in LiquidVault');

        config.weth.deposit{value: vars.netEth}();
        address tokenPairAddress = address(config.tokenPair);
        config.weth.transfer(tokenPairAddress, vars.netEth);
        config.R3T.transfer(tokenPairAddress, r3tRequired);
        config.uniswapOracle.update();

        uint liquidityCreated = config.tokenPair.mint(address(this));

        if (vars.ethFee > 0) {
            address[] memory path = new address[](2);
            path[0] = address(config.weth);
            path[1] = address(config.R3T);

            config.uniswapRouter.swapExactETHForTokens{ value:vars.ethFee }(
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        lockedLP[beneficiary].push(
            LPbatch({
                holder: beneficiary,
                amount: liquidityCreated,
                timestamp: block.timestamp,
                claimed: false
            })
        );

        emit LPQueued(
            beneficiary,
            liquidityCreated,
            vars.netEth,
            r3tRequired,
            block.timestamp,
            _calculateLockPeriod()
        );
    }

    // send ETH to match with R3T tokens in LiquidVault
    function purchaseLP() public payable {
        purchaseLPFor(msg.sender);
    }

    // claimps the oldest LP batch according to the lock period formula
    function claimLP() public returns (bool)  {
        uint length = lockedLP[msg.sender].length;
        require(length > 0, 'R3T: No locked LP.');
        uint next = queueCounter[msg.sender];
        require(
            next < lockedLP[msg.sender].length,
            "R3T: nothing to claim."
        );
        LPbatch storage batch = lockedLP[msg.sender][next];
        uint globalLPLockTime = _calculateLockPeriod();
        require(
            block.timestamp - batch.timestamp > globalLPLockTime,
            'R3T: LP still locked.'
        );
        next++;
        queueCounter[msg.sender] = next;
        uint blackHoleShare = lockPercentageUINT();
        uint blackholeDonation = blackHoleShare.mul(batch.amount).div(1000);
        batch.claimed = true;
        emit LPClaimed(msg.sender, batch.amount, block.timestamp, blackholeDonation, globalLPLockTime);
        require(config.tokenPair.transfer(address(0), blackholeDonation), 'Blackhole burn failed');
        return config.tokenPair.transfer(batch.holder, batch.amount.sub(blackholeDonation));
    }

    function lockedLPLength(address holder) public view returns (uint) {
        return lockedLP[holder].length;
    }

    function getLockedLP(address holder, uint position)
        public
        view
        returns (
            address,
            uint,
            uint,
            bool
        )
    {
        LPbatch memory batch = lockedLP[holder][position];
        return (batch.holder, batch.amount, batch.timestamp, batch.claimed);
    }

    function _calculateLockPeriod() internal view returns (uint) {
        if (forceUnlock) {
            return 0;
        }
        address factory = address(config.tokenPair.factory());
        (uint etherAmount, uint tokenAmount) = UniswapV2Library.getReserves(factory, address(config.weth), address(config.R3T));
        
        require(etherAmount != 0 && tokenAmount != 0, 'Reserves cannot be zero.');
        
        bytes16 floatEtherAmount = ABDKMathQuad.fromUInt(etherAmount);
        bytes16 floatTokenAmount = ABDKMathQuad.fromUInt(tokenAmount);
        bytes16 systemHealth = floatEtherAmount.mul(floatEtherAmount).div(floatTokenAmount);

        return ABDKMathQuad.toUInt(
            ABDKMathQuad.add(
                ABDKMathQuad.mul(
                    LMAX_LMIN, // Lmax - Lmin
                    ABDKMathQuad.exp(
                        ABDKMathQuad.div(
                            systemHealth,
                            BETA // -beta = -0.75
                        )
                    )
                ),
                LMIN // Lmin
            )
        );
    }

    // Could not be canceled if activated
    function enableLPForceUnlock() public onlyOwner {
        forceUnlock = true;
    }

    function calibrate(bytes16 a, bytes16 b, bytes16 c, bytes16 d, uint maxReserves) public onlyOwner {
        calibration = BuyPressureVariables({
            a: a,
            b: b,
            c: c,
            d: d,
            maxReserves: maxReserves
        });
    }

    function calibrateLockPercentage(bytes16 dMax, bytes16 p0, bytes16 d0, bytes16 beta) public onlyOwner {
        lockPercentageCalibration = LockPercentageVariables({
            dMax: dMax,
            p0: p0,
            d0: d0,
            beta: beta
        });
    }

    function square(bytes16 number) internal pure returns (bytes16) {
        return number.mul(number);
    }

    function fee() public view returns (bytes16) {
        uint tokensInUniswapUint = config.R3T.balanceOf(address(config.tokenPair));

        if (tokensInUniswapUint >= calibration.maxReserves) {
            return MAX_FEE; // 40%
        }
        bytes16 tokensInUniswap = ABDKMathQuad.fromUInt(tokensInUniswapUint).div(ABDKMathQuad.fromUInt(1e18));

        bytes16 t_squared = square(tokensInUniswap);
        bytes16 t_cubed = t_squared.mul(tokensInUniswap);

        bytes16 term1 = calibration.a.mul(t_cubed);
        bytes16 term2 = calibration.b.mul(t_squared);
        bytes16 term3 = calibration.c.mul(tokensInUniswap);
        return term1.add(term2).add(term3).add(calibration.d);
    }

    function feeUINT() public view returns (uint) {
        uint multiplier = 10;
        return fee().mul(ABDKMathQuad.fromUInt(multiplier)).toUInt();
    }

    // d = dMax*(1/(b.p+1));
    function _calculateLockPercentage() internal view returns (bytes16) {
        bytes16 price = ABDKMathQuad.fromUInt(config.uniswapOracle.consult()).div(
            ONE_TOKEN_BYTES // 1e18
        );
        bytes16 denominator = lockPercentageCalibration.beta.mul(price).add(ONE_BYTES);
        return lockPercentageCalibration.dMax.div(denominator);
    }

    function lockPercentageUINT() public view returns (uint) {
        uint multiplier = 10;
        return _calculateLockPercentage().mul(ABDKMathQuad.fromUInt(multiplier)).toUInt();
    }
}