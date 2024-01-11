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
// Project: Probably Nothing
// Token: PRBLY
// About: Probably Nothing is more than a meme, it is a case study on how future businesses will operate. Guided by strong values and championed by a passionate community, Probably Nothing will become one of the most respected companies in Web3. Now that is definitely something.
// Founder: @fungibIes, @audieleon, @BlockchainPadawan, @justkidlash, @0xEwok, @px_goose, @steelersfan331
// Follow us: @Probably0
// Join us: Discord.gg/Probably0
// Visit us: Probably0.com
//
pragma solidity ^0.8.4;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./IProbablyNothing.sol";

/** @title Probably Nothing Token - PRBLY
 * @author 0xEwok and audie.eth
 * @notice This is the utility token for the Probably Nothing ecosystem of
 * products and community
 * @dev We kept this contract as simple as possible deliberately, see PN history :)
 */
contract ProbablyNothing is
    IProbablyNothing,
    ERC20Capped,
    Ownable,
    ERC20Burnable
{
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    ) ERC20(name_, symbol_) ERC20Capped(cap_) {}

    /** @notice Allows owner to mint new tokens
     * @param account The address to receive minted tokens
     * @param amount The amount of new tokens to mint
     */
    function mint(address account, uint256 amount) public override onlyOwner {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}
