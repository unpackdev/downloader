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

import "./IERC721.sol";
import "./IERC20.sol";

import "./BaoToken.sol";
import "./Ownable.sol";

error NotActive();
error NoSupplyLeft();
error InsufficientValue();
error MaxEntriesReached();
error ContractCallNotAllowed();

contract Marketplace is Ownable {
    /* ------------- Events ------------- */

    event MarketItemPurchased(address indexed user, bytes32 indexed id);

    /* ------------- Structs ------------- */

    struct MarketItemData {
        uint256 start;
        uint256 end;
        uint256 tokenPrice;
        uint256 ethPrice;
        uint256 maxEntries;
        uint256 maxSupply;
        bytes32 dataHash;
    }

    /* ------------- Storage ------------- */

    mapping(bytes32 => uint256) public totalSupply;
    mapping(bytes32 => mapping(address => uint256)) public numEntries;

    BaoToken public immutable baoToken;

    constructor(BaoToken token) {
        baoToken = token;
    }

    /* ------------- External ------------- */

    function purchaseMarketItem(MarketItemData[] calldata marketItemData, bool tokenPayment) external payable onlyEOA {
        uint256 totalPayment;

        for (uint256 i; i < marketItemData.length; ) {
            MarketItemData calldata item = marketItemData[i];

            bytes32 itemHash = keccak256(abi.encode(item));

            unchecked {
                if (++totalSupply[itemHash] > item.maxSupply) revert NoSupplyLeft();
                if (block.timestamp < item.start || item.end < block.timestamp) revert NotActive();
                if (++numEntries[itemHash][msg.sender] > item.maxEntries) revert MaxEntriesReached();

                // overflow not possible, limited by supply
                if (tokenPayment) totalPayment += item.tokenPrice;
                else totalPayment += item.ethPrice;
            }

            emit MarketItemPurchased(msg.sender, itemHash);

            unchecked {
                ++i;
            }
        }

        if (tokenPayment) baoToken.burnFrom(msg.sender, totalPayment);
        else if (msg.value != totalPayment) revert InsufficientValue();
    }

    /* ------------- Owner ------------- */

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverNFT(IERC721 token, uint256 id) external onlyOwner {
        token.transferFrom(address(this), msg.sender, id);
    }

    /* ------------- Modifier ------------- */

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ContractCallNotAllowed();
        _;
    }
}
