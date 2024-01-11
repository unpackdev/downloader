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
// Token: htPRBLY
// About: Probably Nothing is more than a meme, it is a case study on how future businesses will operate. Guided by strong values and championed by a passionate community, Probably Nothing will become one of the most respected companies in Web3. Now that is definitely something.
// Follow us: @Probably0
// Join us: Discord.gg/Probably0
// Visit us: Probably0.com
//
pragma solidity ^0.8.9;
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./StakedProbablyNothing.sol";

error Unimplemented();

/** @title Probably Nothing Holdier Tier - htPRBLY
 * @author 0xEwok and audie.eth
 * @notice This is a utility contract for calculating holder tiers, modeled as ERC20 to gracefully connect to EVM plug-ins.
 */
contract ProbablyNothingHolderTier is
    Ownable,
    ERC20
{

    address private prblyAddress;
    address private stakedPrblyAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        address prblyAddress_,
        address stakedPrblyAddress_
    ) ERC20(name_, symbol_) {
        prblyAddress = prblyAddress_;
        stakedPrblyAddress = stakedPrblyAddress_;
    }

    /** @notice The PRBLY address
     */
    function getPrblyAddress() public view returns(address) {
        return prblyAddress;
    }

    /** @notice The sPRBLY address
     */
    function getStakedPrblyAddress() public view returns(address) {
        return stakedPrblyAddress;
    }

    /**
     * @dev Proxy for PRBLY.totalSupply().
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC20(prblyAddress).totalSupply();
    }

    /** @notice The computed holder tier.
     */
    function balanceOf(address account) public view override returns (uint256) {
        uint256 prblyBalance = ERC20(prblyAddress).balanceOf(account);
        uint256 sprblyBalance = ERC20(stakedPrblyAddress).balanceOf(account);
        uint256 sprblyBalanceConvertedToPrbly = StakedProbablyNothing(stakedPrblyAddress).toBaseToken(sprblyBalance);

        return prblyBalance + sprblyBalanceConvertedToPrbly;
    }

    /**
     * @dev Disallowed
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        revert Unimplemented();
    }

    /**
     * @dev Disallowed
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        revert Unimplemented();
    }

    /**
     * @dev Disallowed
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        revert Unimplemented();
    }

    /**
     * @dev Disallowed
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        revert Unimplemented();
    }

    /**
     * @dev Disallowed
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        revert Unimplemented();
    }

    /**
     * @dev Disallowed
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        revert Unimplemented();
    }
}
