// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ERC2981Base.sol";

struct generation {
    uint256 generaton;
    string uri;
    uint256 amount;
    uint256 startID;
    uint256 endID;
}

contract NanoPortrait is ERC721, ERC2981Base, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter public totalSupply;
    Counters.Counter public GenerationID;
    mapping(uint256 => generation) public Generation;

    // Royalties fee 10%
    uint public constant Royalties = 1000;  

    // Collect Fee addresses
    address constant treasureAddress = 0x8085647A0770cCdF414976fB3B6EA168A5C8169a;
    
    // Base NFT url
    string public constant contractURI = "https://gateway.pinata.cloud/ipfs/QmXPds2zE5JkDmKCMtKSSR3sBXfAy1PX3aeV8DqZUo2hEc";
    
    constructor() ERC721("Nano Portrait", "NANO") {
        _safeMint(treasureAddress, 0);
        totalSupply.increment();        
        Generation[0] = generation ({
            generaton: 0,
            uri: editionUDI,
            amount: 1,
            startID: 0,
            endID: 0
        });
    }

    // nft base URI
    string private editionUDI = "ipfs://QmPacd4dZN4VG4kca4nXBidHtt8yH2HNSrmPhfF4iuML22";  
    function _baseURI() internal view override returns (string memory) {
        return editionUDI;
    }

    function newGeneration(uint amount, string memory _generationURI) public onlyOwner {
        require(amount > 0, "bunchMint: amount can't be 0 value");
        editionUDI = _generationURI;
        uint Id;
        uint StartID = totalSupply.current();        
        while ( Id < amount ) {
            _safeMint(treasureAddress, totalSupply.current());
            totalSupply.increment();
            Id++;
        }
        GenerationID.increment();
        uint256 _generationID = GenerationID.current();
        Generation[_generationID] = generation ({
            generaton: _generationID,
            uri: _generationURI,
            amount: amount,
            startID: StartID,
            endID: totalSupply.current() - 1
        });
    }

    // Royalties IERC2981 setup interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // IERC2981 Royalties base function
    function royaltyInfo(uint256, uint256 value)
        external
        pure
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = treasureAddress;
        royaltyAmount = (value * Royalties) / 10000;
    }

}