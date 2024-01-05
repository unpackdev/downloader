// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract CryptoJunks is Ownable, ERC721Enumerable, ERC721Burnable {
    using Counters for Counters.Counter;   
    using Strings for uint256; 
    Counters.Counter private _tokenIdTracker;

    // I got one question for you, and that question is...
    string public constant Q = "Can I say my shit?";
    // I got lots of shit to say ... oooooo
    string public constant P = "I can't fit my hand inside a pringle can"; 
    // 2 radiuses of a pringle can is way too smol
    
    
    // I went to Chipotle, got myself a sofritas burrito. brrrap!
    // I got all these ingredients, but when the guy tried to wrap the burrito
    string public constant S = "Half of the shit spilled out, but he still wrapped it";
    // I was like, dude you should have warned me:
    // "Hey, man. You might be reaching maximum burrito capacity here"
    string public constant U = "Do you think I want a messy burrito? No one wants a messy burrito";
    // I wouldn't have got the lettuce if I knew it wouldn't fit
    // Wouldn't have got the cheese if I knew it wouldn't fit
    // Wouldn't have got the peppers if I knew they wouldn't fit
    // I wouldn't have got, half of it
    string public constant T = "But I'll blow my dad before I eat a burrito with a fork";

    
    // I can pretend my biggest problems are pringle cans & burritos


    // But the truth is:
    string public constant R = "My biggest problem's you";
    // I want to please you; but I want to stay true to myself
    
    // I want to give you the junk that you deserve
    // BUt I want to say what I think, and not care what you think about it
    
    
    string public constant Z = "I don't think that I can handle this right now.";
    // Thank you. Goodnight. I hope you're happy.
    //
    // Love you all.

    constructor() ERC721("CryptoJunks", "JUNK") {
        // brought to you by: ambition.wtf
        // thumbs up, let's do this, leeeeeeroy jenkins
    }

    // frivolous values for pointless things
    uint public constant ARBITRARY_QUANTITY = 10000; // max number of junks | lumberjack → robin hood
    bool public areWeFucking = false; // is the sale turned on? | how do you turn this on 
    uint public constant ARBITRARY_LIMIT = 50; // ERC721 gas limits how much fun we can have


    // mint (almost) any number junks
    function fuck(uint _numFucks) public payable {
        // NOTE: DON'T use totalSupply() because they are BURNABLE
        require(
            areWeFucking == true,
            "TOO EARLY. sale hasn't started."
        );
        require(
            _tokenIdTracker.current() < ARBITRARY_QUANTITY,
            "TOO LATE. all junks have been sold."
        );
        require(
            _tokenIdTracker.current()+_numFucks < ARBITRARY_QUANTITY,
            "TOO MANY. there aren't this many junks left."
        );
        require(
            msg.value >= howMuchBondage(_numFucks),
            "TOO LITTLE. pls send moar eth."
        );

        gasm(_numFucks);
    }

    // internal minting function
    function gasm(uint _numGasms) internal {
        require(
            _numGasms <= ARBITRARY_LIMIT,
            "TOO MANY. ERC721 gas limits how much fun we can have."
        );
        for (uint i = 0; i < _numGasms; i++) {            
            uint newTokenId = _tokenIdTracker.current();
            _safeMint(msg.sender, newTokenId);
            // increment AFTER because starts at 0
            _tokenIdTracker.increment();
        }
    }

    // important numbers for special things
    uint public constant SEXY = 69;
    uint public constant MEME = 420;
    uint public constant MUCH = 1000;

    // calculate the cost for a specific junk
    function howMuchForAHit(uint _hit) public pure returns (uint) {
        // no requires bc I don't care when this func is called

        if (_hit >= ARBITRARY_QUANTITY) {
            // dad used to say "there is no such thing as a free lunch" (WATCH TILL THE END)
            // ಠ_ಠ
            // y am I paying extra Ξ to deploy these comments?
            return 0.00 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY) {
            // 9_931—9_999 (69 → SEXY)
            return 1.44 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY - MEME) {
            // 9_511—9_930 (420 → MEME)
            return 0.89 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*11 - MEME) {
            // 8_821—9_510 (690 → SEXY*10)
            return 0.55 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*12 - MEME - MUCH) {
            // 7_752—8_820 (1069 → MUCH+SEXY)
            return 0.34 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*12 - MEME*2 - MUCH*2) {
            // 6_332—7_751 (1420 → MUCH+MEME)
            return 0.21 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*13 - MEME*2 - MUCH*4) {
            // 4_263—6_331 (2069 → MUCH+MUCH+SEXY)
            return 0.13 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*13 - MEME*3 - MUCH*5) {
            // 2_843—4_262 (1420 → MUCH+MEME)
            return 0.08 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*14 - MEME*3 - MUCH*6) {
            // 1_774—2_842 (1069 → MUCH+SEXY)
            return 0.05 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*24 - MEME*3 - MUCH*6) {
            // 1_084—1_773 (690 → SEXY*10)
            return 0.03 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*24 - MEME*4 - MUCH*6) {
            // 664—1_083 (420 → MEME)
            return 0.02 ether;
        } else if (_hit >= ARBITRARY_QUANTITY - SEXY*25 - MEME*4 - MUCH*6) {
            // 595—663 (69 → SEXY)
            return 0.01 ether;
        } else {
            // 0—594 (595 → CALCULATED QUANTITY)
            // ¯\_(ツ)_/¯
            // my lunch is free now dad!
            return 0.0 ether; 
        }
    }

    // calculate how much the cost for a number of junks, across the bondage curve
    function howMuchBondage(uint _hits) public view returns (uint) {        
        require(
            _tokenIdTracker.current()+_hits < ARBITRARY_QUANTITY,
            "TOO MANY. there aren't this many junks left."
        );

        uint _cost;
        uint _index;

        for (_index; _index < _hits; _index++) {
            uint currTokenId = _tokenIdTracker.current();
            _cost += howMuchForAHit(currTokenId + _index);
        }

        return _cost;
    }

    // lists the junks owned by the address
    function exposeJunk(address _owner) external view returns(uint[] memory) {
        uint junks = balanceOf(_owner);
        if (junks == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](junks);
            for (uint i = 0; i < junks; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    /*
     * just dev things
     */
    
    // metadata URI
    string private _baseTokenURI;
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {   
        string memory base = _baseURI();
        string memory _tokenURI = Strings.toString(_tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(base, _tokenURI));
    }
    
    // contract metadata URI for opensea
    string public contractURI;


    /*
     * just owner things
     */

    // stop/start sale
    function ohShitLetsFuckingGo() public onlyOwner {
        areWeFucking = true;
    }
    function ohShitSomethingHappened() public onlyOwner {
        areWeFucking = false;
    }

    // URIs
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // withdrawBalance
    function getPaid() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    // special, reserved for devs
    function wank(uint _numWanks) public onlyOwner {
        require(
            areWeFucking == false,
            "TOO LATE. this should happen first."
        );
        
        // how many we're keeping
        uint maxWanks = ARBITRARY_QUANTITY - SEXY*25 - MEME*4 - MUCH*6; // 595
        uint latestId = _tokenIdTracker.current();

        require(
            latestId < maxWanks,
            "TOO LATE. all the dev mints are minted."
        );

        // limit the number for minting
        uint toWank;
        if (_numWanks < ARBITRARY_LIMIT) {
            toWank = _numWanks;
        } else {
            toWank = ARBITRARY_LIMIT;
        }

        // mint the max number if possible
        if (latestId+toWank < maxWanks) {
            gasm(toWank);
        } else {
            uint wanksLeft = maxWanks - latestId;
            // else mint as many as possible
            gasm(wanksLeft);
        }
    }

    // this seems to be important for something
    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // and this one too seems to be doing something
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // future stuff for onchain stuff

    address public artContractAddress;
    CryptoJunksArt artContract;

    function setArtContract(address _address) external onlyOwner {
        // set the adress
        artContractAddress = _address;
        // set the contract 
        artContract = CryptoJunksArt(_address);
    }

    function getArt(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "OOPS. token does not exist.");

        // really hope I get to this someday
        require(artContractAddress != address(0), "TODO. art contract has not been implemented.");

        return artContract.getArtForJunkId(tokenId);
    }
}

// who knows if this will even work someday?
contract CryptoJunksArt {
    function getArtForJunkId(uint _tokenId) public view returns (string memory) {}
}

// ps. what the fuck is the meaning of stonehenge?