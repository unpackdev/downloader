// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol"; // for WETH
import "./console.sol";
import "./IUniswapV2Factory.sol";
import "./Initializable.sol";

contract FeeApprover is OwnableUpgradeSafe {
    using SafeMath for uint256;

    function initialize(
        address _TSLAAddress,
        address _WETHAddress,
        address _uniswapFactory
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        tslaTokenAddress = _TSLAAddress;
        WETHAddress = _WETHAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(WETHAddress,tslaTokenAddress);
        feePercentX100 = 10;
        paused = true; // We start paused until sync post LGE happens.
        emergencyWithdrawLp = false; //start lp disable
        //_editNoFeeList(0xC5cacb708425961594B63eC171f4df27a9c0d8c9, true); // tslavault proxy
        _editNoFeeList(tokenUniswapPair, true);
        sync();
        minFinney = 5000;
    }


    address tokenUniswapPair;
    IUniswapV2Factory public uniswapFactory;
    address internal WETHAddress;
    address tslaTokenAddress;
    address tslaVaultAddress;
    uint8 public feePercentX100;  // max 255 = 25.5% artificial clamp
    uint256 public lastTotalSupplyOfLPTokens;
    bool paused;
    uint256 private lastSupplyOfTslaInPair;
    uint256 private lastSupplyOfWETHInPair;
    mapping (address => bool) public noFeeList;
    bool emergencyWithdrawLp;

    // TSLA token is pausable
    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
        sync();
    }

    function setEmergencyWithdrawLp(bool _emergencyWithdrawLp) public onlyOwner {
        emergencyWithdrawLp = _emergencyWithdrawLp;
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }

    function setTslaVaultAddress(address _tslaVaultAddress) public onlyOwner {
        tslaVaultAddress = _tslaVaultAddress;
        noFeeList[tslaVaultAddress] = true;
    }

    function editNoFeeList(address _address, bool noFee) public onlyOwner {
        _editNoFeeList(_address,noFee);
    }
    function _editNoFeeList(address _address, bool noFee) internal{
        noFeeList[_address] = noFee;
    }
    uint minFinney; // 2x for $ liq amount
    function setMinimumLiquidityToTriggerStop(uint finneyAmnt) public onlyOwner{ // 1000 = 1eth
        minFinney = finneyAmnt;
    }

    function sync() public returns (bool lastIsMint, bool lpTokenBurn) {

        // This will update the state of lastIsMint, when called publically
        // So we have to sync it before to the last LP token value.
        uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
        lpTokenBurn = lastTotalSupplyOfLPTokens > _LPSupplyOfPairTotal;
        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;

        uint256 _balanceWETH = IERC20(WETHAddress).balanceOf(tokenUniswapPair);
        uint256 _balanceTSLA = IERC20(tslaTokenAddress).balanceOf(tokenUniswapPair);

        // Do not block after small liq additions
        // you can only withdraw 350$ now with front running
        // And cant front run buys with liq add ( adversary drain )

        lastIsMint = _balanceTSLA > lastSupplyOfTslaInPair && _balanceWETH > lastSupplyOfWETHInPair.add(minFinney.mul(1 finney));

        lastSupplyOfTslaInPair = _balanceTSLA;
        lastSupplyOfWETHInPair = _balanceWETH;
    }


    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, // unusued maybe use din future
        uint256 amount
        ) public  returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount) 
        {
            require(paused == false, "FEE APPROVER: Transfers Paused");
            (bool lastIsMint, bool lpTokenBurn) = sync();

            if(sender == tokenUniswapPair) {
                // This will block buys that are immidietly after a mint. Before sync is called/
                // Deployment of this should only happen after router deployment 
                // And addition of sync to all TslaVault transactions to remove 99.99% of the cases.
                if(emergencyWithdrawLp == false){
                    require(lastIsMint == false, "Liquidity withdrawals forbidden");
                    require(lpTokenBurn == false, "Liquidity withdrawals forbidden");
                }

            }

            if(noFeeList[sender]) { // Dont have a fee when tslavault is sending, or infinite loop
                console.log("Sending without fee");                       // And when pair is sending ( buys are happening, no tax on it)
                transferToFeeDistributorAmount = 0;
                transferToAmount = amount;
            } 
            else {
                console.log("Normal fee transfer");
                transferToFeeDistributorAmount = amount.mul(feePercentX100).div(1000);
                transferToAmount = amount.sub(transferToFeeDistributorAmount);
                console.log("transferToFeeDistributorAmount:",transferToFeeDistributorAmount);
            }


        }


}
