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
        address _TENSAddress,
        address _WETHAddress,
        address _uniswapFactory
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        tensTokenAddress = _TENSAddress;
        WETHAddress = _WETHAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(WETHAddress,tensTokenAddress);
        feePercentX100 = 10;
        BURN_FEEX1000 = 25; //0.25%
        paused = true; // We start paused until sync post LGE happens.
        _editNoFeeList(0x5974930C7b838026D3948dAf336443A411482DBA, true); // tensvault proxy
        _editNoFeeList(tokenUniswapPair, true);
        sync();
        minFinney = 5000;
    }


    address tokenUniswapPair;
    IUniswapV2Factory public uniswapFactory;
    address internal WETHAddress;
    address tensTokenAddress;
    address tensVaultAddress;
    uint8 public feePercentX100;  // max 255 = 25.5% artificial clamp
    uint256 public lastTotalSupplyOfLPTokens;
    bool paused;
    uint256 private lastSupplyOfTensInPair;
    uint256 private lastSupplyOfWETHInPair;
    mapping (address => bool) public noFeeList;

    // TENS token is pausable 
    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
        sync();
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }

    // Sets the burn fee for this contract
    // defaults at 2.5%
    // Note contract owner is meant to be a governance contract allowing TENS governance consensus
    uint16 public BURN_FEEX1000;
    function setBurnFee(uint16 _BURN_FEEX1000) public onlyOwner {
        require(_BURN_FEEX1000 <= 5000, 'Burn fee clamped at 5%');
        BURN_FEEX1000 = _BURN_FEEX1000;
    }

    function setTensVaultAddress(address _tensVaultAddress) public onlyOwner {
        tensVaultAddress = _tensVaultAddress;
        noFeeList[tensVaultAddress] = true;
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
        uint256 _balanceTENS = IERC20(tensTokenAddress).balanceOf(tokenUniswapPair);

        // Do not block after small liq additions
        // you can only withdraw 350$ now with front running
        // And cant front run buys with liq add ( adversary drain )

        lastIsMint = _balanceTENS > lastSupplyOfTensInPair && _balanceWETH > lastSupplyOfWETHInPair.add(minFinney.mul(1 finney));

        lastSupplyOfTensInPair = _balanceTENS;
        lastSupplyOfWETHInPair = _balanceWETH;
    }


    function calculateAmountsAfterFee(        
        address sender, 
        address recipient, // unusued maybe use din future
        uint256 amount
        ) public returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount, uint256 burnAmount) 
        {
            require(paused == false, "FEE APPROVER: Transfers Paused");
            (bool lastIsMint, bool lpTokenBurn) = sync();

            if(sender == tokenUniswapPair) {
                // This will block buys that are immidietly after a mint. Before sync is called/
                // Deployment of this should only happen after router deployment 
                // And addition of sync to all TensVault transactions to remove 99.99% of the cases.
                require(lastIsMint == false, "Liquidity withdrawals forbidden");
                require(lpTokenBurn == false, "Liquidity withdrawals forbidden");
      
            }

            if(noFeeList[sender]) { // Dont have a fee when tensvault is sending, or infinite loop
                console.log("Sending without fee");                       // And when pair is sending ( buys are happening, no tax on it)
                transferToFeeDistributorAmount = 0;
                transferToAmount = amount;
                burnAmount = 0;
            } 
            else {
                console.log("Normal fee transfer");
                transferToFeeDistributorAmount = amount.mul(feePercentX100).div(1000);
                burnAmount = amount.mul(BURN_FEEX1000).div(10000);
                // Less the burn fee
                transferToAmount = amount.sub(transferToFeeDistributorAmount).sub(burnAmount);            
            }


        }


}
