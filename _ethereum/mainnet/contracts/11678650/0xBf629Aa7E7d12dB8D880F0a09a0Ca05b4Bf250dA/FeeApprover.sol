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
    
    // In this contract, e do calculate fee and the real amount to be sent to the recepient

    function initialize(
        address _Hal9kAddress,
        address _WETHAddress,
        address _uniswapFactory
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        hal9kTokenAddress = _Hal9kAddress;
        WETHAddress = _WETHAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(
            WETHAddress,
            hal9kTokenAddress
        );
        feePercentX100 = 10;
        paused = true; // We start paused until sync post LGE happens.
    }

    address public tokenUniswapPair;
    IUniswapV2Factory public uniswapFactory;
    address internal WETHAddress;
    address hal9kTokenAddress;
    address hal9kVaultAddress;
    uint8 public feePercentX100; // max 255 = 25.5% artificial clamp
    uint256 public lastTotalSupplyOfLPTokens;
    bool paused;

    // HAL9K token is pausable

    function setHal9kAddress(address _hal9kAddress, address _WETHAddress, address _uniswapFactory) public onlyOwner {
        hal9kTokenAddress = _hal9kAddress;
        WETHAddress = _WETHAddress;
        tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(
            WETHAddress,
            hal9kTokenAddress
        );
    }

    function setPaused(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        feePercentX100 = _feeMultiplier;
    }
    
    function setHal9kVaultAddress(address _hal9kVaultAddress) public onlyOwner {
        hal9kVaultAddress = _hal9kVaultAddress;
    }

    function sync() public {
        uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
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
        uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();

        if (sender == tokenUniswapPair)
            require(
                lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal,
                "Liquidity withdrawals forbidden"
            );

        if (sender == hal9kVaultAddress || sender == tokenUniswapPair) {
            // Dont have a fee when hal9kvault is sending, or infinite loop
            // And when pair is sending ( buys are happening, no tax on it)
            transferToFeeDistributorAmount = 0;
            transferToAmount = amount;
        } else {
            transferToFeeDistributorAmount = amount.mul(feePercentX100).div(
                1000
            );
            transferToAmount = amount.sub(transferToFeeDistributorAmount);
        }

        lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
    }
}
