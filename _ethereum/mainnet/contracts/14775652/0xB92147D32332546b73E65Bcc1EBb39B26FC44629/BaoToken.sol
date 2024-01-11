// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                                       -\**:. `"^`
//                                     ;HNXav*,^;}?|:,.`
//                                    tbKX&]:,:7I}=\:-_._,`
//                                  :OKgTv)*7}ri=*;::,^``:;:^
//                               :&S@OTnccvtl])*\;:--~.`_;;-,^.`
//                            :cdXDOhT&Yuctl1=*;::,^..,;+*;:--,"~^.
//                         ;LX8dXSDOhasocv}1>+|;:---:;|||;:--,"_^^^..`
//                      :3@bd8dXSDPTasocvtl]>+|;::::;;;:::--,_~^^^..'````
//                   `laP@d88d@DhT0Yo3cjt}i]=+*\;;:::::::---,_^^^..'``    ``
//                 `)3&hSd8dbDhT&YoccvIt}l17=)*|;;:::::::--,"_^^^..'```     ``
//                ;=rnOb88d@OT&nucvjItr}i17==+**\;;;:::::--,"~^^^..''``        `
//              ^^:lnOXg8XDhaYucvjttr}lir3Luv=**|;;;;;:::--,_~^^....'-XMMh='     `
//             ``~>YOdKKd@haYucvttrrINMMMMMMMMMMj\;;;;::::-,"~^^....-MMMHDr=:`
//              ,7YDgmK8@haYucItr}}MMMMMMMMmt|1MMM=;;;;::::-,_^^....MMQ8OT-`';`
//          ` `-}&Smqm8SPTsucjr}}lMMMMMMMMMDl|]MMMM|;;;;:::--"^^..''MMmSOhV7)1:`
//        '"^,+vhdHNNEbOT&ocjtllitMMMMMMMMMMMMMMMMM1||\;;;::-"^..''`TMNKSDhaLt\-
//        =)=}nOmNQBHgDhaYuvIrli?jMMMMMMMMMMMMMMMMM1|||;;;::-~.'''``.dMBq8Oaor*|
//       cLY0OgNQQQWHdDh0Yuvt}i?11MMMMMMMMMMMMMMMMM**|;;;:::-_..''```.c#WHSaul7+        `
//      =OS8mNQMMMMQH8DhasucIrli111MMMMMMMMMMMMMMM+*|;;;::::-,^..''````.1VEHda7`        ``
//      @mHWQMMMMMMQNEbDkan3vtli1]>=?SMMMMMMMMMh)**|\;;::::--,~^..-'```````,,``````     ``
//      NQMMMMMMMMMMQNKbOh0Luv}i7==))))))))+*****||\;;;1MMMXkncuOKo.'''````````````````````
//      QMMMMMMMMMMMMQNmdDh&n3I}17==)))))))+****|\;;;;:::::*71=;,~^^...''''````````````````
//      QMMMMMMMMMMMMMQBHEbOTVocjtli?11]>>==)+**||;;;;::::::----,,_~^^^.........''''''````
//      jMMMMMMMMMMMMMMMQ#q8@hTVLuccvjt}}l?1]>=)***|\;;;::::::-----,,,"__~^^^^^......''```
//       qMMMMMMMMMMMMMMMMWNmXDha&noouccjtr}li17==)+**|\;;;::::::::-----,,,"_~^^^....'``'
//        MMMMMMMMMMMMMMMMMQBHgbOhT0Vnoo3cvIt}li117>=)***|\;;;;::::::::----,,,_~^^^..'''
//         QMMMMMMMMMMMMMMMMQWNq8bOhTa&snoucvjt}ll?1]>=))**||\;;;;;:::::::----,"_^^^..'
//          -MMMMMMMMMMMMMMMMMQWNq8bDOhka0sLo3cvjIr}li?1]7>==)+***|\;;;;:::::----,,~^
//            ;NMMMMMMMMMMMMMMMMQQNqEgdSDOhka0Ynou3ccvjItr}lli117>=))***||;;;:::::-
//               ]MMMMMMMMMMMMMMMMQQWBNHmKdb@OhkTa&sYLooucccvjItr}}li?17==)+*||:'
//                 .1qMMMMMMMMMMMMMMMQQBNHqEKdSDOPkaa&snoou3cccvvjItr}li1]>;,`
//                      :IOMMMMMMMMMMMMQQBNHm8XSOPka0Vnou3cvjtr}llli?>:"`
//                            _|jnbQMMMMMMMMQBNqK8XSDPTasLucvI|~.`
//                                   oMMMMMMMMMMMMQqSTocri7)*|:.
//                                 IMMMMMMMMMMNdksc}1)\::-,~^..'`
//                                lTMMMQMMMQqD0oj}1=*;:-_^.'```````
//                              -cOQMN8KMMM#gO&uj}1=*;:-^.''`````````
//                             :hHQ#gDSQMMMMHSTs3v}])|:-~^.'````` '.``
//                            1KMQEOaLXMMMMMQEDTn3Ii7+;:-_^.''````'^.'`
//                           -WMMghYuYHMMMMMM#dO0Lcr?=|;:-_^..'```.^^.'
//                           gMMKhscckWMMMMMMQm@Ts3Il7*\::-_^..'``^",~.'
//                          ?MMNPscvobMMMMMMMMN8Paov}1)*;:-,_^..``,---~.`
//                         .MMWS&utvV8MMMMMMMMWEDTs3jl>*\;:--"^.`.:\;:-_`
//                         lMMNOLjrcTgMMMMMMMMMNXOTYujl>*\:::-,^.`;ll=-`
//                         'MMNDYccclQMMMMMMMMMWq8@PTsct1)|;;;:"
//                            -;\-`  QMMMMMMMQ#HEEgdSOaLv}i]+:,^
//                                   ]MMMMMHdhs3t`  ^P8gbhu];-.
//                                    MMMMW8kci>)    hgKDV}|:^'
//                                    @MMMHho1*;:    hNHDYl\:^
//                                     dMMmav=;:      |t3v7:.
//                                       '~^'
//
//                                         author: phaze

