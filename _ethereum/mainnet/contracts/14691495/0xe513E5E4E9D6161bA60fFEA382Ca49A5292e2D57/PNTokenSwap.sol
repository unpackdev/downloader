//SPDX-License-Identifier: Unlicense
//                                                      *****+=:.  .=*****+-.      -#@@#-.   .+*****=:.     .****+:   :*****+=:.   -***:  -+**=   =***.
//                ...:=*#%%#*=:..       .+%@*.          @@@@%@@@@* .#@@@%%@@@*.  +@@@@%@@@-  :%@@@%%@@@-    +@@@@@#   -@@@@%@@@@+  +@@@-   #@@@:  %@@%
//             .:=%@@@@@@@@@@@@@@#-.  .#@@@@%:          @@@% .#@@%=.#@@*  +@@@= -%@@#: #@@@: :%@@- .@@@@   .@@@#@@#   -@@@* :%@@*: +@@@-   =@@@+ =@@@.
//           .-%@@@@@@%%%%%%%%@@@@@@+=%@@@%*.           @@@%  :@@@*.#@@*  =@@@= +@@@-  *@@@- :%@@=..%@@@   .@@%.@@%:  -@@@* .+@@#: +@@@-    *@@@:%@@+
//          -%@@@@%##=.      :*##@@@@@@@%#.             @@@@:-*@@%=.#@@#::*@@%- +@@@-  +@@@= :%@@*+#@@@=   +@@%.@@@#  -@@@#+#@@@=  +@@@-    .#@@=@@%
//        .=@@@@#*:              *@@@@@#-               @@@@@@@@#+ .#@@@@@@@@=  +@@@-  +@@@+.:%@@%##@@#:   @@@#.%@@#  -@@@%#%@@#-. +@@@-     +@@@@@:
//       :*@@@@+.              .=%@@@#*.                @@@@***+.  .#@@%+*%@@#: +@@@-  *@@@+ :%@@-  %@@@. .@@@#=*@@%- -@@@* :*@@@= +@@@-      #@@@#
//      .#@@@%=              .-#@@@%#:    :             @@@%       .#@@*  =@@@= +@@@=  *@@@- :%@@-  +@@@= +@@@@@@@@@* -@@@*  =@@@= +@@@-      *@@@:
//      =@@@@=              :*@@@@#-.   .-%:            @@@%       .#@@*  =@@@= -%@@*=-%@@#. :%@@*=-%@@@: @@@@++*@@@# -@@@#--*@@%- +@@@*----. *@@@:
//     .@@@@+             :=#@@@#+:    -+@@*.           @@@%       .#@@*  =@@@=  -#@@@@@@#:  :%@@@@@@@*+ .@@@#  .*@@%--@@@@@@@@#-  +@@@@@@@@: *@@@:
//     -@@@%            .-#@@@%*:      *@@@@.           +++=       .=++-  :+++:   :++++++.   .++++++++.  :+++:   :+++-.+++++++=:   -++++++++. -+++.
//     #@@@%           :*@@@@#-.       -%@@@.
//     %@@@%         :+#@@@#=:         :%@@@.                             .                                                        .
//     +@@@%       .=#@@@@*:           =@@@@.           ++++=  :++=   :++***++: .=+++++++++. =++=  .+++-  +++=  .+++=. :+++-   :++***++:
//     :@@@%-     :*@@@@#-.            *@@@%.           @@@@%  =@@#  :#@@@#%@@#:-%@@@@@@@@@: %@@%. :@@@*  @@@%  :@@@@+ -@@@+  :#@@%#@@@#:
//      @@@@#   .*#@@@#=:             =%@@@=            @@@@@= =@@# .+@@@+:=%@@*:---#@@@+--. %@@%. :@@@*  @@@%  :@@@@#:-@@@+ :%@@*::*@@@-
//      -@@@@+ =#@@@@*:              -%@@@#.            @@@#@% =@@# :%@@*. .+@@%-   *@@@-    %@@%. :@@@*  @@@%  :@@@@@+-@@@+ =@@@=  :---.
//       =@@@@#%@@@#-.              =%@@@@-             @@@=@@*=@@# -@@@*   =@@@=   *@@@-    %@@@#*#@@@*  @@@%  :@@%+@%*@@@+ =@@@= -****:
//        =@@@@@@%=.              :*@@@@%-              @@@-%@%-@@# -@@@*   =@@@=   *@@@-    %@@@@@@@@@*  @@@%  :@@#-@@%@@@+ =@@@= +@@@@-
//        =@@@@@*.              -#%@@@@+:               @@@=:@@%@@# -@@@*   =@@@=   *@@@-    %@@%-:=@@@*  @@@%  :@@#.+@@@@@+ =@@@= .*@@@-
//      .%@@@@%:.    :*+-:-=*#%%@@@@@%-                 @@@=.#@@@@# .*@@%- :#@@#:   *@@@-    %@@%. :@@@*  @@@%  :@@# -@@@@@+ =@@@=  +@@@-
//     *%@@@@=.    :#%@@@%@@@@@@@@@*:.                  @@@= :@@@@#  -@@@%+#@@@+    *@@@-    %@@%. :@@@*  @@@%  :@@#  +@@@@+ .*@@@*+%@@@- -#%%:
//   :%@@@@#.     .#@@@@@@@@@@@@*:.                     @@@= .#@@@#   =@@@@@@@+     *@@@-    %@@%. :@@@*  @@@%  :@@#  -@@@@+  -%@@@@@@@@- :%@@:
//    .:-:.         ....:::.....                        ..     ...     ..:::..       ...      ..    ...   ...    ..    ....     .::.....    ..
//
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IPNTokenSwap.sol";

