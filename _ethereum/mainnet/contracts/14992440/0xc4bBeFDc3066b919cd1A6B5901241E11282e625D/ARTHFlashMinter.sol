// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

import "./IFlashBorrower.sol";
import "./IFlashLender.sol";

interface ERC20MinterBurner is IERC20 {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

contract ARTHFlashMinter is IFlashLender, Pausable, Ownable {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ARTHFlashMinter.onFlashLoan");

    uint256 public fee = 1000; //  1000 == 0.1 %.
    ERC20MinterBurner public token;
    address public ecosystemFund;

    event FeeChanged(uint256 amount);
    event EcosystemFundChanged(address fund_);

    event FlashloanMint(uint256 amount, address indexed to);
    event FlashloanPayback(uint256 amount, uint256 fee, address indexed by);

    /**
     * @param token_ The token to mint/burn
     * @param fee_ The percentage of the loan `amount` that needs to be repaid, in addition to `amount`.
     */
    constructor(
        address token_,
        address fund_,
        address governance_,
        uint256 fee_
    ) {
        token = ERC20MinterBurner(token_);
        setFee(fee_);
        setEcosystemFund(fund_);

        _transferOwnership(governance_);
    }

    function setFee(uint256 amount) public onlyOwner {
        fee = amount;
        emit FeeChanged(amount);
    }

    function setEcosystemFund(address fund_) public onlyOwner {
        ecosystemFund = fund_;
        emit EcosystemFundChanged(fund_);
    }

    function toggle() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(uint256 amount) external view override returns (uint256) {
        return _flashFee(amount);
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the ERC3156 callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IFlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        uint256 _fee = _flashFee(amount);

        token.mint(address(receiver), amount);
        emit FlashloanMint(amount, address(receiver));

        require(
            receiver.onFlashLoan(msg.sender, amount, _fee, data) ==
                CALLBACK_SUCCESS,
            "ARTHFlashMinter: Callback failed"
        );

        token.burn(address(receiver), amount);
        token.transfer(ecosystemFund, _fee);

        emit FlashloanPayback(amount, _fee, address(receiver));
        return true;
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * fee) / 10000;
    }
}
