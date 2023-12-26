// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.9;
/*
 *@#+:-*==   .:. :     =#*=.  ..    :=**-    :+%@@@@@#*+-..........        .-.-@@
 *%%*.. +*:    =%.--     :+***+=++**=.    .+%@@@@@*-            . . .     .  -+= 
 *         -==+++. :#:        ..       .=#@@@@@*-   .:=*#%@@@@%#*=.  ...:::::    
 *     .:-======+=--%@*.             .*@@@@@@+   .=#@@@@@@##*#%@@@@@*-           
 *-:::-===-::------+#@@@*.         :*@@@@@@=   :*@@@%*==------=--+@@@@@#=:    .-=
 *=++==:::      .:=+=:.-=. .-**+++#**#@@@+   -#@@%=-::==       :*+--*@@@@@@@@@@@@
 *.....-=*+***+-.   .+#*-    +@@@@@@@@@+.  -%@@%-::. .-     .::-@@@%- -#@@@@@@@@@
 *   :*=@@@@@@@@@@#=.  -*@%#%@@@@@@@@*.  :#@@%-::    :=    =*%@@@@@@@%++*+*%@@@@@
 * .+*%@#+-:-=+*##*#@#=.  -*%@@@@@#=.  -#@@%-::       -:       :+@@@@@@@@*:  ..  
 *@@@%=         .-. :*@@#=.   ...   .=%@@#-:-      :-=++#####+=:  -#@@@@@@@@%*+++
 *@*:       :-=+::..   -#@@%+==--=+#@@%=.:+*=  :=*%@@@@%@@@@@@@@@*- .+%@@@@ SMG @
 *.     .+%@@=%%%##=....  :+*%%@@%#+-. =%@@@@@@%@@@@@@@@@@@%%%%@@@@@#=:-+%@@@@@@@
 */
import "./SafeERC20.sol";
import "./OperatorRole.sol";

/**
 * @title OperatorRecoverable
 * @notice Copyright (c) 2023 Special Mechanisms Group
 *
 * @author SMG <dev@mechanism.org>
 *
 * @dev The OperatorRecoverable contract is designed to allow a contract's 
 *      operator to recover tokens which were accidentally transferred to
 *      it, but which the contract does not otherwise support. This prevents
 *      users having their tokens "bricked", and also allows the operator to
 *      clean out any spurious tokens that may have been transferred to it
 *      on purpose.
 */
abstract contract OperatorRecoverable is OperatorRole {
    using SafeERC20 for IERC20;

    /**
     * @notice Maps token addresses to whether they are unrecoverable.
     */ 
    mapping(address => bool) private isTokenUnrecoverable;

    event SetUnrecoverable(address indexed token);
    event Recovered(address indexed token, address indexed operator);

    /**
     * @notice Marks a token address as unrecoverable by the operator. 
     *
     * @dev Only the operator may call this function. 
     * @dev Once a token is marked as unrecoverable there is no way for
     *      anyone, operator included, to mark it as recoverable again. 
     *
     * @param _token Address of the token that will be unrecoverable.
     */
    function setTokenUnrecoverable(
        address _token
    ) 
        public 
        onlyOperator 
    {
        isTokenUnrecoverable[_token] = true;
        emit SetUnrecoverable(_token);
    }

    /**
     * @notice Recovers recoverable tokens.
     *
     * @dev Only the operator may call this function.
     * @dev The purpose of this function is to allow the operator to assist 
     *      users who accidentally transferred the wrong kind of tokens to 
     *      the smart contract.
     * @dev If the token being recovered is ETH (which is not an ERC20 and
     *      hence does not have a token address), the caller should provide 
     *      `0x0` as the value of `_token`.
     *
     * @param _token Address of the token that the operator will recover. 
     */
    function recoverToken(
        address _token
    ) 
        external 
        onlyOperator 
    {
        require(
            !isTokenUnrecoverable[_token],
            "OperatorRecoverable: cannot recover, token marked as unrecoverable."
        );

        if (_token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            /* ETH */   
            (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "OperatorRecoverable: ETH transfer failed.");
        } else {
            /* ERC20 */   
            IERC20(_token).safeTransfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        }

        emit Recovered(_token, msg.sender);
    }
}
