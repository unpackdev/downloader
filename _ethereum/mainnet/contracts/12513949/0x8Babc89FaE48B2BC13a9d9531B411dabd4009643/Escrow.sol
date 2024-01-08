pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PRBMathUD60x18.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

import "./IOracleFactory.sol";
import "./IOracle.sol";

/**
 *  @title LMaaS Escrow contract
 *  @author Maximiliaan van Dijk - AllianceBlock
 *  @notice Allows the locking of UniswapV2 LiquidityPool tokens, in order to gain access to the Liquidity Mining as a Service platform. The pair must contain ALBT
*/
contract Escrow is Ownable, ReentrancyGuard {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    uint public price;
    uint public lockTime;
    IERC20 public immutable albtToken;
    IUniswapV2Factory public immutable uniswapV2Factory;
    IOracleFactory public immutable oracleFactory;
    IOracle public immutable albtOracle;

    struct EscrowData {
        address pair;
        bool withdrawn;
        uint amountDeposited;
        uint startTime;
    }

    mapping (address => EscrowData) public walletToEscrow;

    event EscrowPaid (address wallet);
    event EscrowWithdrawn (address wallet);

    /**
     * @dev Constructor defining the initial configuration
     * @param _price The required amount to be locked in ALBT, which gets converted to it's worth in LP tokens
     * @param _albtToken The ERC20 ALBT token address, in which the _price shall be paid
     * @param _lockTime The duration of the lock time in seconds.
     */
    constructor (uint _price, address _albtToken, uint _lockTime, address _uniswapV2FactoryAddress, address _oracleFactoryAddress) {
        price = _price;
        albtToken = IERC20(_albtToken);
        lockTime = _lockTime;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2FactoryAddress);
        oracleFactory = IOracleFactory(_oracleFactoryAddress);
        albtOracle = IOracle(IOracleFactory(_oracleFactoryAddress).pairedTokenAlbtOracleAddress());
    }

    /**
     * @dev Deposit the required LP tokens of a pair containing ALBT for escrow/locking
     * @param _userToken A user supplied ERC20 compliant token, for which there's sufficient ALBT(_price) in it's UniswapV2 Liquidity Pool.
     */
    function pay (address _userToken) public nonReentrant {
        address pairAddress = uniswapV2Factory
            .getPair(_userToken, address(albtToken));

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 erc20Pair = IERC20(pairAddress);
        uint nessecaryLpAmount = getNessecaryLpAmountV2(_userToken);

        require(
            pair.allowance(msg.sender, address(this)) >= nessecaryLpAmount,
            "LP allowance is less than nessecary"
        );

        require(
            walletToEscrow[msg.sender].pair == address(0),
            "Already paid for"
        );

        erc20Pair.safeTransferFrom(msg.sender, address(this), nessecaryLpAmount);

        walletToEscrow[msg.sender] = EscrowData({
            pair: pairAddress,
            withdrawn: false,
            amountDeposited: nessecaryLpAmount,
            startTime: block.timestamp
        });

        emit EscrowPaid (msg.sender);
    }

    /**
    * @dev Withdraw the deposited Liquidity Pool tokens from the contract, after they've been locked longer than the _lockTime.
    */
    function withdraw () public nonReentrant {
        EscrowData storage escrowData = walletToEscrow[msg.sender];
        IUniswapV2Pair pair = IUniswapV2Pair(escrowData.pair);

        require(
            block.timestamp >= escrowData.startTime + lockTime,
            "Deadline not met"
        );

        require(
            !escrowData.withdrawn,
            "Escrow already fulfilled"
        );

        escrowData.withdrawn = true;
        pair.transfer(msg.sender, escrowData.amountDeposited);

        emit EscrowWithdrawn (msg.sender);
    }

    function getFairReserves (address _userToken) public view returns (
        uint fairReserve0,
        uint fairReserve1
    ) {
        address pairAddress = uniswapV2Factory.getPair(_userToken, address(albtToken));
        address oracleAddress = oracleFactory.oracleByToken(_userToken);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IOracle oracle = IOracle(oracleAddress);

        (uint _reserve0, uint _reserve1,) = pair.getReserves();

        uint productK = uint(_reserve0).mul(uint(_reserve1));

        uint fairPriceToken = uint(
            oracle.consult(_userToken, 10 ** 18)
        );
        uint fairPriceAlbt = uint(
            albtOracle.consult(address(albtToken), 10 ** 18)
        );

        require(fairPriceToken != 0 && fairPriceAlbt != 0, "Oracle not updated");

        uint fairPriceRatio = fairPriceToken.div(fairPriceAlbt);

        uint albtReserve = productK.div(fairPriceRatio).sqrt();
        uint tokenReserve = productK.mul(fairPriceRatio).sqrt();

        bool token0IsAlbtToken = pair.token0() == address(albtToken);    

        fairReserve0 = token0IsAlbtToken ? albtReserve : tokenReserve;
        fairReserve1 = token0IsAlbtToken ? tokenReserve : albtReserve;
    }

    function getNessecaryLpAmountV2 (address _userToken) public view returns (uint) {
        address pairAddress = uniswapV2Factory.getPair(_userToken, address(albtToken));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address albtAddress = address(albtToken);

        (uint _reserve0, uint _reserve1) = getFairReserves(_userToken);
        uint albtReserve =
            pair.token0() == albtAddress ? uint(_reserve0) :
            pair.token1() == albtAddress ? uint(_reserve1)
            : 0;
        
        require(albtReserve >= price, "Pair doesn't contain ALBT or insufficient reserve");

        uint totalSupply = pair.totalSupply();
        uint calculationDecimals = 10 ** 18;
        uint pricePercentageOfReserve = (price * calculationDecimals) / albtReserve;
        uint nessecaryLp = totalSupply * pricePercentageOfReserve / calculationDecimals;

        return nessecaryLp;
    }

    /**
    * @dev Calculates the required amount of Liquidity Pool tokens of a ALBT/_userToken UniswapV2 pair. Left for backwards compatibility with the frontend.
    * @param _lpAddress The liquidity pool's address, containing both ALBT and user's ERC20 token.
    */
    function getNessecaryLpAmount (address _lpAddress) public view returns (uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(_lpAddress);
        address albtAddress = address(albtToken);
        address userToken = pair.token0() == address(albtToken) ? pair.token1() : pair.token0();

        return getNessecaryLpAmountV2(userToken);
    }

    /**
     * @dev Allows the owner of the contract to change the required amount of ALBT tokens
     * @param _newPrice The new amount of ALBT tokens that need to be locked
     */
    function changePrice (uint _newPrice) public onlyOwner {
        price = _newPrice;
    }

    /**
     * @dev Allows the owner of the contract to change the amount of time the liquidity pool's tokens need to be locked
     * @param _lockTime The newly required time the tokens need to be locked
     */
    function changeLockTime(uint _lockTime) public onlyOwner {
        lockTime = _lockTime;
    }
}