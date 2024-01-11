// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "IERC20Metadata.sol";
import "ITreasury.sol";
import "SafelyOwnable.sol";

contract Treasury is SafelyOwnable, ITreasury {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event SetBondContract(address bond, bool approved);
    event SetMaxPayout(address indexed bond, uint max);
    event ResetPayout(address indexed bond, uint sold);
    event Withdraw(
        address indexed token,
        address indexed destination,
        uint amount
    );

    uint8 private immutable PAYOUT_TOKEN_DECIMALS;
    uint private immutable PAYOUT_TOKEN_SCALE; // 10 ** decimals

    address public immutable payoutToken;
    mapping(address => bool) public isBondContract;
    // max payout per bond
    mapping(address => uint) public maxPayouts;
    // total payout per bond
    mapping(address => uint) public payouts;

    constructor(address _payoutToken) {
        require(_payoutToken != address(0), "payout token = zero");
        payoutToken = _payoutToken;
        uint8 decimals = IERC20Metadata(_payoutToken).decimals();
        PAYOUT_TOKEN_DECIMALS = decimals;
        PAYOUT_TOKEN_SCALE = 10**decimals;
    }

    modifier onlyBondContract() {
        require(isBondContract[msg.sender], "not bond");
        _;
    }

    /**
     *  @notice deposit principal token and recieve back payout token
     *  @param _principalToken address
     *  @param _principalAmount uint
     *  @param _payoutAmount uint
     */
    function deposit(
        address _principalToken,
        uint _principalAmount,
        uint _payoutAmount
    ) external override onlyBondContract {
        payouts[msg.sender] += _payoutAmount;
        require(
            payouts[msg.sender] <= maxPayouts[msg.sender],
            "total payout > max"
        );

        IERC20(_principalToken).safeTransferFrom(
            msg.sender,
            address(this),
            _principalAmount
        );
        IERC20(payoutToken).safeTransfer(msg.sender, _payoutAmount);
    }

    /**
     *   @notice returns payout token valuation of principle
     *   @param _principalToken address
     *   @param _amount uint
     *   @return value uint
     */
    function valueOfToken(address _principalToken, uint _amount)
        external
        view
        override
        returns (uint)
    {
        // convert amount to match payout token decimals
        return
            _amount.mul(PAYOUT_TOKEN_SCALE).div(
                10**IERC20Metadata(_principalToken).decimals()
            );
    }

    /**
     *  @notice owner can withdraw ERC20 token to desired address
     *  @param _token uint
     *  @param _destination address
     *  @param _amount uint
     */
    function withdraw(
        address _token,
        address _destination,
        uint _amount
    ) external onlyOwner {
        require(_destination != address(0), "dest = zero address");
        IERC20(_token).safeTransfer(_destination, _amount);
        emit Withdraw(_token, _destination, _amount);
    }

    /**
     *  @notice set bond contract
     *  @param _bond address
     *  @param _approve bool
     */
    function setBondContract(address _bond, bool _approve) external onlyOwner {
        require(isBondContract[_bond] != _approve, "no change");
        isBondContract[_bond] = _approve;
        emit SetBondContract(_bond, _approve);
    }

    /**
     *  @notice set max amount of bond to be sold by the bond contract
     *  @param _bond address
     *  @param _max uint
     */
    function setMaxPayout(address _bond, uint _max) external onlyOwner {
        require(isBondContract[_bond], "not bond");
        maxPayouts[_bond] = _max;
        emit SetMaxPayout(_bond, _max);
    }

    /**
     *  @notice reset amount of bond sold
     *  @param _bond address
     */
    function resetPayout(address _bond) external onlyOwner {
        require(isBondContract[_bond], "not bond");
        uint sold = payouts[_bond];
        payouts[_bond] = 0;
        emit ResetPayout(_bond, sold);
    }
}
