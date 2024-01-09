// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./console.sol";

contract Crowdsale is AccessControl, ReentrancyGuard {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public immutable ARA;
    uint256 public distributed;

    mapping(address => bool) public whiteListed;

    event TokensSold(
        address token,
        uint256 payAmount,
        uint256 getAmount,
        address user
    );

    constructor(
        address _ARA,
        address _USDC,
        address _USDT,
        address _BTC,
        address _BNB,
        address _signer,
        address _owner
    ) {
        require(
            _ARA != address(0) &&
                _USDC != address(0) &&
                _USDT != address(0) &&
                _BTC != address(0) &&
                _BNB != address(0) &&
                _signer != address(0) &&
                _owner != address(0),
            "Crowdsale: address = 0X0.."
        );
        whiteListed[_USDC] = true;
        whiteListed[_USDT] = true;
        whiteListed[_BTC] = true;
        whiteListed[_BNB] = true;
        whiteListed[NATIVE] = true;
        ARA = _ARA;
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(SIGNER_ROLE, _signer);
    }

    receive() external payable {}

    function getTokens(address token, address to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        uint256 amount;
        if (token == NATIVE) {
            amount = address(this).balance;
            require(amount > 0, "Crowdsale: contract hasn`t tokens");
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "Crowdsale: tokens didn`t transfer");
        } else {
            amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, "Crowdsale: contract hasn`t tokens");
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    function buyTokens(
        address token,
        uint256 payAmount,
        uint256 getAmount,
        uint256 expirationTime,
        address refAddress,
        bytes calldata signature
    ) external payable nonReentrant {
        if (token == NATIVE) {
            payAmount = msg.value;
        }
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                token,
                                payAmount,
                                getAmount,
                                expirationTime
                            )
                        )
                    ),
                    signature
                )
            ),
            "Crowdsale: uncorrect signature"
        );
        require(expirationTime >= block.timestamp, "Crowdsale: expirated");
        require(whiteListed[token], "Crowdsale: token not whiteListed");
        require(
            payAmount > 0 && getAmount > 0,
            "Crowdsale: pay or get 0 tokens"
        );

        address user = _msgSender();
        if (refAddress != address(0) && refAddress != user) {
            uint256 toCodeOwner;
            toCodeOwner = (getAmount * 3) / 100;
            if (toCodeOwner != 0) {
                distributed += toCodeOwner;
                require(
                    IERC20(ARA).balanceOf(address(this)) >=
                        (toCodeOwner + getAmount),
                    "Crowdsale: crowdsale balance too low"
                );
                TransferHelper.safeTransfer(ARA, refAddress, toCodeOwner);
            }
        } else {
            require(
                IERC20(ARA).balanceOf(address(this)) >= getAmount,
                "Crowdsale: crowdsale balance too low"
            );
        }

        distributed += getAmount;

        if (token != NATIVE) {
            TransferHelper.safeTransferFrom(
                token,
                user,
                address(this),
                payAmount
            );
        }

        TransferHelper.safeTransfer(ARA, user, getAmount);

        emit TokensSold(token, payAmount, getAmount, user);
    }
}
