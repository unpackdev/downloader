// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./fxToken.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

/** @dev Same as hPSM but without the IHandle component.
 *       There is no fxToken validation as this contract is intended to be
 *       deployed to mainnet where there is no IHandle-compatible contract.
 */
contract hPSM2 is Ownable {
    using SafeERC20 for ERC20;

    /** @dev This contract's address. */
    address private immutable self;
    /** @dev Transaction fee with 18 decimals. */
    uint256 public transactionFee;
    /** @dev Mapping from pegged token address to total deposit supported. */
    mapping(address => uint256) public collateralCap;
    /** @dev Mapping from pegged token address to accrued fee amount. */
    mapping(address => uint256) public accruedFees;
    /** @dev Mapping from fxToken to peg token address to whether the peg is set. */
    mapping(address => mapping(address => bool)) public isFxTokenPegged;
    /** @dev Mapping from fxToken to peg token to deposit amount. */
    mapping(address => mapping(address => uint256)) public fxTokenDeposits;
    /** @dev Whether deposits are paused. */
    bool public areDepositsPaused;

    event SetPauseDeposits(bool isPaused);

    event SetTransactionFee(uint256 fee);
    
    event SetMaximumTokenDeposit(address indexed token, uint256 amount);
    
    event SetFxTokenPeg(
        address indexed fxToken,
        address indexed peggedToken,
        bool isPegged
    );

    event Deposit(
        address indexed fxToken,
        address indexed peggedToken,
        address indexed account,
        uint256 amountIn,
        uint256 amountOut
    );
 
    event Withdraw(
        address indexed fxToken,
        address indexed peggedToken,
        address indexed account,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor() {
        self = address(this);
    }
    
    function collectAccruedFees(address collateralToken) external onlyOwner {
        uint256 amount = accruedFees[collateralToken];
        require(amount > 0, "PSM: no fee accrual");
        ERC20(collateralToken).transfer(msg.sender, amount);
        accruedFees[collateralToken] -= amount;
    }

    /** @dev Sets the transaction fee. */
    function setTransactionFee(uint256 fee) external onlyOwner {
        require(fee < 1 ether, "PSM: fee must be < 100%");
        transactionFee = fee;
        emit SetTransactionFee(transactionFee);
    }

    /** @dev Sets whether deposits are paused. */
    function setPausedDeposits(bool isPaused) external onlyOwner {
        areDepositsPaused = isPaused;
        emit SetPauseDeposits(isPaused);
    }

    /** @dev Configures a fxToken peg to a collateral token. */
    function setFxTokenPeg(
        address fxTokenAddress,
        address peggedTokenAddress,
        bool isPegged
    ) external onlyOwner {
        fxToken _fxToken = fxToken(fxTokenAddress);
        assert(isFxTokenPegged[fxTokenAddress][peggedTokenAddress] != isPegged);
        bytes32 operatorRole = _fxToken.OPERATOR_ROLE();
        require(
            !isPegged || _fxToken.hasRole(operatorRole, self),
            "PSM: not an fxToken operator"
        );
        isFxTokenPegged[fxTokenAddress][peggedTokenAddress] = isPegged;
        if (!isPegged)
            _fxToken.renounceRole(operatorRole, self);
        emit SetFxTokenPeg(fxTokenAddress, peggedTokenAddress, isPegged);
    }

    /** @dev Sets the maximum total deposit for a pegged token. */
    function setCollateralCap(
        address peggedToken,
        uint256 capWithPeggedTokenDecimals
    ) external onlyOwner {
        collateralCap[peggedToken] = capWithPeggedTokenDecimals;
        emit SetMaximumTokenDeposit(peggedToken, capWithPeggedTokenDecimals);
    }

    /** @dev Receives a pegged token in exchange for minting fxToken for an account. */
    function deposit(
        address fxTokenAddress,
        address peggedTokenAddress,
        uint256 amount
    ) external {
        require(!areDepositsPaused, "PSM: deposits are paused");
        require(
            isFxTokenPegged[fxTokenAddress][peggedTokenAddress],
            "PSM: fxToken not pegged to peggedToken"
        );
        require(
            amount > 0,
            "PSM: amount must be > 0"
        );
        ERC20 peggedToken = ERC20(peggedTokenAddress);
        require(
            collateralCap[peggedTokenAddress] == 0 ||
                amount + peggedToken.balanceOf(self)
                    <= collateralCap[peggedTokenAddress],
            "PSM: collateral cap exceeded"
        );
        peggedToken.safeTransferFrom(
            msg.sender,
            self,
            amount
        );
        uint256 amountOutGross = calculateAmountForDecimalChange(
            peggedTokenAddress,
            fxTokenAddress,
            amount
        );
        uint256 amountOutNet = calculateAmountAfterFees(
          amountOutGross  
        );
        require(amountOutNet > 0, "PSM: prevented nil transfer");
        updateFeeForCollateral(
            peggedTokenAddress,
            amount,
            calculateAmountAfterFees(amount)
        );
        // Increase fxToken (input) amount from deposits.
        fxTokenDeposits[fxTokenAddress][peggedTokenAddress] += amount;
        fxToken(fxTokenAddress).mint(msg.sender, amountOutNet);
        emit Deposit(
            fxTokenAddress,
            peggedTokenAddress,
            msg.sender,
            amount,
            amountOutNet
        );
    }

    /** @dev Burns an account's fxToken balance in exchange for a pegged token. */
    function withdraw(
        address fxTokenAddress,
        address peggedTokenAddress,
        uint256 amount
    ) external {
        require(
            isFxTokenPegged[fxTokenAddress][peggedTokenAddress],
            "PSM: fxToken not pegged to peggedToken"
        );
        ERC20 peggedToken = ERC20(peggedTokenAddress);
        uint256 amountOutGross = calculateAmountForDecimalChange(
            fxTokenAddress,
            peggedTokenAddress,
            amount
        );
        // While deposits are paused:
        //  - users can still withdraw all the pegged token liquidity currently in the contract
        //  - once the pegged token liquidity runs out, users can no longer call withdraw
        require(
            !areDepositsPaused ||
                fxTokenDeposits[fxTokenAddress][peggedTokenAddress] >= amountOutGross,
            "PSM: paused + no liquidity"
        );
        require(
            peggedToken.balanceOf(self) >= amountOutGross,
            "PSM: contract lacks liquidity"
        );
        fxToken fxToken = fxToken(fxTokenAddress);
        require(
            fxToken.balanceOf(msg.sender) >= amount,
            "PSM: insufficient fx balance"
        );
        fxToken.burn(msg.sender, amount);
        uint256 amountOutNet = calculateAmountAfterFees(
            amountOutGross
        );
        require(amountOutNet > 0, "PSM: prevented nil transfer");
        updateFeeForCollateral(
            peggedTokenAddress,
            amountOutGross,
            amountOutNet
        );
        // Reduce fxToken (amount out, gross) amount from deposits.
        fxTokenDeposits[fxTokenAddress][peggedTokenAddress] -= amountOutGross;
        peggedToken.safeTransfer(msg.sender, amountOutNet);
        emit Withdraw(
            fxTokenAddress,
            peggedTokenAddress,
            msg.sender,
            amount,
            amountOutNet
        );
    }

    /** @dev Converts an input amount to after fees. */
    function calculateAmountAfterFees(uint256 amount) private returns (uint256) {
        return amount * (1 ether - transactionFee) / 1 ether;
    }

    function updateFeeForCollateral(
        address collateralToken,
        uint256 amountGross,
        uint256 amountNet
    ) private{
        if (amountNet == amountGross) return;
        assert(amountNet < amountGross);
        accruedFees[collateralToken] += amountGross - amountNet;
    }

    /** @dev Converts an amount to match a different decimal count. */
    function calculateAmountForDecimalChange(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private returns (uint256) {
        uint256 decimalsIn = uint256(ERC20(tokenIn).decimals());
        uint256 decimalsOut = uint256(ERC20(tokenOut).decimals());
        if (decimalsIn == decimalsOut) return amountIn;
        uint256 decimalsDiff;
        if (decimalsIn > decimalsOut) {
            decimalsDiff = decimalsIn - decimalsOut;
            return amountIn / (10 ** decimalsDiff);
        }
        decimalsDiff = decimalsOut - decimalsIn;
        return amountIn * (10 ** decimalsDiff);
    }
}
