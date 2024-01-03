// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol"; // for WETH
import "./IUniswapV2Factory.sol";
import "./Initializable.sol";


contract FeeApprover is OwnableUpgradeSafe {
    using SafeMath for uint256;

    function initialize(
        address _RAMAddress,
        address _YGYAddress,
        address _uniswapFactory,
        address _ramVault
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();

        // Setup system addresses
        ramTokenAddress = _RAMAddress;
        ygyTokenAddress = _YGYAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(
            ygyTokenAddress,
            ramTokenAddress
        );

        // Fee perrcents
        feePercentX100 = 10; // 1%
        paused = true; // We start paused until sync post LGE happens.

        _editNoFeeList(_ramVault, true); // ramvault proxy
        _editNoFeeList(tokenUniswapPair, true);

        sync();
        minFinney = 5000;
    }

    address tokenUniswapPair;
    IUniswapV2Factory public uniswapFactory;
    address ramTokenAddress;
    address ygyTokenAddress;
    address ramVaultAddress;
    uint8 public feePercentX100; // max 255 = 25.5% artificial clamp
    uint256 public lastTotalSupplyOfLPTokens;
    bool paused;
    uint256 private lastSupplyOfRamInPair;
    uint256 private lastSupplyOfYgyInPair;
    mapping(address => bool) public noFeeList;

    // RAM token is pausable
    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
        sync();
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }

    function setRamVaultAddress(address _ramVaultAddress) public onlyOwner {
        ramVaultAddress = _ramVaultAddress;
        noFeeList[ramVaultAddress] = true;
    }

    function editNoFeeList(address _address, bool noFee) public onlyOwner {
        _editNoFeeList(_address, noFee);
    }

    function _editNoFeeList(address _address, bool noFee) internal {
        noFeeList[_address] = noFee;
    }

    uint256 minFinney; // 2x for $ liq amount

    function setMinimumLiquidityToTriggerStop(uint256 finneyAmnt)
        public
        onlyOwner
    {
        // 1000 = 1eth
        minFinney = finneyAmnt;
    }

    function sync() public returns (bool lastIsMint, bool lpTokenBurn) {
        // This will update the state of lastIsMint, when called publically
        // So we have to sync it before to the last LP token value.
        uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
        lpTokenBurn = lastTotalSupplyOfLPTokens > _LPSupplyOfPairTotal;
        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;

        uint256 _balanceYGY = IERC20(ygyTokenAddress).balanceOf(
            tokenUniswapPair
        );
        uint256 _balanceRAM = IERC20(ramTokenAddress).balanceOf(
            tokenUniswapPair
        );

        // Do not block after small liq additions
        // you can only withdraw 350$ now with front running
        // And cant front run buys with liq add ( adversary drain )
        lastIsMint =
            _balanceRAM > lastSupplyOfRamInPair &&
            _balanceYGY > lastSupplyOfYgyInPair.add(minFinney.mul(1 finney));

        lastSupplyOfRamInPair = _balanceRAM;
        lastSupplyOfYgyInPair = _balanceYGY;
    }

    function calculateAmountsAfterFee(
        address sender,
        address recipient, // unusued maybe use din future
        uint256 amount
    )
        public
        returns (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        )
    {
        require(paused == false, "FEE APPROVER: Transfers Paused");
        (bool lastIsMint, bool lpTokenBurn) = sync();

        if (sender == tokenUniswapPair) {
            // This will block buys that are immidietly after a mint. Before sync is called/
            // Deployment of this should only happen after router deployment
            // And addition of sync to all RamVault transactions to remove 99.99% of the cases.
            require(lastIsMint == false, "Liquidity withdrawals forbidden");
            require(lpTokenBurn == false, "Liquidity withdrawals forbidden");
        }

        if (noFeeList[sender]) {
            // Dont have a fee when ramvault is sending, or infinite loop
 // And when pair is sending ( buys are happening, no tax on it)
            transferToFeeDistributorAmount = 0;
            transferToAmount = amount;
        } else {
            transferToFeeDistributorAmount = amount.mul(feePercentX100).div(
                1000
            );
            transferToAmount = amount.sub(transferToFeeDistributorAmount);
        }
    }
}
