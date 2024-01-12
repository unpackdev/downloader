// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./TransferHelper.sol";

contract Crowdsale is AccessControl, ReentrancyGuard {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable zeroGas;
    uint256 public immutable maxPurchase; // in 0gas
    uint256 public immutable minPurchase; // in 0gas
    uint256 public immutable hardcap; // in 0gas
    uint256 public immutable softcap; // in 0gas

    uint128 public sellEnd;
    uint128 public totalBought;
    uint256 public totalClaimed;

    // [0] - usdt, [1] - usdc
    address[2] public tokens;
    // [0] - eth payed, [1] - usdt payed,
    // [2] - usdc payed, [3] - bought
    mapping(address => uint128[4]) public userToBalance;
    // 1 - usdt, 2 - usdc
    mapping(address => uint256) private tokenToId;

    event Buy(uint256 bought, uint256 payed);
    event Withdraw(uint256 eth, uint256 usdt, uint256 usdc);
    event Claim(uint256 amount);
    event ClaimRised(uint256 eth, uint256 usdt, uint256 usdc, uint256 zeroGas);

    constructor(
        address owner,
        address signer,
        address _zeroGas,
        address _usdt,
        address _usdc,
        uint256 _hardcap,
        uint256 _softcap,
        uint256 _minPurchase,
        uint256 _maxPurchase
    ) {
        require(
            owner != address(0) &&
                signer != address(0) &&
                _zeroGas != address(0) &&
                _usdt != address(0) &&
                _usdc != address(0),
            "Zero address"
        );
        require(_softcap > 0 && _softcap < _hardcap, "Wrong softcap");
        _grantRole(0x0, owner);
        _grantRole(SIGNER_ROLE, signer);
        tokens[0] = _usdt;
        tokens[1] = _usdc;
        tokenToId[_usdt] = 1;
        tokenToId[_usdc] = 2;
        zeroGas = _zeroGas;
        hardcap = _hardcap;
        softcap = _softcap;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }

    /**
     * @notice allow admin set sellStart timestamp,
     * before this he must transfer hardcap to this contract,
     * can be called only once
     * @param sellStart timestamp of sell start
     */
    function initiate(uint128 sellStart) external onlyRole(0x0) {
        require(sellEnd == 0, "Already initiated");
        require(sellStart > block.timestamp, "Sell start before now");
        require(
            IERC20(zeroGas).balanceOf(address(this)) >= hardcap,
            "Transfer tokens before init"
        );
        sellEnd = sellStart + 35 days;
    }

    /**
     * @notice allow users buy 0gas tokens, usdt/usdc must be approved for payed,
     * user can't buy less then min and more then max purchase in total
     * @param token address of payed token, = NATIVE if eth
     * @param payed amount of payed with decimals
     * @param bought bought amount of 0gas with decimals
     * @param expirationTime timestamp, when signature will die
     * @param signature signed message from backend
     */
    function buy(
        address token,
        uint128 payed,
        uint128 bought,
        uint256 expirationTime,
        bytes calldata signature
    ) external payable nonReentrant {
        uint256 _sellEnd = sellEnd;
        uint128 _totalBought = totalBought;
        require(
            ((_sellEnd - 35 days <= block.timestamp &&
                block.timestamp < _sellEnd - 21 days) ||
                (_sellEnd - 14 days <= block.timestamp &&
                    block.timestamp < _sellEnd)) && _totalBought < hardcap,
            "Buy is not available"
        );
        require(expirationTime >= block.timestamp, "Signature out of time");
        require(payed > 0 && bought > 0, "Zero amount");
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                token,
                                payed,
                                bought,
                                expirationTime
                            )
                        )
                    ),
                    signature
                )
            ),
            "Crowdsale: incorrect signature"
        );
        _totalBought += bought;
        require(hardcap >= _totalBought, "Hardcap exceeded");
        totalBought = _totalBought;
        userToBalance[_msgSender()][3] += bought;
        uint256 balance = userToBalance[_msgSender()][3];
        require(balance >= minPurchase && balance <= maxPurchase, "Purchase");
        if (token == NATIVE) {
            require(msg.value == payed, "Wrong amount payed");
            userToBalance[_msgSender()][0] += payed;
        } else {
            uint256 id = tokenToId[token];
            require(id != 0, "Wrong token");
            userToBalance[_msgSender()][id] += payed;
            TransferHelper.safeTransferFrom(
                token,
                _msgSender(),
                address(this),
                payed
            );
        }
        emit Buy(bought, payed);
    }

    /**
     * @notice allow users claim bought 0gas tokens if softcap was earned
     */
    function claim() external nonReentrant {
        require(
            (block.timestamp > sellEnd && totalBought >= softcap) ||
                totalBought == hardcap,
            "Claim not available now"
        );
        uint256 balance = userToBalance[_msgSender()][3];
        require(balance > 0, "Nothing to claim");
        totalClaimed += balance;
        delete userToBalance[_msgSender()];
        TransferHelper.safeTransfer(zeroGas, _msgSender(), balance);
        emit Claim(balance);
    }

    /**
     * @notice allow users withdraw their payments if softcap wasn't earned
     */
    function refund() external nonReentrant {
        require(
            block.timestamp > sellEnd && totalBought < softcap,
            "Refund not available now"
        );
        uint128[4] memory balance = userToBalance[_msgSender()];
        require(balance[3] > 0, "Nothing to withdraw");
        delete userToBalance[_msgSender()];
        if (balance[0] > 0) {
            (bool success, ) = payable(_msgSender()).call{value: balance[0]}(
                ""
            );
            require(success, "ETH not transfered");
        }
        for (uint256 i = 1; i < 3; ) {
            if (balance[i] > 0) {
                TransferHelper.safeTransfer(
                    tokens[i - 1],
                    _msgSender(),
                    balance[i]
                );
            }
            unchecked {
                ++i;
            }
        }
        emit Withdraw(balance[0], balance[1], balance[2]);
    }

    /**
     * @notice allow admin claim rised funds and 0gas
     */
    function claimRised() external onlyRole(0x0) nonReentrant {
        uint256 amount = totalBought;
        uint256[4] memory balance;
        if (amount >= softcap) {
            balance[0] = address(this).balance;
            if (balance[0] > 0) {
                (bool success, ) = payable(_msgSender()).call{
                    value: balance[0]
                }("");
                require(success, "Eth not transfered");
            }
            for (uint256 i = 1; i < 3; ) {
                address token = tokens[i - 1];
                balance[i] = IERC20(token).balanceOf(address(this));
                if (balance[i] > 0) {
                    TransferHelper.safeTransfer(
                        token,
                        _msgSender(),
                        balance[i]
                    );
                }
                unchecked {
                    ++i;
                }
            }
            if (block.timestamp > sellEnd || amount == hardcap) {
                amount =
                    totalClaimed +
                    IERC20(zeroGas).balanceOf(address(this)) -
                    amount;
                if (amount > 0) {
                    TransferHelper.safeTransfer(zeroGas, _msgSender(), amount);
                }
            } else {
                delete amount;
            }
        } else {
            require(block.timestamp > sellEnd, "Claim not available now");
            amount = IERC20(zeroGas).balanceOf(address(this));
            TransferHelper.safeTransfer(zeroGas, _msgSender(), amount);
        }
        require(
            amount > 0 || balance[0] > 0 || balance[1] > 0 || balance[2] > 0,
            "Nothing to claim now"
        );
        emit ClaimRised(balance[0], balance[1], balance[2], amount);
    }

    /**
     * @return allowable - array with 2 numbers
     * allowable[0] - min amount 0gas, that user can buy
     * allowable[1] - how many 0gas user can buy, till reach max purchase
     */
    function getAllowable(address user)
        external
        view
        returns (uint256[2] memory allowable)
    {
        uint256 bought = userToBalance[user][3];
        allowable[0] = bought >= minPurchase ? 1 : minPurchase - bought;
        allowable[1] = maxPurchase - bought;
    }

    /**
     * @notice return price (price / denominator)
     */
    function getPrice()
        external
        pure
        returns (uint256 price, uint256 denominator)
    {
        return (44, 1000);
    }

    /**
     * @notice return current stage, = 0 if pause, = -1 if not start,
     * = 3 if ended
     */
    function getStage() external view returns (int256) {
        uint256 _sellEnd = sellEnd;
        if (_sellEnd == 0 || _sellEnd - 35 days > block.timestamp) {
            return -1;
        }
        if (hardcap == totalBought) {
            return 3;
        }
        if (block.timestamp < _sellEnd - 21 days) {
            return 1;
        }
        if (block.timestamp < _sellEnd - 14 days) {
            return 0;
        }
        if (block.timestamp < _sellEnd) {
            return 2;
        }
        return 3;
    }

    /**
     * @notice return array with start and end sell timestamp for all periods
     */
    function getTimestamps()
        external
        view
        returns (uint256[2][2] memory timestamps)
    {
        uint256 _sellEnd = sellEnd;
        if (_sellEnd != 0) {
            timestamps[0] = [_sellEnd - 35 days, _sellEnd - 21 days];
            timestamps[1] = [_sellEnd - 14 days, _sellEnd];
        }
    }
}
