// SPDX-License-Identifier: GNU-GPL v3.0 or later
pragma solidity ^0.8.0;

import "./IRevest.sol";
import "./IAddressRegistry.sol";
import "./IFeeReporter.sol";
import "./IRewardsHandler.sol";

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IUniswapV2Router02.sol";

interface IWETH {
    function deposit() external payable;
}

contract CashFlowManagement is Ownable, IFeeReporter, ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    // Set at deployment to allow for different AMMs on different chains
    // Any fork of Uniswap v2 will work
    address private immutable UNISWAP_V2_ROUTER;
    address private immutable WETH;

    uint private constant MAX_INT = 2**256 - 1;

    address public addressRegistry;
    uint public constant PRECISION = 1 ether;

    uint internal erc20Fee = 2;
    uint internal weiFee;

    // For tracking if a given contract has approval for Uniswap V2 instance
    mapping(uint => uint) private approved;

    // For tracking if a given contract has approval for token
    mapping(address => mapping(address => bool)) private approvedContracts;

    constructor(address registry_, address router_, address weth_) {
        UNISWAP_V2_ROUTER = router_;
        addressRegistry = registry_;
        WETH = weth_;
    }

    function mintTimeLock(
        uint[] memory endTimes,
        uint[] memory amountPerPeriod,
        address[] memory pathToSwaps,
        uint slippage // slippage / PRECISION = fraction that represents actual slippage
    ) external payable nonReentrant returns (uint[] memory fnftIds) {
        require(endTimes.length == amountPerPeriod.length, "Invalid arrays");
        require(pathToSwaps.length > 1, "Path to swap should be greater than 1");
        require(msg.value >= weiFee, 'Insufficient fees!');

        bool upfrontPayment = endTimes[0] == 0; // This is the easiest way to indicate immediate payment
        uint totalAmountReceived;
        uint mul;
        {
            uint totalAmountToSwap;
            for (uint i; i < amountPerPeriod.length; i++) {
                totalAmountToSwap += amountPerPeriod[i];
            }
            
            // Transfer the tokens from the user to this contract
            IERC20(pathToSwaps[0]).safeTransferFrom(
                msg.sender,
                address(this),
                totalAmountToSwap
            );

            
            {
                uint[] memory amountsOut = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(totalAmountToSwap, pathToSwaps);
                uint amtOut = amountsOut[amountsOut.length - 1];


                if(!_isApproved(pathToSwaps[0])) {
                    IERC20(pathToSwaps[0]).approve(UNISWAP_V2_ROUTER, MAX_INT);
                    _setIsApproved(pathToSwaps[0], true);
                }

                IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        totalAmountToSwap,
                        amtOut * (PRECISION - slippage) / PRECISION,
                        pathToSwaps,
                        address(this),
                        block.timestamp
                    );
            }
            totalAmountReceived = IERC20(pathToSwaps[pathToSwaps.length - 1]).balanceOf(address(this)) * (1000 - erc20Fee) / 1000;
            mul = PRECISION * totalAmountReceived / totalAmountToSwap;
        }
        

        // Initialize the Revest config object
        IRevest.FNFTConfig memory fnftConfig;

        // Assign what ERC20 pathToSwaps[0] the FNFT will hold
        fnftConfig.asset = pathToSwaps[pathToSwaps.length - 1];

        // Set these two arrays according to Revest specifications to say
        // Who gets these FNFTs and how many copies of them we should create
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;

        uint[] memory quantities = new uint[](1);
        quantities[0] = 1;

        if(upfrontPayment) {
            fnftIds = new uint[](endTimes.length - 1);

        } else {
            fnftIds = new uint[](endTimes.length);
        }
        
        // We use an inline block here to save a little bit of gas + stack
        // Allows us to avoid keeping the "address revest" var in memory once
        // it has served its purpose
        
        {
            // Retrieve the Revest controller address from the address registry
            address revest = IAddressRegistry(addressRegistry).getRevest();
            // Here, check if the controller has approval to spend tokens out of this entry point contract
            if (!approvedContracts[revest][fnftConfig.asset]) {
                // If it doesn't, approve it
                IERC20(fnftConfig.asset).approve(revest, MAX_INT);
                approvedContracts[revest][fnftConfig.asset] = true;
            }
            
            // Mint the FNFT
            // The return gives us a unique ID we can use to store additional data
            for (uint i; i < endTimes.length; i++) {
                if(i == 0 && upfrontPayment) {
                    uint payAmt;
                    if(i == endTimes.length - 1 ) {
                        payAmt = totalAmountReceived;
                    } else {
                        payAmt = amountPerPeriod[i] * mul / PRECISION;
                    }
                    IERC20(fnftConfig.asset).safeTransfer(msg.sender, payAmt);
                    totalAmountReceived -= payAmt;
                } else {
                    if(i == endTimes.length - 1 ) {
                        fnftConfig.depositAmount = totalAmountReceived;
                    } else {
                        fnftConfig.depositAmount = amountPerPeriod[i] * mul / PRECISION;
                    }

                    fnftIds[(upfrontPayment && i > 0) ? i - 1 : i] = IRevest(revest).mintTimeLock{value: (msg.value - weiFee) / endTimes.length}(endTimes[i], recipients, quantities, fnftConfig);
                    // Avoids issues with division
                    totalAmountReceived -= fnftConfig.depositAmount;
                }
            }

            if(erc20Fee > 0) {
                // Transfer fees to admin contract
                address admin = IAddressRegistry(addressRegistry).getAdmin();
                uint bal = IERC20(fnftConfig.asset).balanceOf(address(this));
                IERC20(fnftConfig.asset).safeTransfer(admin, bal);
            }
            if(weiFee > 0) {
                address rewards = IAddressRegistry(addressRegistry).getRewardsHandler();
                IWETH(WETH).deposit{value:weiFee}();
                if(!approvedContracts[rewards][WETH]) {
                    IERC20(WETH).approve(rewards, MAX_INT);
                    approvedContracts[rewards][WETH] = true;
                }
                IRewardsHandler(rewards).receiveFee(WETH, weiFee);
            }
        }
    }

    function setERC20Fee(uint fee) external onlyOwner {
        erc20Fee = fee;
    }

    function setWeiFee(uint weiFee_) external onlyOwner {
        weiFee = weiFee_;
    }

    function _isApproved(address _owner) internal view returns (bool) {
        uint _id = uint(uint160(_owner));
        uint _mask = 1 << _id % 256;
        return (approved[_id / 256] & _mask) != 0;
    }

    function _setIsApproved(address _owner, bool _isApprove) internal {
        uint _id = uint(uint160(_owner));
        if (_isApprove) {
            approved[_id / 256] |= 1 << _id % 256;
        } else {
            approved[_id / 256] &= 0 << _id % 256;
        }
    }

    function getERC20Fee(address) external view override returns (uint) {
        return erc20Fee;
    }

    function getFlatWeiFee(address) external view override returns (uint) {
        return weiFee;
    }

}
