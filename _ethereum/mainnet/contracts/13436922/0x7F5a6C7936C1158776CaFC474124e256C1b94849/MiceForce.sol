// contracts/MiceForce.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IMFMetaVault.sol";
import "./IBrainz.sol";

/* 
  __  __ _          ______                 
 |  \/  (_)        |  ____|                
 | \  / |_  ___ ___| |__ ___  _ __ ___ ___ 
 | |\/| | |/ __/ _ \  __/ _ \| '__/ __/ _ \
 | |  | | | (_|  __/ | | (_) | | | (_|  __/
 |_|  |_|_|\___\___|_|  \___/|_|  \___\___|
                                           
*/

/**
@dev MiceForce contract is the main contract for MF collection
*/
contract MiceForce is ERC721Enumerable {
    //Mappings
    mapping(uint256 => bytes16) internal tokenIdToHash;

    //uint256s
    uint public constant MAX_SUPPLY = 7500;
    //team + giveaway reserve, not possible to mint directly
    uint public constant RESERVED_SUPPLY = 150;
    uint public constant BRAINS_MINT_COST = 12 ether;
    uint public pumpkinMinted;
    uint public brainsMinted;
    uint SEED_NONCE = 0;

    uint public scientistTotal;
    uint public militaryTotal;

    //uint arrays
    uint16[][8] TIERS;

    //bytes32
    bytes32 entropySauce;

    //boolean
    bool public MINT_ENABLED;

    //address
    address constant burnAddress=0x000000000000000000000000000000000D15ea5E;
    address public _owner;
    address metaVaultAddress;
    address pumpkinJackAddress;
    address brainzAddress;

    constructor() ERC721("MiceForce", "MFORCE") {
        _owner = msg.sender;
        // eyes
        TIERS[0]=[0,375,750,1875,2250,2250];
        // hair
        TIERS[1]=[0,375,750,1875,2250,2250];
        // suit
        TIERS[2]=[0,1125,2625,3750];
        // nose
        TIERS[3]=[0,3000,3000,1500];
        // mouth
        TIERS[4]=[0,375,750,1125,1500,1875,1875];
        // whiskers
        TIERS[5]=[0,3750,3750];
        // body
        TIERS[6]=[4,1873,1873,1875,1875];
    }

    /** 
    @dev Generate 16 bytes hash with all trait rolls. Does not guarantee the uniquness of every MiceForce unit.
    @param _milisci MiceForce unit type
    */
    function hash(
        uint8 _milisci,
        uint256 _t,
        address _a
    ) 
        internal 
        returns (bytes16) 
    {
        // hash kept as 16 bytes
        // 1 byte: 0 - military, 1 - scientist
        // 2 byte: 0 - alive, 2 - dead
        // 3-16 bytes: 7 pairs of bytes for trait rolls   
        
        // 0 byte is always 0x00 as MiceForce unit is alive
        bytes16 currentHash=bytes16(0);
        // set 1 byte to MiceForce unit type
        currentHash=setHashByte(currentHash, 1, bytes1(_milisci));
        // generate random uint256
        uint randomUint256 = uint256(
                    keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _t,
                        _a,
                        ++SEED_NONCE,
                        entropySauce
                    )));

        uint16 _randinput;
        // iterating through traits
        for (uint8 i = 0; i < 7; i++) {
            // take 4 digits from random uint256 as roll for trait
            _randinput = uint16((randomUint256 / 10000**i % 10000) % MAX_SUPPLY);
            // write roll to coresponding trait position within the hash 
            currentHash = setTraitRollToHash(currentHash,i,_randinput);
        }

        return currentHash;
    }

    /** 
    @dev Mint tokens for free, usable by giveaway contract only
    @param _winner Address to mint tokens
    @param _amount Amount of tokens to mint
    @param _class Class to mint (0 - mili, 1 - sci, 3 - random)
    */
    function getPrize(address _winner, uint8 _amount, uint8 _class) 
        external 
        onlyPumpkinJack 
    {
        uint256 _startMintId = totalSupply();
        require(
            (_startMintId + _amount) <= MAX_SUPPLY,
            "The amount exceed max supply"
        );

        bool randomize = _class==3;
        pumpkinMinted += _amount;

        for (uint i = 0; i < _amount; i++) {
            uint8 rand = randomize?uint8(uint256(keccak256(abi.encodePacked(_winner, _amount, block.timestamp, block.difficulty, SEED_NONCE++)))%2):_class;
            uint256 _mintId = _startMintId + i;

            tokenIdToHash[_mintId] = hash(rand, _mintId, _winner);
            rand==0?militaryTotal++:scientistTotal++;
            _mint(_winner, _mintId);
        }
        
    }

    /** 
    @dev Mint several tokens in exchange to BRAIN$
    @param _milisci MiceForce unit type (0 - mili, 1 - sci)
    @param _amount Amount to mint
    */
    function mintFew(uint8 _milisci, uint _amount) 
        external 
        noCheaters 
        mintAllowed 
    {
        require(_milisci < 2, "Wrong class chosen");

        require(_amount <= 10, "Max amount per tx exceed");
        uint256 _startMintId = totalSupply();

        require((_startMintId + _amount) <= MAX_SUPPLY, "The amount exceed max supply");
        require(_startMintId + _amount <= MAX_SUPPLY - RESERVED_SUPPLY, "No unreserved mice force available");
        
        IBrainz(brainzAddress).burnFrom(msg.sender, BRAINS_MINT_COST*_amount);
        brainsMinted+=_amount;

        for (uint i = 0; i < _amount; i++) {
            uint256 _mintId = _startMintId + i;
            _milisci==0?militaryTotal++:scientistTotal++;
            tokenIdToHash[_mintId] = hash(_milisci,_mintId, msg.sender);
            _mint(msg.sender, _mintId);
        }
    }

    /** 
    @dev Mint one token in exchange to BRAIN$
    @param _milisci MiceForce unit type (0 - mili, 1 - sci)
    */
    function mintOne(uint8 _milisci) 
        external  
        noCheaters
        mintAllowed
    {
        require(_milisci < 2, "Wrong class chosen");

        uint _mintId = totalSupply();

        require(_mintId < MAX_SUPPLY, "No more mice force available");
        require(brainsMinted < MAX_SUPPLY - RESERVED_SUPPLY, "No unreserved mice force available");

        IBrainz(brainzAddress).burnFrom(msg.sender, BRAINS_MINT_COST);
        brainsMinted++;

        _milisci==0?militaryTotal++:scientistTotal++;
        bytes16 _h=hash(_milisci, _mintId, msg.sender);
        tokenIdToHash[_mintId] = _h;

        _mint(msg.sender, _mintId);
    }

    /**
    @dev Burn the token
    @param _tokenId Token ID
    */
    function burn(uint _tokenId) external {
        _transfer(
            msg.sender,
            burnAddress,
            _tokenId
        );
    }

    /**
    @dev Return all metadata for token ID
    @param _tokenId Token ID
    */
    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        bytes9 packedHash = getPackedHashByTokenId(_tokenId);
        return IMFMetaVault(metaVaultAddress).getMetadataByHash(_tokenId, packedHash);
    }

    /**
    @dev Return the wallet of a given address. Mainly for ease for frontend devs
    @param _wallet The wallet to get the tokens of
    */
    function walletOfOwner(
        address _wallet
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /**
    @dev Get bytes9 hash by tokenID
    @param _tokenId Token ID
    */
    function getPackedHashByTokenId(uint _tokenId) public view returns(bytes9) {
        require(_exists(_tokenId));

        bytes16 _hash=tokenIdToHash[_tokenId];
        bytes1 burned=0x00;
        if (ownerOf(_tokenId) == burnAddress) {
            burned=0x01;
        }

        bytes9 phash=burned;
        phash=setPackedHashByte(phash,1,_hash[1]);

        if (getTraitRollFromHash(_hash, 6)<TIERS[6][0]) {
            return phash;
        }

        for (uint8 i = 0; i < 7; i++) {
            uint16 edge;
            uint16 trait_roll=getTraitRollFromHash(_hash, i);
            for (uint8 j = 0; j < TIERS[i].length; j++) {
                if (trait_roll < (edge+=TIERS[i][j])) 
                {
                    phash=setPackedHashByte(phash,i+2,bytes1(j));
                    break;
                }
            }  
        }
        return(phash);
    }

    /**
    @dev Set addresses
    @param _brainzAddress BRAIN$ contract address
    @param _metavaultAddress MetaBault contract address
    @param _pumpkinJackAddress PumpkinJack contract address
    */
    function setAddress(address _brainzAddress, address _metavaultAddress, address _pumpkinJackAddress) external onlyOwner {
        brainzAddress=_brainzAddress;
        metaVaultAddress=_metavaultAddress;
        pumpkinJackAddress = _pumpkinJackAddress;
    }

    /** 
    @dev Switch the mint phase state from true -> false and vice versa
    */
    function mintSwitch() external onlyOwner {
        MINT_ENABLED=!MINT_ENABLED;
    }

    /** 
    @dev Transfers ownership
    @param _newOwner The new owner
    */
    function transferOwnership(
        address _newOwner
    ) 
        public 
        onlyOwner 
    {
        _owner = _newOwner;
    }

    function getTraitRoll(uint _tokenId, uint8 _traitId) internal view returns(uint16) {
        return getTraitRollFromHash(tokenIdToHash[_tokenId], _traitId);
    }

    //Modifiers

    /**
    @dev Modifier to only allow owner to call function
    */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    /**
    @dev Modifier to only allow PJ contract to call function
    */
    modifier onlyPumpkinJack() {
        require(pumpkinJackAddress == msg.sender);
        _;
    }

    /**
    @dev Modifier to only allow function to be used if MINT_ENABLED
    */
    modifier mintAllowed() {
        require(MINT_ENABLED);
        _;
    }

    /**
    @notice Credits goes to Ether Orcs
    @dev Modifier to not allow contracts call the function
    */
    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin , "No contracts allowed");
        require(size == 0,                "No contracts allowed");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    // Utility functions

    /**
    @dev Get string representation of uint
    */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
    @dev Write trait roll number to bytes16 hash
    */
    function setTraitRollToHash(bytes16 _hash, uint8 _traitId, uint16 roll) internal pure returns (bytes16) {
        return (_hash & ~(bytes16(0xffff0000000000000000000000000000) >> (16+_traitId * 16))) | (bytes16(bytes2(roll)) >> (16+_traitId * 16));
    }

    /**
    @dev Get trait roll number from bytes16 hash
    */
    function getTraitRollFromHash(bytes16 _hash, uint8 _traitId) internal pure returns (uint16) {
        uint16 number;
        uint8 start_pos=2+_traitId*2;
        number = uint16(uint8(_hash[start_pos])*(2**(8)) + uint8(_hash[start_pos+1]));
        return number;
    }

    /**
    @dev Write byte to bytes9 hash
    */
    function setPackedHashByte(bytes9 _hash, uint _index, bytes1 _byte) internal pure returns (bytes9) {
        return (_hash & ~(bytes9(0xff0000000000000000) >> (_index * 8))) | (bytes9(_byte) >> (_index * 8));
    }

    /**
    @dev Write byte to bytes16 hash
    */
    function setHashByte(bytes16 _hash, uint _index, bytes1 _byte) internal pure returns (bytes16) {
        return (_hash & ~(bytes16(0xff000000000000000000000000000000) >> (_index * 8))) | (bytes16(_byte) >> (_index * 8));
    }
}
