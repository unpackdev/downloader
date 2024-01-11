// SPDX-License-Identifier: MIT
/**
                               ╓"^  ▐▒└       "∩╖
                          "Q▐   ▒    ▄▐       ╡└▌  ,█   ,
                       █    █µ  ▀└└           └▀  #▀▓   ╓╙▀
                 ²▄     ▀                              4⌐   └▀#
                  `█▄▀                                     ▄└    ,
                                                              ▄█▄└
          ╔└,                                                   '¬ ,#╙
            ▀▄▀                                                    ╙▄▄
       a▄╖▌▄                                                         ▄#"
         "▀                      , ╓█▄,                              "└
     "▀▄,                  ╓█    █▌╙████▄                             ,M"└▐
                         ,██▌   ╫██  ████ ██▀█▄▄▄▄,,                   ▀"
    µ▄▀▀               ,█████   ███ ▐██▀  ╟███▄▄▄▄╙╙▀╙╨╩▒▀ªwµ           K⌐▒▀
     └▀▀             ,██▀▐███▌  ███ ╟██     ▀██████████▄▄  └7V▌¥µ       *▀T`
                    ▄█▀  ▐████  ╫██ ╟██      ███       └██▌    └⌐▀▄
                   ██    ]█████ ╟██ ╟██     ████▄▄▄█████▀└     ^  "U
    ,             █▌      █████▄╟█▌ ▐██      ███████████▄▄ `≈,    ▄
    ▀`            █▄   %  ██▌╟████▌ ▐██      ██▌      └▀▀████, ''          ▀▀
                   ▀W▄«╛  ██▌ ████▌ ]██ ▐██▀▀██⌐           ╙▀██▄
                          ██▌  ███⌐  ██  ╟█████▀█            ╓██▌
       ,       ▌   ▀▄#    ██▌   ██   ██   ▀╙▀██████████████████▀        ,
    ,#░▄       ▌    ▌▀▄   ██▌    █#█▀█████▄╙▀▄▄▄╙▀███▀▀█▀▀▀▀▀└          ▄▄╝▀▀
    ╙'         █    ▌ ╙   ██    ▀  █▄██.╙▀███▄    ]█ε                     '"
     ƒ` ,▌      ▀    ▀▄▄▄█▀`   ▐    └' ╟▌  ╙▀███████                  ^▀╗▄
     '^└          ▀w, ,▄▀       ▀▄µ,,▄█▀       └╙└'                  ▄
        ,▄▀└                      '└└                               ╗╥╜Σ▄
            ▄▀                                                    #▄  "¬
            ,#▀                                                  └ *└¥
           └'  á╖▄                                                  "
              ╝▀.   ▄                                     ,▄█
                 ╓ ╜    ▄                              ▄  "  ▀▄
                  ╙▀   á.  ▐ ╓                     ▄    █
                      ╙▀   ╫╩`  ▌║⌐      #▀ε  └└µ  ▌▀    ▀
                           └   ▐░▌       '"▄   ,ì  ╙ '
                                          └
*/

/// @title NLB NFT Interface
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// Contract address: 0x0E29086b5A3C8A0ABd0662F5f1a4BE2bEE158058
/// Credits: 0xCursed @nftchance @masonnft @squeebo_nft
/// https://www.nlbnft.com/

pragma solidity ^0.8.8;

import "./IERC721Enumerable.sol";

interface INLBNFT is IERC721Enumerable {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool);
}
