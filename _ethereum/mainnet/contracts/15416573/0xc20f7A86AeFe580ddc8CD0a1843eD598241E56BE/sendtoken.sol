// SPDX-License-Identifier: MIT
//
//                                      :=+*#%%%%%%%%#*=-.                  .-=*#%%@@@@@%%#*+-.
//                                 .-*%%*=:.          :-+*%#+.          :+#@@@@@@@@@@@@@@@@@@@@@#+-
//                               -#%+-      .:--=---:.     .=#%+.    :*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:
//                            .+%*:   .-+##*+==----=++##*+:   .=##=+%@@@@@@@@@%#+==-----==+*%@@@@@@@@@%+.
//                           *@+   .+%#+:               .-*%*:   *@@@@@@@@%+-                 :+%@@@@@@@@+
//                         .%*.  .*@+.                      -%%=%@@@@@@@*:                       .+@@@@@@@%:
//                        =@=   +@=                           #@@@@@@@@-                            +@@@@@@@+
//                       +@-  :%#.                           *@@@@@@#.*@:                            .#@@@@@@*
//                      -@=  :@*                            -@@@@@@%   #@                              *@@@@@@+
//                     .@*  .@*                             %@@@@@%@=   %+                              *@@@@@@.
//                     *@   +%                             -@@@@@@:*@.  =@                               %@@@@@+
//                     @*   %+                             *@@@@@% .@+   @-                              *@@@@@#
//                    .@+..:@:                             %@@@@@+  %#...%+                              =@@@@@%
//                    :@%##%@:                             %@@@@@+  %@###@*                              =@@@@@%
//                    .@+   @:                             #@@@@@#  @#   %=                              +@@@@@#
//                     %#   %+                             =@@@@@@.:@=  .@:                              %@@@@@+
//                     +@:  =@.                             @@@@@@*#%   +%                              +@@@@@@:
//                      %%   %%                             =@@@@@@@:  .@=                             =@@@@@@+
//                      :@*  .%%.                            #@@@@@-   %%                             *@@@@@@#
//                       :@*   *@=    .-=*#%%@@@@@@@@%#*+=:.  *@@@-  .%#.                           =%@@@@@@*
//                        .%#   :%#=#@@@@@@@@@@@@@@@@@@@@@@@%++@*.  -@@@+.                        =%@@@@@@@-
//                          *%-.+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+.*@@@@@@*=.                 .=*@@@@@@@@*
//                           +@@@@@@@@@@%*+=-:......:-=*#@@@@@@@@@@@@@@@@@@@@@#+=--:::::--=+#@@@@@@@@@@@%.
//                          *@@@@@@@@*-.                  :=%@@@@@* :*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*: +%:
//                        :%@@@@@@%=                         -#@@=   +@*-*@@@@@@@@@@@@@@@@@@@@@@@#=+@+   -@=
//                       =@@@@@@@=                            *@:  -%@@%:  .:=+*#%%%@@@@%%#*+=:.    .#%:  :@*
//                      +@@@@@@#.                            *@:  -@@@@@@.                            =@=  :@*
//                     -@@@@@@*                             :@=   @@@@@@@#                             +@:  =@-
//                     @@@@@@#                              *%   *#=@@@@@@-                             ##   %%
//                    =@@@@@@.                              @=  .@= #@@@@@%                             :@.  =@:
//                    #@@@@@%                              .@.  =@. =@@@@@@.                             @=  .@-
//                    %@@@@@*                              :@%%%%@. :@@@@@@:                             @%%%%@=
//                    %@@@@@*                              .@.  =@. :@@@@@@:                             @=  .@-
//                    *@@@@@%                               @=  .@= +@@@@@@                             :@.  =@:
//                    -@@@@@@-                              *#   ## @@@@@@*                             *#   #%
//                     #@@@@@%.                             :@-  .@%@@@@@@.                            =@:  -@-
//                     .@@@@@@%.                             *@:  *@@@@@@+                            =@=  :@*
//                      :@@@@@@@-                             #@:*@@@@@@%                            *@-  .@#
//                       :%@@@@@@#:                           .%@@@@@@@@.                          =%*.  -@+
//                         +@@@@@@@#-                       :*@@@@@@@%=+@+.                     .+%*.   +%-
//                          :%@@@@@@@@#=:               .-+%@@@@@@@@%.   =%%+:               :+#%+.   =@#.
//                            -#@@@@@@@@@@%#*+=====++*#@@@@@@@@@@@+:+%*-   .-+*##*++====+*###+-.   :*%+:
//                               =#@@@@@@@@@@@@@@@@@@@@@@@@@@@@*:     -*@*-.     ..:::::..      -+%#-
//                                 .-*%@@@@@@@@@@@@@@@@@@@@#+:           -+%%*+-:.       .:-=*%%*-.
//
//
//
//
//                                 ▀█▀ █░█ █▀▀ █▀▀ █░█ ▄▀█ █ █▄░█ ▀█▀ █▀▀ █▀▀ █░█ ░ █ █▀█
//                                 ░█░ █▀█ ██▄ █▄▄ █▀█ █▀█ █ █░▀█ ░█░ ██▄ █▄▄ █▀█ ▄ █ █▄█
//
//
//
//
//

pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Context.sol";
import "./Address.sol";

contract SendToken is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    receive() external payable {
        revert("SendToken: 0");
    }

    function sendNativeCoin(address[] memory _recipients, uint256[] memory _values)
        external
        payable
        nonReentrant
    {
        require(_recipients.length == _values.length, "SendToken: 1");
        for (uint256 i; i < _recipients.length; ++i) {
            (bool success, ) = _recipients[i].call{value: _values[i]}("");
            require(success, "SendToken: 1");
        }
    }

    function sendERC20Token(
        address _token,
        address[] memory _recipients,
        uint256[] memory _values
    ) external {
        require(_recipients.length == _values.length, "SendToken: 2");
        IERC20 token = IERC20(_token);
        for (uint256 i; i < _recipients.length; ++i) {
            token.safeTransferFrom(_msgSender(), _recipients[i], _values[i]);
        }
    }

    function sendERC721Token(
        address _token,
        address[] memory _recipients,
        uint256[] memory _ids
    ) external {
        require(_recipients.length == _ids.length, "SendToken: 3");
        IERC721 token = IERC721(_token);
        for (uint256 i; i < _recipients.length; ++i) {
            token.safeTransferFrom(_msgSender(), _recipients[i], _ids[i]);
        }
    }

    function sendERC1155Token(
        address _token,
        address[] memory _recipients,
        uint256[] memory _ids,
        uint256[] memory _values
    ) external {
        require(_recipients.length == _ids.length, "SendToken: 4");
        require(_ids.length == _values.length, "SendToken: 5");
        IERC1155 token = IERC1155(_token);
        for (uint256 i; i < _recipients.length; ++i) {
            token.safeTransferFrom(
                _msgSender(),
                _recipients[i],
                _ids[i],
                _values[i],
                bytes("SendToken")
            );
        }
    }
}
