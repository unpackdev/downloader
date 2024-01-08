// contracts/Project79.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ByteUtils.sol";

interface IMetaVault {
    function getMetadataByHash(uint _id, bytes9 _packedHash, string calldata name, uint eaten) external view returns (string memory);
}

interface IMiceForce {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getPackedHashByTokenId(uint _tokenId) external view returns(bytes9);
    function transferFrom(address from,address to,uint256 tokenId) external;
    function burn(uint tokenId) external;
}

interface IBrainz {
    function burnFrom(address account, uint256 amount) external;
    function stakeByIds(uint256[] calldata tokenIds) external;
    function claimByTokenId(uint256 tokenId) external;
    function getRewardsByTokenId(uint256 tokenId) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IZombieMice { 
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function balanceOf(address owner) external view returns (uint256);
}
interface IPumpkinJack {
    function brainsSacrificed() external view returns(uint256);
}

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
contract Project79 is ERC721Enumerable {
    //Mappings
    mapping(uint256 => bytes16) internal tokenIdToHash;
    mapping(uint256 => bytes9) internal idToFrozenHash;
    mapping(uint => string) internal idtoName;
    mapping(uint => uint[]) internal idToEaten;

    //uint256s
    uint public constant MAX_SUPPLY = 2750;
    uint SEED_NONCE = 0;
    uint public BRAINS_SACRIFICED_DIVIDER = 15;
    uint public BRAINS_NAMING_COST = 30;

    //uint arrays
    uint[][8] TIERS;

    //boolean
    bool public MINT_ENABLED;

    //address
    address public owner;

    IMetaVault metavaultContract;
    IMiceForce miceForceContract;
    IBrainz brainsContract;
    IPumpkinJack pumpkingJackContract;
    IZombieMice zmiceContract;

    constructor() ERC721("Project79", "Project79") {
        owner = msg.sender;
        // eyes
        TIERS[0]=[0, 0, 1500,2000,2500,4000];
        // hair
        TIERS[1]=[0, 0, 1500,2000,2500,4000];
        // suit
        TIERS[2]=[1500, 3500, 5000];
        // nose
        TIERS[3]=[1500, 3500, 5000];
        // mouth
        TIERS[4]=[0, 0, 1500, 3500, 5000];
        // whiskers
        TIERS[5]=[1000,2000,3000,4000];
        // body
        TIERS[6]=[5000,5000];

    }

    function hash(
        uint8 hellamutant,
        uint256 _t,
        address _a
    ) 
        internal 
        returns (bytes16) 
    {
        bytes16 currentHash=bytes16(0);
        currentHash=ByteUtils.setHashByte(currentHash, 1, bytes1(hellamutant));
        uint randomUint256 = uint256(
                    keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        block.timestamp,
                        _t,
                        _a,
                        ++SEED_NONCE
                    )));
        uint16 _randinput;
        for (uint8 i = 0; i < 7; i++) {
            _randinput = uint16((randomUint256 / 10000**i % 10000) % 10000);
            currentHash = ByteUtils.setTraitRollToHash(currentHash,i,_randinput);
        }
        return currentHash;
    }

    function mint(uint[] calldata miceForceIds) external mintAllowed {
        uint _mintId = totalSupply();

        require(_mintId < MAX_SUPPLY, "No more mice force available");
        require(zmiceContract.balanceOf(msg.sender) > 0, "You don't own the Zombiemice");

        uint count=miceForceIds.length;
        require (count==2,"2 of miceForce should be burned.");

        uint8[2] memory milisci;
        for (uint i;i<2;i++) {
            bytes9 phash = miceForceContract.getPackedHashByTokenId(miceForceIds[i]);
            milisci[i] = uint8(phash[1]);
        }
        // don't really need complex random here
        uint8 tomint = milisci[0]^milisci[1]==0?milisci[0]:uint8(SEED_NONCE%2);
        bytes16 _h=hash(tomint, _mintId, msg.sender);

        tokenIdToHash[_mintId] = _h;

        for (uint i;i<count;i++) { 
            miceForceContract.transferFrom(msg.sender, address(this),miceForceIds[i]);
            miceForceContract.burn(miceForceIds[i]);
        }
        _mint(msg.sender, _mintId);
    }

    function giveName(uint tokenId, string calldata _name) external {
        require(msg.sender==ownerOf(tokenId), "You're not the owner");
        require(onlyAllowedCharacters(_name), "Some characters not allowed");

        idtoName[tokenId]=_name;
        brainsContract.burnFrom(msg.sender, BRAINS_NAMING_COST);
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
        return metavaultContract.getMetadataByHash(_tokenId, packedHash,idtoName[_tokenId],idToEaten[_tokenId].length);
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

    function getPackedHashByTokenId(uint _tokenId) public view returns(bytes9) {
        require(_exists(_tokenId));

        // If token was frozen - just get the phash from the contract
        if (idToFrozenHash[_tokenId]!=bytes9(0)) {
            return idToFrozenHash[_tokenId];
        }

        bytes16 _hash=tokenIdToHash[_tokenId];

        bytes9 phash=0x00;
        phash=ByteUtils.setPackedHashByte(phash,1,_hash[1]);
        uint pjSacrificed=pumpkingJackContract.brainsSacrificed();

        for (uint8 i = 0; i < 7; i++) {
            uint edge;
            uint[] memory adjusted=TIERS[i];
            adjusted = calculateAdjusted(pjSacrificed, TIERS[i]);

            uint16 trait_roll=ByteUtils.getTraitRollFromHash(_hash, i);
            for (uint8 j = 0; j < adjusted.length; j++) {
                if (trait_roll < (edge+=adjusted[j])) 
                {
                    phash=ByteUtils.setPackedHashByte(phash,i+2,bytes1(j));
                    break;
                }
            }  
        }
        return(phash);
    }

    function freeze(uint tokenId) external {
        require(msg.sender==ownerOf(tokenId), "You are not the owner");
        require(idToFrozenHash[tokenId]==bytes9(0), "Already frozen");

        idToFrozenHash[tokenId]=ByteUtils.setPackedHashByte(getPackedHashByTokenId(tokenId), 0, 0x01);
    }

    function calculateAdjusted(uint pjBrains, uint[] storage traitsSlice) internal view returns(uint[] memory) {
        uint len = traitsSlice.length;

        // Only some traits adjustable
        if (len <= 4) {
            return traitsSlice;
        }

        uint[] memory adjusted = new uint[](len);
        uint pjBrainsAdjustment=pjBrains/(10**18)/BRAINS_SACRIFICED_DIVIDER;
        // total must be 10000 to avoid errors
        uint total;
        for (uint i;i<2;i++) {
            adjusted[i]=traitsSlice[i]+(i+1)*pjBrainsAdjustment;
            total+=adjusted[i];
        }
        
        uint negativeAdj=pjBrainsAdjustment*3/((len-1)*(len-2)/2);

        for (uint i=2;i<len;i++) {
            // avoid underflow
            if (negativeAdj*(i-1)<=traitsSlice[i]) 
            {
                adjusted[i]=traitsSlice[i]-negativeAdj*(i-1); 
            }
            total+=adjusted[i];
        }
        if (total < 10000) { total+=10000-total; }
        return adjusted;
    }

    function setAddress(
        address _metavaultAddress, 
        address _zombiemiceAddress, 
        address _brainsAddress, 
        address _miceForceAddress,
        address _pumpkinJackAddress
    ) external onlyOwner {
        metavaultContract=IMetaVault(_metavaultAddress);
        zmiceContract=IZombieMice(_zombiemiceAddress);
        brainsContract=IBrainz(_brainsAddress);
        miceForceContract=IMiceForce(_miceForceAddress);
        pumpkingJackContract=IPumpkinJack(_pumpkinJackAddress);

        // Required to eat zombies
        zmiceContract.setApprovalForAll(address(brainsContract), true);
    }

    function eatZombies(uint projectId, uint[] calldata zombiesId) external {
        require(ownerOf(projectId)==msg.sender);
        for (uint i;i<zombiesId.length;i++)
        {
            require(zmiceContract.ownerOf(zombiesId[i])==msg.sender);
            idToEaten[projectId].push(zombiesId[i]);
            zmiceContract.transferFrom(msg.sender, address(this), zombiesId[i]);
        }
        brainsContract.stakeByIds(zombiesId);
    }

    function claimBrainsForId(uint tokenId) external {
        require(ownerOf(tokenId)==msg.sender);
        for (uint i;i<idToEaten[tokenId].length;i++) {
            uint brainsReward = brainsContract.getRewardsByTokenId(idToEaten[tokenId][i]);
            brainsContract.claimByTokenId(idToEaten[tokenId][i]);
            brainsContract.transfer(msg.sender, brainsReward);
        }
    }

    function claimableBrains(uint tokenId) external view returns (uint){
        uint total;
        for (uint i;i<idToEaten[tokenId].length;i++) {
            total+=brainsContract.getRewardsByTokenId(idToEaten[tokenId][i]);
        }
        return total;
    }

    function mintSwitch() external onlyOwner {
        MINT_ENABLED=!MINT_ENABLED;
    }

    function onlyAllowedCharacters(string calldata string_) internal pure returns (bool) {
        bytes memory _strBytes = bytes(string_);
        uint _strLen = _strBytes.length;
        for (uint i = 0; i < _strLen; i++) {
            bytes1 _letterBytes1 = _strBytes[i];
            bytes1 _bottomBytes;
            
            _bottomBytes = 0x21;
            
            if (_letterBytes1 < _bottomBytes || _letterBytes1 > 0x7A || _letterBytes1 == 0x26 || _letterBytes1 == 0x22 || _letterBytes1 == 0x3C || _letterBytes1 == 0x3E) {
                    return false;
            }     
        }
        return true;
    }

    function getTraitRoll(uint _tokenId, uint8 _traitId) internal view returns(uint16) {
        return ByteUtils.getTraitRollFromHash(tokenIdToHash[_tokenId], _traitId);
    }

    function setMultipliers(uint _bsd, uint _bnc) external onlyOwner {
        BRAINS_NAMING_COST=_bnc;
        BRAINS_SACRIFICED_DIVIDER=_bsd;
    }
/*
    function getName(uint tokenId) external view returns(string memory) {
        return idtoName[tokenId];
    }*/

    function isZombieEater(uint tokenId) external view returns(bool) {
        return idToEaten[tokenId].length > 0;
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender);
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
    }
}
