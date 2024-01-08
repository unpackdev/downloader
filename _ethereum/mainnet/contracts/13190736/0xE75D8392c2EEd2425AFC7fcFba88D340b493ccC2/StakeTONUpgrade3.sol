//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IIIDepositManager.sol";
import "./IISeigManager.sol";
import "./IWTON.sol";
import "./LibTokenStake1.sol";
import "./SafeMath.sol";
import "./AccessibleCommon.sol";
import "./StakeTONStorage.sol";

interface ITokamakRegistry3 {
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function defiInfo(bytes32)
        external
        view
        returns (
            string memory,
            address,
            address,
            address,
            uint256,
            address
        );
}

interface ITOS3 {
    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    //function isBurner(address account) external view returns (bool);

    function hasRole(bytes32 role, address account) external view returns (bool) ;

}

contract StakeTONUpgrade3 is StakeTONStorage, AccessibleCommon {
    using SafeMath for uint256;

    modifier lock() {
        require(_lock == 0, "StakeTONUpgrade3: LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    /// @dev event on withdrawal
    /// @param to the sender
    /// @param tonAmount the amount of TON withdrawal
    /// @param tosAmount the amount of TOS withdrawal
    event Withdrawal(address indexed to, uint256 tonAmount, uint256 tosAmount);
    event TonWithdrawal(
        address indexed to,
        uint256 tonAmount,
        uint256 wtonAmount,
        uint256 tosAmount,
        uint256 tosBurnAmount
    );

    /// @dev constructor of StakeTON
    constructor() {}

    /// @dev This contract cannot stake Ether.
    receive() external payable {
        revert("cannot stake Ether");
    }

    /// @dev withdraw
    function withdraw() external {
        require(
            endBlock > 0 && endBlock < block.number,
            "StakeTONUpgrade3: not end"
        );

        (
            address ton,
            address wton,
            address depositManager,
            address seigManager,
        ) = ITokamakRegistry3(stakeRegistry).getTokamak();

        (, , , , uint256 _burnPercent, ) =
            ITokamakRegistry3(stakeRegistry).defiInfo(
                keccak256("PHASE1.SWAPTOS.BURNPERCENT")
            );

        require(
            ton != address(0) &&
                wton != address(0) &&
                depositManager != address(0) &&
                seigManager != address(0),
            "StakeTONUpgrade3: ITokamakRegistry zero"
        );
        if (tokamakLayer2 != address(0)) {
            require(
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) ==
                    0 &&
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    ) ==
                    0,
                "StakeTONUpgrade3: remain amount in tokamak"
            );
        }
        LibTokenStake1.StakedAmount storage staked = userStaked[msg.sender];
        require(!staked.released, "StakeTONUpgrade3: Already withdraw");

        if (!withdrawFlag) {
            withdrawFlag = true;
            if (paytoken == ton) {
                swappedAmountTOS = ITOS3(token).balanceOf(address(this));
                finalBalanceWTON = ITOS3(wton).balanceOf(address(this));
                finalBalanceTON = ITOS3(ton).balanceOf(address(this));
                require(
                    finalBalanceWTON.div(10**9).add(finalBalanceTON) >=
                        totalStakedAmount,
                    "StakeTONUpgrade3: finalBalance is lack"
                );
            }
        }

        uint256 amount = staked.amount;
        require(amount > 0, "StakeTONUpgrade3: Amount wrong");
        staked.releasedBlock = block.number;
        staked.released = true;
        totalStakers = totalStakers.sub(1);

        if (paytoken == ton) {
            uint256 tonAmount = 0;
            uint256 wtonAmount = 0;
            uint256 tosAmount = 0;
            uint256 tosBurnAmount = 0;

            if (finalBalanceTON > 0)
                tonAmount = finalBalanceTON.mul(amount).div(totalStakedAmount);
            if (finalBalanceWTON > 0)
                wtonAmount = finalBalanceWTON.mul(amount).div(
                    totalStakedAmount
                );
            if (swappedAmountTOS > 0) {
                tosAmount = swappedAmountTOS.mul(amount).div(totalStakedAmount);
                if (tosAmount > 0 && _burnPercent > 0 && _burnPercent <= 100) {
                    tosBurnAmount = tosAmount.mul(_burnPercent).div(100);
                    tosAmount = tosAmount.sub(tosBurnAmount);
                }
            }

            staked.releasedTOSAmount = tosAmount;
            if (wtonAmount > 0)
                staked.releasedAmount = wtonAmount.div(10**9).add(tonAmount);
            else staked.releasedAmount = tonAmount;

            tonWithdraw(
                ton,
                wton,
                tonAmount,
                wtonAmount,
                tosAmount,
                tosBurnAmount
            );

        } else if (paytoken == address(0)) {
            require(
                staked.releasedAmount <= amount,
                "StakeTONUpgrade3: Amount wrong"
            );
            staked.releasedAmount = amount;
            address payable self = address(uint160(address(this)));
            require(self.balance >= amount, "StakeTONUpgrade3: insuffient ETH");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "StakeTONUpgrade3: withdraw failed.");
        } else {
            require(
                staked.releasedAmount <= amount,
                "StakeTONUpgrade3: Amount wrong"
            );
            staked.releasedAmount = amount;
            require(
                ITOS3(paytoken).transfer(msg.sender, amount),
                "StakeTONUpgrade3: transfer fail"
            );
        }

        emit Withdrawal(
            msg.sender,
            staked.releasedAmount,
            staked.releasedTOSAmount
        );
    }

    /// @dev withdraw TON
    /// @param ton  TON address
    /// @param wton  WTON address
    /// @param tonAmount  the amount of TON to be withdrawn to msg.sender
    /// @param wtonAmount  the amount of WTON to be withdrawn to msg.sender
    /// @param tosAmount  the amount of TOS to be withdrawn to msg.sender
    function tonWithdraw(
        address ton,
        address wton,
        uint256 tonAmount,
        uint256 wtonAmount,
        uint256 tosAmount,
        uint256 tosBurnAmount
    ) internal {
        if (tonAmount > 0) {
            require(
                ITOS3(ton).balanceOf(address(this)) >= tonAmount,
                "StakeTONUpgrade3: ton balance is lack"
            );

            require(
                ITOS3(ton).transfer(msg.sender, tonAmount),
                "StakeTONUpgrade3: transfer ton fail"
            );
        }
        if (wtonAmount > 0) {
            require(
                ITOS3(wton).balanceOf(address(this)) >= wtonAmount,
                "StakeTONUpgrade3: wton balance is lack"
            );
            require(
                IWTON(wton).swapToTONAndTransfer(msg.sender, wtonAmount),
                "StakeTONUpgrade3: transfer wton fail"
            );
        }
        if (tosAmount > 0) {
            require(
                ITOS3(token).balanceOf(address(this)) >= tosAmount,
                "StakeTONUpgrade3: tos balance is lack"
            );
            require(
                ITOS3(token).transfer(msg.sender, tosAmount),
                "StakeTONUpgrade3: transfer tos fail"
            );
        }
        if (tosBurnAmount > 0) {
            // require(
            //     ITOS3(token).isBurner(address(this)),
            //     "StakeTONUpgrade3: not burner"
            // );
            require(
                ITOS3(token).hasRole(keccak256("BURNER"), address(this)),
                "StakeTONUpgrade3: not burner"
            );
            require(
                ITOS3(token).burn(address(this), tosBurnAmount),
                "StakeTONUpgrade3: tos burn fail"
            );
        }

        emit TonWithdrawal(
            msg.sender,
            tonAmount,
            wtonAmount,
            tosAmount,
            tosBurnAmount
        );
    }

    function version() external pure returns (string memory) {
        return "phase1.upgrade.v3";
    }


    /// @dev withdraw
    function withdrawData(address user) external view returns (uint256[4] memory){
        (
            address ton,
            address wton,
            address depositManager,
            address seigManager,
        ) = ITokamakRegistry3(stakeRegistry).getTokamak();

        (, , , , uint256 _burnPercent, ) =
            ITokamakRegistry3(stakeRegistry).defiInfo(
                keccak256("PHASE1.SWAPTOS.BURNPERCENT")
            );

        require(
            ton != address(0) &&
                wton != address(0) &&
                depositManager != address(0) &&
                seigManager != address(0),
            "StakeTONUpgrade3: ITokamakRegistry zero"
        );

        if (tokamakLayer2 != address(0)) {
            require(
                IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                ) ==
                    0 &&
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    ) ==
                    0,
                "StakeTONUpgrade3: remain amount in tokamak"
            );
        }

        uint256 _swappedAmountTOS = 0;
        uint256 _finalBalanceWTON = 0;
        uint256 _finalBalanceTON = 0;

        LibTokenStake1.StakedAmount storage staked = userStaked[user];
        require(!staked.released, "StakeTONUpgrade3: Already withdraw");

        if (finalBalanceTON == 0) {
            if (paytoken == ton) {
                _swappedAmountTOS = ITOS3(token).balanceOf(address(this));
                _finalBalanceWTON = ITOS3(wton).balanceOf(address(this));
                _finalBalanceTON = ITOS3(ton).balanceOf(address(this));
                require(
                    _finalBalanceWTON.div(10**9).add(_finalBalanceTON) >=
                        totalStakedAmount,
                    "StakeTONUpgrade3: finalBalance is lack"
                );
            }
        }

        uint256 amount = staked.amount;
        require(amount > 0, "StakeTONUpgrade3: Amount wrong");


        uint256 tonAmount = 0;
        uint256 wtonAmount = 0;
        uint256 tosAmount = 0;
        uint256 tosBurnAmount = 0;

        if (_finalBalanceTON > 0)
            tonAmount = _finalBalanceTON.mul(amount).div(totalStakedAmount);
        if (_finalBalanceWTON > 0)
            wtonAmount = _finalBalanceWTON.mul(amount).div(
                totalStakedAmount
            );
        if (_swappedAmountTOS > 0) {
            tosAmount = _swappedAmountTOS.mul(amount).div(totalStakedAmount);
            if (tosAmount > 0 && _burnPercent > 0 && _burnPercent <= 100) {
                tosBurnAmount = tosAmount.mul(_burnPercent).div(100);
                tosAmount = tosAmount.sub(tosBurnAmount);
            }
        }

        return [tonAmount, wtonAmount, tosAmount, tosBurnAmount];

    }
}
