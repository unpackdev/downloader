// SPDX-License-Identifier: MIT

//       THE ETHEREUM LODGE - 2022
//
//                                    **   **
//                               **************  *****
//                            **$$$$  ****   $$*******
//                          * $$$$$$$$$   $$* **   *$**
//                         *  $    $$$$$* $* *$$$$$$$$$**
//                        *  $$$$$$$$$$$$$ $$$$$$$$$**$$*
//                        $$  $$$$$$$ $$$$$$$$ $$$$$$$$$$$$
//                      *$ *$$$$$$$$$$$*$*$*$    *****$***
//                    **$$ $$$$$$*$ **    [[[[[[[   [[[
//                    **$**$$**$$$@@     [  #####  ## #
//                  *$$$*****$$$$$$         ..###   ###
//                  **$$$$$$$$ [[$$ ##        +++   ###
//                   $$$$$$**[[  [[$$    #          ##
//                     $$$***#[  #     ###      #   ##
//                     $$$$$$ ##++ #+        ## ######
//                     $$$$$#  ###       ##       ##
//                     $$$$$#   ##            ######
//                       $$$### ##      ##    #####
//                         $#$ #  +##  #   ##  ## #
//                         $$$$     #   +++#######
//                         $$*      ##############
//                         *$$# #  ++     ++++        ######
//                         $$###         ++###      ##      ++
//                         $# +#      #######+     +##+   ## ##
//                         *#+ ##     ++###+###    +  ###+     ##
//                         ## ##+#  # ++ +++++##  +  #++##       ##
//                        ##+#  ##  ++##+     ###++ ##++           #
//                       ##+ +   ++  +##+  +   +######## #          #
//                     ###+     ++++##          ++ # # ##+         ##
//                 ####  +        ++            +++++# ## ##+        #
//            ###++   +                           ##############+ +##+##
//          ##+       ##                         ++#+ ++#########++##  "
//        ####+                                    +#+ +++###############
//      ###                                       ++++++#+++++##########
//     ##+                                            ++ +     ####+++++
//    ##                              ++               +++        ##  ++
//    ##+                  ++                         +++++ +  # # ##+++
//    #      ++  +           ++                       ++@++ ++##### # ++
//    #    +   ####+                                +++++++###++####+##
//    #    +   ####+                                +++++++###++####+##
//    #   +    ###++                               +++++######## #######
//    #  +++    ####++++@                          +++++++++###   ###  #
//    #+ #+      ###++++++++                            ++++++#   ##+++#
//    ##+ +      #### #####++++                          ++++##    ###++
//    ##++      ###########++                          ++++++#      ## +
//    ###+      ##########+++                             #++#        ##
//    #+  +    +########++                         ++##########     
//   ###+        # ###+++++                         +++++#####      
//  ###+  +      #  ##+++                          +++++#######     
//  ##++##+     ##   ##++  ##                       ###########     
//   ##+##+     ###  ######              #####     ###++++#####
//   ##  ##     ##      ##  ######  ++              #+  ######
//   ##+#       ##      ##  ######+++++             ++ #######
//  ### #+    ###       ##  ########                  ## ####
//  ######+    ##       ##++    ##+                  ## ## ##
// +###  ####+##       ##                            +     #+
// ##++ +  ######      ##                                  ##
// +##       ++ #     +#                 @@@                #
// +#         + #    ##                                    ##
// ## +       # #    #                                      #+
// ##+        # #    # +                                    #+
// ##+        # #    ## ###                                ###
// ##+  +     ###    ##    ####                            +##
// #++     #  ##+   +#  ########                          ####
//##++        ##    ## ++   ####                         #####
// ##++       ++    #         +##         ##            ######
//+# +        +#   +#           +#+      #####         ######+
// # +       +#    #           +#+   ############           +##
// # +      ##    +#           +###+  ######### +###++      +#
//  ##++  + #     #     #             ###   #  #######++     #
//  ##++  + #     ##             +### #+#  #+####        #
//  ##+    +##    ##     ##         +###++#   #++####        #
//  # + +  +#     #                 +#+++# #+++###+         #
//   #      #     # +++++           +#+++# #+++###++        ##
//  +#      #     #    #####+        +#+++# #+++####++        #
//  # ##    ###   ###++           ++##+++# #+++####          #
//  ########  ##  ###              ###++## ##++##             #
//    ### ##     ## ##                ###########               #
//   ##+ ###      #####              #########                 #
//    ##### ###     ##+               ## ## ###                 +
//    ########## #  ##++             +++###++++                 +
//    ########## #  #++              ++##### ++++                ++
//    ++## ++  ++  ## #+               ++### #++++               +
//      ########### ## #+            ++++##+++++++                +
//        ##+++  #  #### ++           ++### #+++++++              ++
//          #+####    ##++          +++##+ #####++ +             ++
//           ##### + + ### ++++      ++###  #####++ +            ++
//             ########### #++++    ++###  #####++ +             +
//              +###+ ##### ++ ++ +   +#      +# #++  +            +
//                    ##############  ##       +### ++            ++
//                     ####+++++###+  ##         ## ++           +++
//                     #####+++#####  ##          ##+#            ++
//                     ########+###++  #           ###             +
//                      ###### # ## #  #           ##++            +
//                       ## ## ## ## ## #           # # ##         +
//                       ####  #  ++ # ##           +#  #+         +
//                       ## ++       # ##            #####         ++
//                       ######  #   +###             ####+         +
//                       # ####      ####             #####+         +
//                        +#+ ## +#### ##               ####+++  +     #
//                          ##  #  #######               ###### ###   ##
//                         #    ##  #  ###                 ######+++   ##
//                        #########  #####                 ######+++   #
//                        ## # # ## # # #                   ## # #  
//                         ##  # +  #  ##                    +## + + +
//                        # ###   #     #                     # ### #
//                        #  ###+++     #+                    ## ++  #
//                        ## #####      ##                    ## ## ####
//                        # ######       #                    ## # +  +
//                        # + + +#       #                     # + + + +
//                         # +  ##       #                     # + + + +
//                          #+ ++##     ##                      # # #+ +
//                           #+ + +     +#                      ### # +
//                           # + + +      #                      +# + +
//                           # + +  +     #                       ### ##
//                            # ###++     ##                        ## #
//                              #  #      ##                        ####
//                               # #      #+                         ###
//                                ## #   ###                          ##
//                                 ## #   ##                          ##
//                                  ### ## #
//                                  +##  +##
//                                   ##    #
//                                   +#    #
//                                   +#++   "
//                                    ## +   #
//                                    ##+     ##
//                                    # #     +#
//                                   #+      ###
//                                    +# +    ++#
//                                    ##   +   +#
//                                   ## +     +##
//                                  ###       #+#
//                                 #+         + #
//                               ##           +##
//                               #+ # # # +#    #
//                                ##+ #  # #   ##
//                                 #+##+#  ####+

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Lodge is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public constant MAX_SUPPLY = 8800;
    uint public maxFreeMint = 300;
    uint public price = 0.001 ether;
    bool public isSalesActive = true;
    uint public maxFreeMintPerWallet = 80;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Lodge", "LODGE") {
        _contractUri = "ipfs://QmSmmSfYLccN8ikpkLL1Bqag5r7FoVYEbPGAwzCk7YzRMW";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Lodge sales are not active.");
        require(totalSupply() < maxFreeMint, "There's no more free mints =/");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "Sorry, you already minted a Lodge for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "Lodge sale is not active.");
        require(quantity <= 200, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Lodge are Sold Out! Boom!");
        require(msg.value >= price * quantity, "ETH for sale send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}