// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
/*  Keep Calm and Stay Trollin                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                          ###       
                                ###################################                  ######.##      
         #####.              ######       #################       ######        #####      ###      
         ###########      ####     ##             .########.   .##      ###.##.            ##       
         #####  ######## ##  .##      ##           #            ##             .###.    # ###       
          #### ####    #       ####              #.                          #          # ##        
           #### ######                          #      #                      ######  . ####        
            #####                              ##              .#                  ##  ####         
            ## .##                              #                 .#               #. ####          
             #.                                    ################                #   ##           
             .#         .###        ##           ##       ##    o#####       ######   ###           
            ######.##     ## ## #####        #  .     o############  #    #.  # # ##. .#            
           ## ##   . .     #######               #o#####          #.             . ##  #            
          ## ##                                                                    ##  #.           
         ##  ##                      #              ###                            ##  ##           
        ##                      .###                ######                             ##           
        ##                  ######     .  ######.      ##                              ##           
        ##                #      ###     ####    #.#####                               ##           
        .##                        ########      ####                                  ##           
         ###              ##                            ####                          ##o           
          ###              ###                       #######                          ##            
           ###               ##        ###        ########                            ##            
            #####             ###    ### ##    #########                             ###            
               o###            #######oo.#############                       #.    ###.             
                 ###           ##ooooooooooooo######                    ####      ####              
                  ##          #ooooooooooooo######              ####     #.    #####.               
                  ###        ##oooo##oooooo#.#             .##    .#####    #####.                  
                  ###        ##ooo##ooooooo#            # ######        .#####.                     
                   ##        ##ooo#.oooooo##         ######################                         
                   ###       ##ooo#oooooooo#     #####################                              
                    ####     #oooooooooooo##########                                                
                     ########oo.#ooooooooo#####o                                                    
                      o####.oooooooooooo##o                                                         
                    o#o.oooooooooooo###                                                             
                      #############                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract TrollinTown is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    uint public startingBlock;
    uint public trollPool;

    mapping(uint256 => string) public nameTag;
    mapping(address => uint256) public greedyLimiter;
    uint256 public howGreedy = 1;

    constructor(string memory _initialBaseURI, uint _initialStartBlock, uint _initialPool) ERC721("TrollinTown", "TROLL") {
        baseURI = _initialBaseURI;
        startingBlock = _initialStartBlock;
        trollPool = _initialPool;
    }

    function trollTownAddress(string memory _newURI)
        public
        onlyOwner
    {
        baseURI = _newURI;
    }

    function iAmBeingGenerous(uint256 _newLimit)
        public
        onlyOwner
    {
        howGreedy = _newLimit;
    }

    function itsTrollinTime(uint newStartBlock)
        public
        onlyOwner
    {
        startingBlock = newStartBlock;
    }

    function trollinPool(uint newPool)
        public
        onlyOwner
    {
        trollPool = newPool;
    }

    function feedTrollAName(uint256 _tokenId, string memory _newName)
        public
    {
        require(_exists(_tokenId), "ERC721: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "TrollTown: Only token owner can change name");
        nameTag[_tokenId] = _newName;
    }

    function trollsOnTheHill()
        public
        view
        returns(uint256)
    {
        return _tokenIdCounter.current();
    }

    function _forgingTroll(address _to, string memory _trollName)
        internal
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId);
        nameTag[newItemId] = _trollName;
        return newItemId;
    }

    function giveMeOneTroll(address _to, string memory _trollName)
        public
        returns (uint256)
    {
        require(block.number > startingBlock, "TrollTown: Trolls are not in the mood to reproduce");
        require(trollsOnTheHill() < trollPool, "TrollTown: We are on troll shortage now");
        require(greedyLimiter[_to] < howGreedy, "TrollTown: You fucking greedy troll maniac");
        uint256 newItemId = _forgingTroll(_to, _trollName);
        greedyLimiter[_to] += 1;
        return newItemId;
    }

    function releaseTheTrolls(address _to, string memory _trollName, uint trollCount)
        public
        onlyOwner
    {
        for(uint i = 0; i < trollCount; i++) {
            _forgingTroll(_to, _trollName);
        }
    }

    function burnInHell(uint256 _tokenId)
        public
        onlyOwner
    {
        _burn(_tokenId);
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }
}