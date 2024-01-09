/*                                     @@@@@@@@@@@@@                                 
                                    @@@@@@@@@@@@@@@@@@@                              
                           @@@@@@@@@@@@@           @@@@@@@@@@@@@                     
                       @@@@@@@@@@@@@@@               @@@@@@@@@@@@@@@                 
                     @@@@@@                                     @@@@@@               
                    @@@@@                                         @@@@@              
                   @@@@@                                           @@@@&             
                   @@@@                                            @@@@@             
                   @@@@@          @@@@#             @@@@@          @@@@              
                 @@@@@@@,          @@@@@@         @@@@@@          *@@@@@@@           
               @@@@@*                #@@@@@#   @@@@@@.                %@@@@@         
              @@@@@                     @@@@@@@@@@@                     @@@@@        
              @@@@                        @@@@@@#                        @@@@        
              @@@@                      @@@@@@@@@@@                      @@@@        
              @@@@@                  @@@@@@.   #@@@@@#                  @@@@@        
               @@@@@               @@@@@@         @@@@@@               @@@@@         
                 @@@@@@@          @@@@,             #@@@@          @@@@@@@           
                   @@@@                                            @@@@@             
                   @@@@@                                           @@@@#             
                    @@@@@                                         @@@@@              
                     @@@@@@                                     @@@@@@               
                       @@@@@@@@@@@@@@@               @@@@@@@@@@@@@@%                 
                           @@@@@@@@@@@@@           @@@@@@@@@@@@@                     
                                    @@@@@@@@@@@@@@@@@@@                              
                                       @@@@@@@@@@@@%


██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗  ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗
██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██║  ██║██╔══██╗██║████╗  ██║
██████╔╝██║     ██║   ██║██║     █████╔╝ █████╗  ██║  ██║██║     ███████║███████║██║██╔██╗ ██║
██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██║  ██║██║     ██╔══██║██╔══██║██║██║╚██╗██║
██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██████╔╝╚██████╗██║  ██║██║  ██║██║██║ ╚████║
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
                                                                                              

Silence is true wisdom’s best reply.
—  Euripides

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./base64.sol";
import "./ECDSA.sol";

contract Blockedchain is ERC721, Pausable, Ownable {
    using ECDSA for bytes32; 
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address private signerAddress;

    struct Blocker {
        string handle;
        string asset;
        string image;
        string name;
        bool exists;
        uint id;
        uint numBlocks;
        mapping (uint => Block) blocks;
    }

    struct Block {
        bool exists;
        uint tokenId;
        uint blockNum;
        string timeString;
    }

    struct Token {
        uint blockerId;
        uint blockeeId;
    }

    struct NewBlocker {
        string handle;
        string asset;
        string image;
        string name;
        uint id;
    }

    mapping (uint => Blocker) blockers;
    mapping (uint => Token) tokens;

    constructor() ERC721("Blockedchain", "BLOK") {
    }

    function setSigner(address newSigner) public onlyOwner{
        signerAddress = newSigner;
    }

    function addBlockers(NewBlocker[] memory newBlockers) public onlyOwner{
        for(uint i=0; i<newBlockers.length; i++){
            Blocker storage blocker = blockers[newBlockers[i].id];
            blocker.handle = newBlockers[i].handle;
            blocker.asset = newBlockers[i].asset;
            blocker.image = newBlockers[i].image;
            blocker.name = newBlockers[i].name;
            if(!blocker.exists){
                blocker.exists = true;
                blocker.numBlocks = 0;
            }
            
        }
    }

    function pauseBlocker(uint256 id) public onlyOwner {
        blockers[id].exists = false;
    }

    function unpauseBlocker(uint256 id) public onlyOwner {
        blockers[id].exists = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        uint blockeeId,
        uint blockerId,
        uint deadline,
        string memory timeString,
        bytes memory signature
    ) public whenNotPaused {
        // Check signature is valid
        require(verifyMessage(blockeeId, blockerId, deadline, timeString, signature), 'INVALID_SIG');
        // Check deadline hasn't passed
        require(deadline >= block.timestamp, 'DEADLINE_PASSED');
        // Check that this is an approved blocker
        require(blockers[blockerId].exists, 'NO_BLOCKER');
        // Check this blockeeId hasn't already registered this blockerId
        require(!blockers[blockerId].blocks[blockeeId].exists, 'BLOCK_EXISTS');
        blockers[blockerId].numBlocks += 1;
        // Add this instance to the blockers struct
        // Save the blockeesId so there can't be duplicate mints of the same block
        blockers[blockerId].blocks[blockeeId] = Block({
            tokenId : _tokenIdCounter.current(),
            exists: true,
            timeString: timeString,
            blockNum: blockers[blockerId].numBlocks
        });
        // Mint token
        tokens[_tokenIdCounter.current()] = Token({
            blockerId: blockerId,
            blockeeId: blockeeId
        });
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

    }

    function verifyMessage(
        uint p1, 
        uint  p2,
        uint p3,
        string memory p4,
        bytes memory signature
        ) public view  returns( bool) {
        // Hash those params!
        bytes32 messagehash =  keccak256(abi.encodePacked(p1, p2, p3, p4));
        // See who's the signer
        address thisSigner = messagehash.toEthSignedMessageHash().recover(signature);
        if (signerAddress==thisSigner) {
            // Checks out!
            return (true);
        } else {
            // Looks bogus.
            return (false);
        }
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    // Look up how many tokens have been minted for a blocker
    function blocksForBlocker(uint256 id) public view returns (uint) {
        return blockers[id].numBlocks;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Token memory t = tokens[tokenId];
        Blocker storage blocker = blockers[t.blockerId];
        string memory timeString = blockers[t.blockerId].blocks[t.blockeeId].timeString;
        uint blockNum = blockers[t.blockerId].blocks[t.blockeeId].blockNum;

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Blockedchain - @', blocker.handle , ' (#', uint2str(blockNum) ,')", "description": "The minter of this token was confirmed to be blocked by ', blocker.name , ' (@', blocker.handle ,') on Twitter. \\n \\n[Block provenance]  \\nTime: ', timeString ,'  \\nBlocked Twitter ID: ', uint2str(t.blockeeId) ,'", "image": "', blocker.image ,'", "animation_url": "', blocker.asset ,'", "attributes": [{"trait_type": "Blocker","value": "@', blocker.handle , '"}]}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}