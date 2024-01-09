// Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//       o@@@@@@@@@@@@@@@@@@@@@@@o   .@@@@@@@@@@@@@@@@@@@@@   o@@@@@@@@@@@@@@@@@@@@@°       //
//       O@@@@@@@@@@@@@@@@@@@@@@@O   .@@@@@@@@@@@@@@@@@@@@@   O@@@@@@@@@@@@@@@@@@@@@*       //
//       O@@@@@@@@@@@@@@@@@@@@@@@O   .@@@@@@@@@@@@@@@@@@@@@   O@@@@@@@@@@@@@@@@@@@@@*       //
//       *OOOOOOO@@@@@@@@@OOOOOOO*    OOOOOOOOOOOOO@@@@@@@@   *OOOOOOO#@@@@@@@@@@@@@°       //
//       .°....°.o@@@@@@@o.°....°.    .....°°°°°°°.@@@@@@@@   .°...°O@@@@@@@@@@@@O*°        //
//               *@@@@@@@o        *@@@@@@@o        @@@@@@@@      *#@@@@@@@@@@@O*°..         //
//               *@@@@@@@o        *@@@@@@@@O*...*o@@@@@@@@@   .O@@@@@@@@@@@@#o**°°°°.       //
//               *@@@@@@@o        .@@@@@@@@@@@@@@@@@@@@@@@o   #@@@@@@@@@@@@@@@@@@@@@*       //
//               *@@@@@@@o         *#@@@@@@@@@@@@@@@@@@@@o.   O@@@@@@@@@@@@@@@@@@@@@*       //
//               *@@@@@@@*         .°*O#@@@@@@@@@@@@@@Oo°.    O@@@@@@@@@@@@@@@@@@@@@*       //
//               .*******.           ..°°***oooooo**°°°..     °*********************.       //
//                .......               .............         ......................        //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////

contract TeejeezNFT is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    /*  Counter instead of ERC721Enumerable to reduce gas price
    /   See -> https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
    /   Thx to them
    */
    Counters.Counter private _nextMintId;
    
    // Mint settings
    uint256 public constant MAX_PURCHASE_PER_TX = 10;
    uint256 public constant MAX_PURCHASE_PER_ADDRESS = 20;
    uint256 public constant TJZ_PRICE = 25000000000000000; //WEI, 25000000 GWEI, 25 FINNEY, 0.025 ETH
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant LAUNCH_TIMESTAMP = 1642283999;
    uint256 public constant RESERVED_AMOUNT = 50;

    // URI / Provenance / Index
    string private _baseTokenURI;
    string private _extensionURI;
    string public secretURI = "https://teejeez.world/secret.json";
    string public provenance;
    uint256 private _creationTimestamp;
    uint256 public offsetIndex;

    // Reserved TJZs claim status: 0=not claimed, 1=claimed
    uint256 public isReservedClaimed;

    // Minting state: 0=paused, 1=open
    uint256 public isMintingLive;

    // Metadata Reveal State: 0=hidden, 1=revealed
    uint256 public isReveal;

    // Dev wallet for giveaway
    address dev1 = 0x1823FdDd74B439144B5b04B87f1cCc115F121F3a; // Ketso
    address dev2 = 0x28c626ba7c66aB68eCBcacF96A0EfE42a0C695D9; // InMot
    address dev3 = 0x441d39885E223c82262922Adb5960e07Bb90890B; // Strearate
    address dev4 = 0xCecC5B6f51960Cdb556eC6723AC49DDbB2aFceb7; // Torkor

    ////////////////////////////////////////////////

    constructor() ERC721("TeejeezNFT", "TJZ") {
        _nextMintId.increment();
        _creationTimestamp = block.timestamp;
    }

    // Mint reserved for the team, family,friends and giveaway (basically first #50)
    function mintReserved () external onlyOwner {
        require(isReservedClaimed == 0, "Reserved Teejeez have already been claimed");
        isReservedClaimed = 1;

        for(uint i = 0; i < RESERVED_AMOUNT; i++) {
            uint mintIndex = _nextMintId.current();
            address currentAddress = dev1;

            if (mintIndex > 8 && mintIndex <= 16) {
                currentAddress = dev2;
            }
            if (mintIndex > 16 && mintIndex <= 20) {
                currentAddress = dev3;
            }
            if (mintIndex > 20 && mintIndex <= 24) {
                currentAddress = dev4;
            }
            if (_nextMintId.current() <= MAX_SUPPLY) {
                _nextMintId.increment();
                _safeMint(currentAddress, mintIndex);
            }
        }
    }

    /*
    * --- MINTING
    */

    function mintTJZ(uint256 tokenAmount) public payable {
        require(block.timestamp >= LAUNCH_TIMESTAMP, "Mint isn't open yet : Opening 01/15/2022, 11:00PM CET");
        require(isMintingLive == 1, "Minting must be active to mint a Teejeez");
        require(tokenAmount <= MAX_PURCHASE_PER_TX, "You can only mint 10 Teejeez at a time");
        require(balanceOf(msg.sender).add(tokenAmount) <= MAX_PURCHASE_PER_ADDRESS, "You can only mint a maximum of 20 Teejeez per wallet");
        require(_nextMintId.current().add(tokenAmount) <= MAX_SUPPLY.add(1), "The mint would exceed Teejeez max supply");
        require(TJZ_PRICE.mul(tokenAmount) <= msg.value, "Ether value sent is uncorrect");
        
        for(uint i = 0; i < tokenAmount; i++) {
            uint mintIndex = _nextMintId.current();
            if (_nextMintId.current() <= MAX_SUPPLY) {
                _nextMintId.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /*
    * --- TOKEN URI
    */
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setExtension(string memory newExtension) external onlyOwner {
        _extensionURI = newExtension;
    }

    function setSecretURI(string memory newSecretURI) external onlyOwner {
        secretURI = newSecretURI;
    }

    // Raspberries are perched on my grandfather's stool
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "URI query for non-existent token");

        string memory baseURI = _baseURI();

        if (isReveal == 0) {
            return secretURI;
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString(), _extensionURI));
        }
    }

    function setOffsetIndex() external {
        bytes memory tempProvenanceBytes = bytes(provenance);
        require(offsetIndex == 0, "Offset index has already been set");
        require(tempProvenanceBytes.length != 0, "The provenance hash must be set prior to the offset index");

        offsetIndex = uint(_creationTimestamp + block.timestamp) % MAX_SUPPLY;

        // Prevent default sequence
        if (offsetIndex == 0) {
            offsetIndex = 1;
        }
    }

    /*
    * --- UTILITIES
    */
    // And so, it begins...
    function toggleMintingState() external onlyOwner {
        isMintingLive == 0 ? isMintingLive = 1 : isMintingLive = 0;
    }
    
    function toggleRevealState() external onlyOwner {
        isReveal == 0 ? isReveal = 1 : isReveal = 0;
    }

    function setProvenance(string memory provenanceHash) external onlyOwner {
        provenance = provenanceHash;
    }

    function totalSupply() public view returns(uint256) {
        return _nextMintId.current() - 1;
    }

    // Funds are safe
    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}