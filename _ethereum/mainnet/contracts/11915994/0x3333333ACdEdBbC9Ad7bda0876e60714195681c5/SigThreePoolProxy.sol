// SPDX-License-Identifier: MIT
// Fork of Swerve's YPoolDelegator https://etherscan.io/address/0x329239599afB305DA0A2eC69c58F8a6697F9F88d#code

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./SigToken.sol";

contract SigThreePoolProxy {
    uint256 constant N_COINS = 3;
    address[] public coins;
    uint256[] public balances;

    uint256 constant FEE_DENOMINATOR = 10* 10 ** 9;
    uint256 constant MAX_ADMIN_FEE = 10 * 10 ** 9; // 1%
    uint256 constant MAX_FEE = 5 * 10 ** 9;        // 0.5%
    uint256 public fee;
    uint256 public admin_fee;
    
    address public owner;
    address token;
    
    uint256 public initial_A;
    uint256 public future_A;
    uint256 public initial_A_time;
    uint256 public future_A_time;
    
    uint256 public admin_actions_deadline;
    uint256 public transfer_ownership_deadline;
    uint256 public future_fee;
    uint256 public future_admin_fee;
    address public future_owner;
    // fill the rest of current slot to fix https://github.com/vyperlang/vyper/issues/2270
    uint64 public slot_fill_0;
    uint32 public slot_fill_1;

    bool is_killed;
    uint256 kill_deadline;
    uint256 constant KILL_DEADLINE_DT = 2 * 30 * 86400;

    // following 3 variables aren't part of proxy implementation and go after all 3pool's variables
    address delegationTarget;
    address dutchAuction;
    SigToken sigToken;
    
    constructor(
        address _owner,
        address[N_COINS] memory _coinsIn,
        address _pool_token,
        uint256 _A,
        uint256 _fee,
        uint256 _admin_fee,
        // additional variables
        address _delegationTarget,
        address _dutchAuction,
        SigToken _sigToken
    ) public {
        for (uint256 i = 0; i < N_COINS; i++) {
            require(_coinsIn[i] != address(0));
            balances.push(0);
            coins.push(_coinsIn[i]);
        }
        initial_A = _A;
        future_A = _A;
        fee = _fee;
        admin_fee = _admin_fee;
        owner = _owner;
        is_killed = false;
        kill_deadline = block.timestamp + KILL_DEADLINE_DT;
        token = _pool_token;
        // gas can be optimized if used constant instead of variables
        delegationTarget = _delegationTarget;
        dutchAuction = _dutchAuction;
        sigToken = _sigToken;
    }

    // template from https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/Proxy.sol
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        //        // solhint-disable-next-line no-inline-assembly
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    fallback () external {
        _delegate(delegationTarget);
    }

    receive () external payable {}

    // this function can be called by anyone, but fees go directly to the auction
    function withdraw_admin_fees() public {
        for (uint256 i = 0; i < N_COINS; i++) {
            IERC20 coin = IERC20(coins[i]);
            uint256 value = IERC20(coin).balanceOf(address(this)) - balances[i];
            if (value > 0) {
                coin.transfer(dutchAuction, value);
            }
        }
    }

    function changeAuction(address newAuction) public {
        require(msg.sender == owner);
        dutchAuction = newAuction;
    }

    /**
    * @dev
    * The code below implements an additional exchange2 function, which does normal exchange delegate call
    * plus gives users some cashback, if possible
    */
    uint256 constant CASHBACK_EXCHANGE_THRESHOLD_0 = 1000e18; // at least 1000 stablecoins to get reward
    uint256 constant CASHBACK_SIG_LOW_AMOUNT = 30e18;
    uint256 constant CASHBACK_SIG_HIGH_AMOUNT = 100e18;
    uint256 constant CASHBACK_MAX_GAS_PRICE = 100e9; // 100 gwei

    uint256 startBlock;
    uint256 endBlock;
    int256 a;
    int256 c;

    /**
     * @notice Set parameters for cashback, such that
     *          availableCashbackEther(startBlock) = initCashback
     *          availableCashbackEther(endBlock) = totalCashback >= initCashback
     * @param _startBlock - first block of the cashback
     * @param _endBlock - last block of the cashback
     * @param initCashback - about of ETH cashback available at _startBlock
     * @param totalCashback - total amount of ETH available at _endBlock
     *
     */
    function setCashbackEther(
        uint256 _startBlock,
        uint256 _endBlock,
        int256 initCashback,
        int256 totalCashback
    ) public payable {
        require(msg.sender == owner, "msg.sender == owner");
        require(address(this).balance >= uint256(totalCashback), "balance < totalCashback");
        startBlock = _startBlock;
        endBlock = _endBlock;
        // t := (block.number - _startBlock) <=> t from 0 .. E
        // l(t) := a*t + b is a line, such
        // l(0) = a*0 + b = init
        // l(E) = a*E + b = total
        //
        // ethPerBlock*(block.number - _startBlock) + initCashback = totalCashback unlocked so far until block.number]
        //
        // B := contract balance(t = 0)
        // safe(t) - how much of balance is untouchable
        // safe(0) = B - init
        // safe(E) = B - total
        // safe(t) = B - l(t) = B - (a*t + b) = B-b - a*t;
        // allow to spend (t) = balance(t) - safe(t) = balance(t) - (B-b - a*t) = balance(t) - B+b + a*t =
        // = balance(t) + a*t + c, where c = b-B;
        // <=> c = init - balance(_startBlock);
        a = (totalCashback - initCashback) / int256(_endBlock - _startBlock);
        c = initCashback - int256(address(this).balance);
        // allow to spend (t) = balance(t) + a*t + c
    }

    /**
     * @notice how mush ETH is available for the cashback at the currBlock
     *      invariant: availableCashbackEther(t) <= address(this).balance
     *      to keep invariant: we **MUST** use address(this).balance in calc
     */
    function availableCashbackEther(uint256 currBlock) view public returns(uint256) {
        if (currBlock < startBlock || endBlock < currBlock) return 0;
        return uint256(int256(address(this).balance) + a * int256(currBlock - startBlock) + c);
    }
    /**
     * @notice how much cashback tx.origin would get if there's full funding
     */
    function entitledCashbackEther(uint256 txGasPrice) public view returns (uint256) {
        // people who trade via contract calc with 50% penalty
        uint256 sigBalance = (sigToken.balanceOf(tx.origin) + sigToken.balanceOf(msg.sender)) / 2;
        if (sigBalance < CASHBACK_SIG_LOW_AMOUNT) return 0;
        // level from 0 ... CASHBACK_SIG_HIGH_AMOUNT linear
        uint256 cashBackLevel = Math.min(sigBalance, CASHBACK_SIG_HIGH_AMOUNT);
        // does user use reasonable gasprice?
        uint256 gasPrice = Math.min(txGasPrice, CASHBACK_MAX_GAS_PRICE);
        // 100_000 gas units - maximum cashback
        uint256 gasUnitsCashback = (100_000 * cashBackLevel / CASHBACK_SIG_HIGH_AMOUNT);
        return gasUnitsCashback * gasPrice;
    }

    function payCashbackEther(int128 coinId, uint256 amount) private {
        // coinId = 0 => DAI(1e18), 1||2 => USDC||USDT(1e6), so make them all 1e18
        if (coinId != 0) amount *= 1e12;
        // to whom should we give cashback?
        if (amount >= CASHBACK_EXCHANGE_THRESHOLD_0) {
            // how much ETH are we ready to spend?
            uint256 availableEth = availableCashbackEther(block.number);
            // how much cashback to give?
            // use not all availableEth but some part that it depleted gradually rather than completely after certain payback
            uint256 cashback = Math.min(entitledCashbackEther(tx.gasprice), availableEth * 1/10);
            tx.origin.transfer(cashback);
        }
    }

    // the same code as of above function, but for view only
    function calcCashbackEther(int128 coinId, uint256 amount, uint256 txGasPrice) public view returns (uint256) {
        // coinId = 0 => DAI(1e18), 1||2 => USDC||USDT(1e6), so make them all 1e18
        if (coinId != 0) amount *= 1e12;
        // to whom should we give cashback?
        if (amount >= CASHBACK_EXCHANGE_THRESHOLD_0) {
            // how much ETH are we ready to spend?
            uint256 availableEth = availableCashbackEther(block.number);
            // how much cashback to give?
            // use not all availableEth but some part that it depleted gradually rather than completely after certain payback
            uint256 cashback = Math.min(entitledCashbackEther(txGasPrice), availableEth * 1/10);
            return cashback;
        }
        return 0;
    }

    function exchange2(int128 i, int128 j, uint256 dx, uint256 min_dy) public {
        (bool success, bytes memory result) = delegationTarget.delegatecall(
              abi.encodeWithSignature("exchange(int128,int128,uint256,uint256)", i, j, dx, min_dy)
            // signature of exchange(int128,int128,uint256,uint256) - 0x3df02124
        );
        if (!success) {
            if (result.length > 0) {
                revert(string(result));
            } else {
                revert();
            }
        }
        // give cashback
        payCashbackEther(i, dx);
    }

}