/** @title Probably Nothing Token Swap from PN to PRBLY
 * @author 0xEwok and audie.eth
 * @notice This contract swaps PN tokens for PRBLY tokens and compensates PN
 *         taxes
 */
contract PNTokenSwap is IPNTokenSwap, ReentrancyGuard, Ownable {
    address private v1TokenAddress;
    address private v2TokenAddress;
    address private v1TokenTaker;
    bool private swapActive;

    mapping(address => uint256) private swappedAmount;

    constructor(address _v1Token, address _v2Token) {
        v1TokenAddress = _v1Token;
        v2TokenAddress = _v2Token;
    }

    /** @notice Provides address of token being swapped
     * @return v1Address address of the V1 token contract
     */
    function getV1TokenAddress() external view override returns (address) {
        return v1TokenAddress;
    }

    /** @notice Provides address of received from swap
     * @return v2Address address of the V2 token contract
     */
    function getV2TokenAddress() external view override returns (address) {
        return v2TokenAddress;
    }

    /** @notice Provides address that receives swapped tokens
     * @return tokenTaker address that receives swapped tokens
     */
    function getV1TokenTaker() public view override returns (address) {
        return v1TokenTaker;
    }

    /** @notice Allows owner to change who receives swapped tokens
     * @param newTokenTaker address to receive swapped tokens
     */
    function setV1TokenTaker(address newTokenTaker)
        external
        override
        onlyOwner
    {
        v1TokenTaker = newTokenTaker;
    }

    /** @notice Allows any caller to see if the swap function is active
     * @return swapActive boolean indicating whether swap is on or off
     */
    function isSwapActive() external view returns (bool) {
        return swapActive;
    }

    /** @notice Allows owner to pause use of the swap function
     * @dev Simply calling this function is enough to pause swapping
     */
    function pauseSwap() external onlyOwner {
        swapActive = false;
    }

    /** @notice Allows owner to activate the swap function if it's paused
     * @dev Ensure the token taker address is set before calling
     */
    function allowSwap() external onlyOwner {
        require(v1TokenTaker != address(0), "Must setV1TokenTaker");
        swapActive = true;
    }

    /** @notice Check an addresses cumulative swapped tokens (input)
     * @param swapper Address for which you want the cumulative balance
     */
    function getSwappedAmount(address swapper) external view returns (uint256) {
        return swappedAmount[swapper];
    }

    /** @notice Swaps PN v1 tokens for PN v2 tokens
     * @param amount The amount of v1 tokens to exchange for v2 tokens
     */
    function swap(uint256 amount) external override nonReentrant {
        require(swapActive, "Swap is paused");
        IERC20 v1Contract = IERC20(v1TokenAddress);
        require(
            v1Contract.balanceOf(msg.sender) >= amount,
            "Amount higher than user's balance"
        );
        require(
            // Tranfer tokens from sender to token taker
            v1Contract.transferFrom(msg.sender, v1TokenTaker, amount),
            "Token swap failed"
        );

        IERC20 v2Contract = IERC20(v2TokenAddress);

        // Transfer amount minus fees to sender
        v2Contract.transfer(msg.sender, swapAmount(amount));

        // record the amount of swapped v1 tokens
        swappedAmount[msg.sender] = swappedAmount[msg.sender] + amount;
    }

    /** @notice Allows Owner to withdraw unswapped v2 tokens
     * @param amount The amount of v2 tokens to withdraw
     */
    function withdrawV2(uint256 amount) external onlyOwner {
        IERC20(v2TokenAddress).transfer(msg.sender, amount);
    }

    /** @notice Given a v1 Amount, shows the number of v2 tokens swap will return
     * @param v1Amount The amount of v1 tokens to check
     * @return v2Amount number of V2 tokens to be swapped for V1
     */
    function swapAmount(uint256 v1Amount) public pure returns (uint256) {
        // This results in moving the decimal place 4 positions to the RIGHT!
        // The reason is because v1 was 9 decimals, and v2 is 18 decimals.
        return v1Amount * 100000;
    }
}