import "./AccessControl.sol";
import "./IERC721.sol";

import "./BaoStaking.sol";

contract BaoToken is AccessControl, BaoStaking {
    bytes32 public constant MINT_AUTHORITY = keccak256("MINT_AUTHORITY");
    bytes32 public constant BURN_AUTHORITY = keccak256("BURN_AUTHORITY");

    address public treasuryAddress = address(0x69D8004d527d72eFe1a4d5eECFf4A7f38f5b2B69);

    constructor() ERC20("Bao Token", "BAO", 18) {
        _setupRole(DEFAULT_ADMIN_ROLE, treasuryAddress);
        _mint(treasuryAddress, 10_000_000 * 1e18);
    }

    /* ------------- Restricted ------------- */

    function mint(address user, uint256 amount) external payable onlyRole(MINT_AUTHORITY) {
        _mint(user, amount);
    }

    /* ------------- ERC20Burnable ------------- */

    function burn(uint256 amount) external payable {
        _burn(msg.sender, amount);
    }

    function burnFrom(address user, uint256 amount) external payable {
        if (!hasRole(BURN_AUTHORITY, msg.sender)) {
            uint256 allowed = allowance[user][msg.sender];
            if (allowed != type(uint256).max) allowance[user][msg.sender] = allowed - amount;
        }
        _burn(user, amount);
    }

    /* ------------- MultiCall ------------- */

    function multiCall(bytes[] calldata data) external {
        unchecked {
            for (uint256 i; i < data.length; ++i) address(this).delegatecall(data[i]);
        }
    }

    /* ------------- Owner ------------- */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function recoverNFT(IERC721 token, uint256 id) external onlyOwner {
        token.transferFrom(address(this), msg.sender, id);
    }
}
