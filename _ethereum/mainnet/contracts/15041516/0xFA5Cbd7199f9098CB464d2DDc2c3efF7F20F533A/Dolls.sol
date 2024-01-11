// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./ITraits.sol";

// maps id to status (O = original, 1 = deconstructed, 2 = reconstructed)
enum DOLL_STATUS {
    ORIGINAL,
    DECONSTRUCTED,
    RECONSTRUCTED
}
enum PHASE {
    PREREVEAL,
    REVEAL,
    DECONSTRUCT
}
struct Doll {
    DOLL_STATUS status;
    uint32 version;
    string reconstructedLink;
}

contract Dolls is ERC721, Ownable, Pausable {

    // max supply
    uint16 immutable MAX_SUPPLY;
    uint64 constant PRICE = 1 ether * 1337 / 10000; //  133700000000000000 gwei
    
    bool public presale = true;
    PHASE public phase = PHASE.PREREVEAL;
    uint64 _tokenIds = 0;
    
    address constant ticket_signer = 0xD68a149D5646277cB271E283537b8A9C60D8A32f;
    ITraits public traits_contract;

    mapping(address=>uint16) public mints_per_address;

    mapping(uint256=>Doll) public dolls;

    string public prerevealURI;
    string public revealURIBase;
    string public deconstructionURIBase;

    constructor(string memory _prerevealURI, uint16 maxSupply) ERC721("KLLD Collection", "KLLD") Pausable() {
        prerevealURI = _prerevealURI;
        MAX_SUPPLY = maxSupply;
    }

    function setPrerevealURI(string memory _prerevealURI) external {
        prerevealURI = _prerevealURI;
    }

    function pause() external {
        _pause();
    }

    function unPause() external {
        _unpause();
    }

    //fallback, you never knows if someone wants to tip you ;)
    receive() external payable {
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds;//.current();
    }

    /** 
     * @dev walletofOwner
     * @return tokens id owned by the given address
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function walletOfOwner(address queryAddress) external view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(queryAddress);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        //index starting @ 1
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while ( ownedTokenIndex < ownerTokenCount && currentTokenId <= _tokenIds/*.current()*/ ) {
            if (ownerOf(currentTokenId) == queryAddress) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                unchecked{ ownedTokenIndex++;}
            }
            unchecked{ currentTokenId++;}
        }
        return ownedTokenIds;
    }


    function stopPresale() public onlyOwner {
        presale = false;
    }

    function reveal(string memory _revealURIBase) public onlyOwner {
        phase = PHASE.REVEAL;
        revealURIBase = _revealURIBase;
    }

    function deconstructionPhase(string memory _deconstructionURIBase) public onlyOwner {
        phase = PHASE.DECONSTRUCT;
        deconstructionURIBase = _deconstructionURIBase;
    }

    function setTraitsContract(address contractAddress) public onlyOwner {
        traits_contract = ITraits(contractAddress);
    }

    function presaleMint(uint8 number, bytes calldata encoded, uint8 v, bytes32 r, bytes32 s) public payable whenNotPaused {
        //check signed ticket
        bytes32 hash = keccak256(encoded);
        address signer = ecrecover(hash, v, r, s);
        require (ticket_signer == signer, "wrong signer");
        (uint32 total_allowed, address wallet, bool free) = abi.decode(encoded, (uint32, address, bool));
        //check phase
        require(free || presale, 'presale over');
        //check ticket user 
        //check number of already minted
        require (msg.sender == wallet, "wrong user");
        require (mints_per_address[msg.sender] + number <= total_allowed, "max presale");
        internalMint(number, free);
    }

    function mint(uint8 number) public payable whenNotPaused {
        require(!presale, 'presale phase');
        internalMint(number, false);
    }

    function internalMint(uint8 number, bool free) private {
        require (free || msg.value >= PRICE * number, "min 0.1337 * number");
        require (_tokenIds/*.current()*/ + number <= MAX_SUPPLY, "sold out");

        unchecked {
            mints_per_address[msg.sender] = mints_per_address[msg.sender] + number;
        }

        for (uint i=0; i<number; i++) {
            // index starts at 1 (NOT zero based!!!!)
            unchecked {_tokenIds++;} //.increment();
            _safeMint(msg.sender, _tokenIds);//.current());
           // unchecked {i++;}
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        //check phase & if original, deconstructed or reconstructed
        if (phase==PHASE.PREREVEAL) {
            return prerevealURI;
        } else if (dolls[tokenId].status==DOLL_STATUS.ORIGINAL) {
            return string(abi.encodePacked(revealURIBase, "/", Strings.toString(tokenId)));
        } else if (dolls[tokenId].status==DOLL_STATUS.DECONSTRUCTED) {
            return string(abi.encodePacked(deconstructionURIBase, "/", Strings.toString(tokenId)));
        } else {
            // reconstructed
            return dolls[tokenId].reconstructedLink;
        }

    }

    function drain() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function deconstruct(bytes calldata encoded, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {

        // check phase
        require(phase == PHASE.DECONSTRUCT, "wrong phase");

        // check signature
        bytes32 hash = keccak256(encoded);
        address signer = ecrecover(hash, v, r, s);
        //check traits signer
        require (ticket_signer == signer, "wrong signer");
        (uint256 id, uint256 traits, uint256 version)  = abi.decode(encoded, (uint256, uint256, uint256));

        // check ownership
        require(ownerOf(id)==msg.sender, "not owner");

        // check if not yet deconstructed
        require(dolls[id].status != DOLL_STATUS.DECONSTRUCTED, string(abi.encode("not constructed ", Strings.toString(uint256(dolls[id].status)))));

        // check version
        require(version==dolls[id].version, "wrong version");

        // indicate that it is a deconstructed main nft
        dolls[id].status = DOLL_STATUS.DECONSTRUCTED;
        string memory empty;
        dolls[id].reconstructedLink = empty;

        traits_contract.mintTraits(msg.sender, traits);

    }

    function reconstruct(uint256[] calldata traitTokenIds, bytes calldata encoded, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {

        // check phase
        require(phase == PHASE.DECONSTRUCT, "wrong phase");

        // check signature
        bytes32 hash = keccak256(encoded);
        address signer = ecrecover(hash, v, r, s);
        //check traits signer
        require (ticket_signer == signer, "wrong signer");
        (uint256 signedId, uint256[] memory signedTraitIds, string memory tokenURIPath, uint256 version)  = abi.decode(encoded, (uint256, uint256[], string, uint256));

        // check ownership
        require(ownerOf(signedId)==msg.sender, "not owner");

        // require to be deconstructed
        require(dolls[signedId].status == DOLL_STATUS.DECONSTRUCTED, "not deconstructed");

                // check version
        require(version==(dolls[signedId].version)+1, "wrong version");

        // indicate that it is a reconstructed main nft
        dolls[signedId].status = DOLL_STATUS.RECONSTRUCTED;
        //set version
        dolls[signedId].version = dolls[signedId].version + 1;
        // set the path
        dolls[signedId].reconstructedLink = tokenURIPath;

        traits_contract.burnTraits(msg.sender, traitTokenIds, signedTraitIds);

    }

}