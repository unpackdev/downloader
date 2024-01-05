// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./ILFeiPairCallee.sol";

contract LFeiPair is ERC20 {
    using SafeMath for uint256;

    // contract constants
    uint128 public constant usdcFeesNumerator = 1003; // fees is 0.3%
    uint128 public constant denominator = 1000; // base for decimals is 1000

    // constructor constants
    address public usdc;
    address public fei;
    uint256 private constant feiDecimals = 1000000000000000000;
    uint256 private constant usdcDecimals = 1000000;
        
    address public contractCreator;
    uint256 public conversionRateNumerator; // this conversion rate is divided by denominator (1000)

    event Swapped(uint256 feiSent, uint256 usdcGained);

    constructor(
        uint256 _conversionRateNumerator,
        address _fei,
        address _usdc
    ) public ERC20("LFeiPair", "LFP") {
        conversionRateNumerator = _conversionRateNumerator;
        contractCreator = msg.sender;
        fei = _fei;
        usdc = _usdc;
    }

    receive() external payable {}

    function feiToEquivalentUSDC(uint256 amountFei) internal view returns (uint256) {
        uint256 feiToUSDC = amountFei.mul(conversionRateNumerator).div(denominator);
        uint256 feiToUSDCWithDecimals = feiToUSDC.div(feiDecimals).mul(usdcDecimals);
        return feiToUSDCWithDecimals;
    }

    function usdcToEquivalentFei(uint256 amountUSDC) internal view returns (uint256) {
        uint256 feiToUSDC = amountUSDC.mul(denominator).div(conversionRateNumerator);
        uint256 feiToUSDCWithDecimals = feiToUSDC.div(usdcDecimals).mul(feiDecimals);
        return feiToUSDCWithDecimals;
    }

    // Deposit Fei into the contract and mint equivalent amount of LFeiPair tokens
    function depositFei(uint256 amountFeiIn) public {
        TransferHelper.safeTransferFrom(fei, msg.sender, address(this), amountFeiIn);
        _mint(msg.sender, amountFeiIn);
    }

    // calculate the Fei withdrawable by the user
    function withdrawableFei(address user) public view returns (uint256) {
        uint256 reserveFei = IERC20(fei).balanceOf(address(this));
        uint256 userLfeiBalance = IERC20(address(this)).balanceOf(user);
        if (reserveFei > userLfeiBalance) {
            return userLfeiBalance;
        } else {
            return reserveFei;
        }
    }

    // Burn LFeiPair from the sender and send equivalent amount of Fei tokens
    function withdrawFei(uint256 amountFeiOut) public {
        _burn(msg.sender, amountFeiOut);
        TransferHelper.safeTransfer(fei, msg.sender, amountFeiOut);
    }

    // calculate the USDC withdrawable by the user
    function withdrawableUSDC(address user) public view returns (uint256) {
        uint256 reserveUSDC = IERC20(usdc).balanceOf(address(this));
        uint256 userLfeiBalance = IERC20(address(this)).balanceOf(user);
        uint256 userUSDCBalance = feiToEquivalentUSDC(userLfeiBalance);
        if (reserveUSDC > userUSDCBalance) {
            return userUSDCBalance;
        } else {
            return reserveUSDC;
        }
    }

    // Burn LFeiPair from the sender and send required amount of USDC tokens
    function withdrawUSDC(uint256 amountUSDCOut) public {
        uint256 amountLFeiBurn = usdcToEquivalentFei(amountUSDCOut);
        _burn(msg.sender, amountLFeiBurn);
        TransferHelper.safeTransfer(usdc, msg.sender, amountUSDCOut);
    }

    function feesEarned() public view returns (uint256) {
        uint256 reserveFei = IERC20(fei).balanceOf(address(this));
        uint256 reserveUSDC = IERC20(usdc).balanceOf(address(this));
        uint256 reserveFeiEquivalentUSDC = feiToEquivalentUSDC(reserveFei);
        uint256 reserveEquivalentUSDC = reserveFeiEquivalentUSDC.add(reserveUSDC);
        uint256 outstandingUSDC = feiToEquivalentUSDC(totalSupply());
        if (outstandingUSDC > reserveEquivalentUSDC) {
            return 0;
        } else {
            return reserveEquivalentUSDC.sub(outstandingUSDC);
        }
    }

    // Transfers fees earned to the contract creator
    function claimFees() public {
        TransferHelper.safeTransfer(usdc, contractCreator, feesEarned());
    }

    // Creates a flash loan of amountFeiOut Fei atleast amountFeiOut*conversionRate should be returned back
    function swap(
        uint256 amountFeiOut,
        address to,
        bytes calldata data
    ) public {
        uint256 reserveFei = IERC20(fei).balanceOf(address(this));
        uint256 reserveUSDC = IERC20(usdc).balanceOf(address(this));
        TransferHelper.safeTransfer(fei, msg.sender, amountFeiOut); // optimistically sending fei tokens
        if (data.length > 0) ILFeiPairCallee(to).lFeiPairCall(msg.sender, amountFeiOut, data);
        uint256 newReserveUSDC = IERC20(usdc).balanceOf(address(this));
        uint256 newReserveFei = IERC20(fei).balanceOf(address(this));

        require(reserveFei > newReserveFei && reserveUSDC < newReserveUSDC, "only one way arb possible");
        uint256 feiSent = reserveFei - newReserveFei;
        uint256 feiSentEquivalentUSDC = feiToEquivalentUSDC(feiSent);
        uint256 feiSentEquivalentUSDCWithFees = feiSentEquivalentUSDC.mul(usdcFeesNumerator).div(denominator);
        uint256 usdcGained = newReserveUSDC - reserveUSDC;
        require(feiSentEquivalentUSDCWithFees < usdcGained, "USDC returned insufficient");
        emit Swapped(feiSent, usdcGained);
    }
}
