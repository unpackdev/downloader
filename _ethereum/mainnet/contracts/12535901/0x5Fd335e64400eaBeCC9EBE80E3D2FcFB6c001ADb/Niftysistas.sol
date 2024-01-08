// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Niftysistas is ERC721, Ownable, Pausable {

    event NameUpdated(uint256 indexed sistaID, string previousName, string newName);
    event SistaUpdated(uint256 indexed sistaid, uint newTraits);

    using Counters for Counters.Counter;
    using SafeMath for uint;

    string constant arweaveImgHash = "WSWyugwPLdKdAVdjtNeHwolQ-6ZYZMBSp4PGF7u74NI";
    string constant ipfsImgHash = "QmbHNixULPacHpwK5FugNYoeCg9YeKxJvnCyjYGXDxwGqW";

    string arweaveGeneratorHash = "k204IFXhzLwEcJ0xFsQVhSCEiLZL8qzqPIRP4sqtxDc";
    string ipfsGeneratorHash = "QmfAmCbvmPMispUK1xiS44r1Mjo1i8695rVKZ8b83Qp3Su";

    uint constant maxSupply = 1024;   

    uint constant emptyTrait = 999;   

    uint traitCost = 30000000000000000;
    uint baseCost = 240000000000000000;

    uint freeTraits = 13;
    uint freeTraitsHolder = 20;

    mapping (string => bool) private nameAssigned;
    mapping (uint => bool) private removedTraitsMap;
    mapping (uint => uint) private tokenTraits;
    mapping (uint => bool) private existMap;
    mapping (uint => string) private sistaNames;
    mapping (address => bool) private isWhitelisted;

    uint[] private removedTraits;

    // skin, mouth, eye, shoes, hair, hats, leftHand, rightHand, bodytraits, dresslower, dresstop, face, accessories
    uint[] private lowerBounds = [885, 866, 828, 651, 306, 184, 142, 100, 789, 684, 499, 448, 247];
    uint[] private upperBounds = [903, 884, 865, 683, 447, 246, 183, 141, 827, 788, 650, 498, 305];

    Counters.Counter private sistaCounter;

    uint skillBase;
    uint skillActivationBlock;

    NiftysistasTraitsContract public traitsContract;
    NiftydudesContract public dudesContract = NiftydudesContract(0x892555E75350E11f2058d086C72b9C94C9493d72);

    uint256 public sale_start_timestamp = 1622487570;

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _setBaseURI("https://niftysistas.com/metadata/");          
    }

    function purchase(uint[] memory singleTraits, uint[] memory bodyTraits, uint[] memory dresstop, uint[] memory dressbottom, uint[] memory accessoires, uint[] memory face) external payable {
        
        require((!paused() && block.timestamp >= sale_start_timestamp) || msg.sender == owner() || isWhitelisted[msg.sender], "Purchases are paused.");
        require(singleTraits.length == 8);

        uint numberOfTraits = bodyTraits.length.add(dresstop.length).add(dressbottom.length).add(accessoires.length).add(face.length).add(1);

        require(singleTraits[0] >= lowerBounds[0] && singleTraits[0] <= upperBounds[0] && !removedTraitsMap[singleTraits[0]], "At least one of the provided traits does not exist");
        for(uint i=1;i<8;i++) {
            require((singleTraits[i] == emptyTrait || singleTraits[i] >= lowerBounds[i] && singleTraits[i] <= upperBounds[i]) && !removedTraitsMap[singleTraits[i]], "At least one of the provided traits does not exist");
            if(singleTraits[i]!=emptyTrait) numberOfTraits++;

        }

        uint traitsToBill = 0;
        uint dudeBal = dudesContract.balanceOf(msg.sender);

        if(numberOfTraits > freeTraits && dudeBal < 1) {
            traitsToBill = numberOfTraits.sub(freeTraits);
        } else if(numberOfTraits > freeTraitsHolder && dudeBal >= 1) {
            traitsToBill = numberOfTraits.sub(freeTraitsHolder);
        }

        require((msg.value == baseCost + (traitsToBill * traitCost) || msg.sender == owner() || isWhitelisted[msg.sender]), "ether amount incorrect");
        require(numberOfTraits <= 25, "must not provide more than 25 traits");
        require(sistaCounter.current() < maxSupply, "all sistas have been minted");

        uint traitCombination = lowLayerSingleCombi(singleTraits[0], singleTraits[1], singleTraits[2]);
        traitCombination = getMultiLayerCombi(traitCombination, bodyTraits, dressbottom, singleTraits[3], face, dresstop);
        traitCombination = upperLayerSingleCombi(traitCombination, singleTraits[5], singleTraits[4], singleTraits[6], singleTraits[7], accessoires);

        storeNewSista(traitCombination);
    }

    function storeNewSista(uint traitCombi) private {
        require(!existMap[traitCombi], "sista not unique");
        existMap[traitCombi] = true;

        sistaCounter.increment();
        uint256 newSistaId = sistaCounter.current();

        tokenTraits[newSistaId] = traitCombi;

        if(newSistaId > 40) {
            uint traitToRemove = (rngTrait(1, newSistaId) % (lowerBounds[0]-100)) + 100;
            if(!removedTraitsMap[traitToRemove]) {
                removedTraits.push(traitToRemove); 
            }
            removedTraitsMap[traitToRemove] = true;
        }

        _safeMint(msg.sender, newSistaId);

        if (skillActivationBlock == 0 && newSistaId == maxSupply) {
            skillActivationBlock = block.number+2;
        }
    }

    function lowLayerSingleCombi(uint skin, uint mouth, uint eye) private pure returns (uint256) {
        uint result = skin;

        if(mouth != emptyTrait) { result = result.mul(1000).add(mouth); }        
        if(eye != emptyTrait) { result = result.mul(1000).add(eye); }        

        return result;
    }

    function getMultiLayerCombi(uint base, uint[] memory bodyTraits, uint[] memory dressbottom, uint shoes, uint[] memory face, uint[] memory dresstop) private view returns (uint256) {
        base = base.mul(10**(bodyTraits.length*3)).add(validateAndCalculate(bodyTraits, lowerBounds[8], upperBounds[8]));
        base = base.mul(10**(dressbottom.length*3)).add(validateAndCalculate(dressbottom,lowerBounds[9], upperBounds[9]));
        if(shoes != emptyTrait) { base = base.mul(1000).add(shoes); }        
        base = base.mul(10**(dresstop.length*3)).add(validateAndCalculate(dresstop,lowerBounds[10], upperBounds[10]));
        base = base.mul(10**(face.length*3)).add(validateAndCalculate(face,lowerBounds[11], upperBounds[11]));

        return base;
    }

    function upperLayerSingleCombi(uint base, uint hat, uint hair, uint leftHand, uint rightHand, uint[] memory accessories) private view returns (uint256) {
        if(hair != emptyTrait) { base = base.mul(1000).add(hair); }
        base = base.mul(10**(accessories.length*3)).add(validateAndCalculate(accessories,lowerBounds[12], upperBounds[12]));
        if(hat != emptyTrait) { base = base.mul(1000).add(hat); }
        if(leftHand != emptyTrait) { base = base.mul(1000).add(leftHand); }
        if(rightHand != emptyTrait) { base = base.mul(1000).add(rightHand); }

        return base;
    }

    function validateAndCalculate(uint[] memory traitCollection, uint lower, uint upper) private view returns (uint256) {
        uint traitCombi = 0;

        for (uint i=0; i < traitCollection.length; i++) {
            require(traitCollection[i] >= lower && traitCollection[i] <= upper, "one of the multi traits does not exist");
            require(!removedTraitsMap[traitCollection[i]], "one of the multi traits is unavailable");
            
            bool unique = true;
            for(uint j=i+1; j<traitCollection.length; j++) {
                if(traitCollection[j] == traitCollection[i]) {
                    unique = false;
                }
            }
            require(unique, "traits can only be applied once");

            traitCombi = traitCombi.mul(1000).add(traitCollection[i]);
        }
        return traitCombi;
    }

    function setSaleStart(uint _sale_start_timestamp) onlyOwner external {
        sale_start_timestamp = _sale_start_timestamp;
    } 

    function withdraw() onlyOwner external {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function whitelist(address addressToWhitelist, bool _whitelist) onlyOwner external {
        isWhitelisted[addressToWhitelist] = _whitelist;
    }

    function changePrice(uint _basePrice, uint _traitPrice, uint _freeTraits, uint _freeTraitsHolder) external onlyOwner {
        baseCost = _basePrice;
        traitCost = _traitPrice;
        freeTraits = _freeTraits;
        freeTraitsHolder = _freeTraitsHolder;
    }

    function setSkillActivationBlock(uint activationBlock) external onlyOwner {
        skillActivationBlock = activationBlock;
    }

    function removeTraits(uint[] calldata traitids) external onlyOwner {
        for (uint i=0; i < traitids.length; i++) {
            removedTraits.push(traitids[i]);
            removedTraitsMap[traitids[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function rngTrait(uint nonce, uint id) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(nonce, id, block.timestamp, block.difficulty, blockhash(block.number-1))));
    }

    function rngSkills(uint nonce, uint id) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(skillBase, nonce, id)));
    }

    function getRemovedTraits() external view returns (uint[] memory) {
        return removedTraits;
    }

    function getTraits(uint256 tokenId) external view returns (uint) {
        require(_exists(tokenId), "nonexistent token");
        return tokenTraits[tokenId];
    }

    function setGeneratorHashes(string memory newArweave, string memory newIpfs) external onlyOwner {
        arweaveGeneratorHash = newArweave;
        ipfsGeneratorHash = newIpfs;
    }

    function getArweaveImgHash() external pure returns (string memory) {
        return arweaveImgHash;
    }

    function getIpfsImgHash() external pure returns (string memory) {
        return ipfsImgHash;
    }

    function getArweaveGeneratorHash() external view returns (string memory) {
        return arweaveGeneratorHash;
    }

    function getIpfsGeneratorHash() external view returns (string memory) {
        return ipfsGeneratorHash;
    }    

    function isUnique(uint traitCombi) external view returns (bool) {
        return !existMap[traitCombi];
    }    

    function shuffle(uint[] memory a, uint id) private view returns (uint[] memory){
        uint j;
        uint x;

        for (uint i = 5; i > 0; i--) {
            j = rngSkills(i, id) % (i + 1);
            x = a[i];
            a[i] = a[j];
            a[j] = x;
        }
        return a;
    }

    function getSkills(uint256 tokenId) external view returns (uint, uint, uint, uint, uint, uint) {
        require(_exists(tokenId), "nonexistent token");

        if(skillBase == 0) {
            return (0,0,0,0,0,0);
        } else {
            uint remainingSkills = 0;

            uint randSistaBase = rngSkills(1, tokenId);

            if(randSistaBase % maxSupply == 512) {
                remainingSkills = (rngSkills(2, tokenId) % 50) + 550;
            } else if(randSistaBase % maxSupply < 8) {
                remainingSkills = (rngSkills(2, tokenId) % 50) + 500;
            } else if((randSistaBase % maxSupply) + 8 < 40) {
                remainingSkills = (rngSkills(2, tokenId) % 100) + 400;
            } else if(randSistaBase % maxSupply > 895) {
                remainingSkills = (rngSkills(2, tokenId) % 100) + 300;
            } else {
                remainingSkills = (rngSkills(2, tokenId) % 100) + 200;
            }
            uint diff=0;
            
            uint[] memory skillArray = new uint[](6);

            for(uint i=0;i<5;i++) {
                if(remainingSkills > 500 - (i*100)) {
                    diff = remainingSkills - (500 - (i*100));
                    skillArray[i] = (rngSkills(i+3, tokenId) % (101-diff)) + diff;
                } else {
                    if(i==0) {
                        skillArray[i] = rngSkills(i+3, tokenId) % 101;
                    } else {
                        skillArray[i] = rngSkills(i+3, tokenId) % (remainingSkills > 100 ? 101 : (remainingSkills + 1));
                    }
                }
                remainingSkills -= skillArray[i];                
            }

            skillArray[5] = remainingSkills;

            skillArray = shuffle(skillArray, tokenId);

            return (skillArray[0], skillArray[1], skillArray[2], skillArray[3], skillArray[4], skillArray[5] );
        }
    }    

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function activateSkills() external {
        require(skillBase == 0, "skill base is set");
        require(skillActivationBlock != 0, "skill activation block not set");
        require(block.number > skillActivationBlock, "block number too low");

        skillBase = uint(blockhash(skillActivationBlock));

        if (block.number.sub(skillActivationBlock) > 255) {
            skillBase = uint(blockhash(block.number-1));
        }
    }

    function getName(uint256 tokenID) external view returns (string memory) {
        require(_exists(tokenID), "nonexistent token");
        return sistaNames[tokenID];
    }

    function updateName(uint256 tokenID, string memory newName) external returns (string memory) {
        require(_exists(tokenID), "nonexistent token");
        require(sha256(bytes(newName)) != sha256(bytes(sistaNames[tokenID])), "new name and old name equal");
        require(_isApprovedOrOwner(_msgSender(), tokenID), "no permission");
        require(isNameAllowed(newName), "name not allowed");
        require(!isNameReserved(newName), "name reserved");

        string memory prevName = sistaNames[tokenID];

        if (bytes(sistaNames[tokenID]).length > 0) {
            toggleAssignName(sistaNames[tokenID], false);
        }
        toggleAssignName(newName, true);

        sistaNames[tokenID] = newName;

        emit NameUpdated(tokenID, prevName, newName);

        return prevName;
    }

    function toggleAssignName(string memory str, bool isReserve) private {
        nameAssigned[toLower(str)] = isReserve;
    }

    function isNameReserved(string memory nameString) public view returns (bool) {
        return nameAssigned[toLower(nameString)];
    }

    function isNameAllowed(string memory newName) public pure returns (bool) {
        bytes memory byteName = bytes(newName);
        if(byteName.length < 1 || byteName.length > 25) return false;
        if(byteName[0] == 0x20 || byteName[byteName.length - 1] == 0x20) return false; // reject leading and trailing space

        bytes1 lastChar = byteName[0];

        for(uint i; i < byteName.length; i++){
            bytes1 currentChar = byteName[i];

            if (currentChar == 0x20 && lastChar == 0x20) return false; // reject double spaces

            if(
                !(currentChar >= 0x30 && currentChar <= 0x39) && //9-0
                !(currentChar >= 0x41 && currentChar <= 0x5A) && //A-Z
                !(currentChar >= 0x61 && currentChar <= 0x7A) && //a-z
                !(currentChar == 0x20) //space
            )
                return false;

            lastChar = currentChar;
        }

        return true;
    }

    function toLower(string memory str) private pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function detachTrait(uint sistaid, uint[] memory traitsToDetach, bool burn) external {
        require(!paused(), "contract paused");

        uint traitCombi = tokenTraits[sistaid];
        for (uint i=0; i < traitsToDetach.length; i++) {
            require(_isApprovedOrOwner(_msgSender(), sistaid), "no permission");
            require(containsTrait(traitCombi, traitsToDetach[i]), "trait not found");

            uint result = removeTraitFromCombi(traitCombi, traitsToDetach[i]);

            require(result<traitCombi);

            traitCombi = result;            
        }

        require(!existMap[traitCombi], "result not unique");
        existMap[tokenTraits[sistaid]] = false;
        tokenTraits[sistaid] = traitCombi;
        existMap[traitCombi] = true;

        if(!burn) {
            traitsContract.mint(traitsToDetach, msg.sender);
        }

        emit SistaUpdated(sistaid, traitCombi);
    }

    function removeTraitFromCombi(uint initial, uint traitnr) public pure returns (uint) {
        uint mod = 1000;
        uint div = 1;

        uint newTraitCombi = 0;

        while(newTraitCombi == 0) {
            if(initial % mod / div == traitnr) {
                newTraitCombi = (initial / mod * mod / 1000) + (initial % mod % div);
            }
            mod = mod*1000;
            div = div*1000;
        }
        return newTraitCombi;
    }


    function assignDetachedTrait(uint sistaid, uint[] memory traitid, uint[] memory positionAfter) external returns (uint) {
        require(!paused(), "contract is paused");

        require(_isApprovedOrOwner(_msgSender(), sistaid), "no permission");
        require(traitid.length == positionAfter.length);

        uint newTraitCombi = tokenTraits[sistaid];

        for (uint k=0; k < traitid.length; k++) {
            require(traitsContract.balanceOf(msg.sender, traitid[k]) >= 1, "trait not owned");
            require(!containsTrait(newTraitCombi, traitid[k]), "sista already owns this trait");

            require(newTraitCombi < 1000000000000000000000000000000000000000000000000000000000000000000000000, "maximum of 25 traits exceeded");

            bool singleTrait = false;
            uint lower = 0;
            uint upper = 0;

            for(uint i; i < lowerBounds.length; i++) {
                if(traitid[k] <= upperBounds[i]  && traitid[k] >= lowerBounds[i]) {
                    if(i < 8) singleTrait = true;

                    lower = lowerBounds[i];
                    upper = upperBounds[i];
                    
                    break;
                }
            }

            require(positionAfter[k] == 0 || positionAfter[k] >= lower && positionAfter[k] <= upper, "position in wrong boundaries");

            uint mod = 1000;
            uint div = 1;
            uint temp = 999;

            while(true) {
                temp = newTraitCombi % mod / div;
                require(!(temp >= lower && temp <= upper && singleTrait), "second trait in single category not allowed");
                if((singleTrait && temp > upper) || 
                   (temp > upper && !singleTrait && positionAfter[k] == 0) ||
                   (temp > lower && !singleTrait && temp == positionAfter[k])) {
                        newTraitCombi = ((newTraitCombi / div * 1000) + traitid[k]) * (mod / 1000) + (newTraitCombi % mod % div);
                        break;
                }
                mod = mod*1000;
                div = div*1000;
            }
        }

        require(!existMap[newTraitCombi], "result not unique");
        existMap[newTraitCombi] = true;
        existMap[tokenTraits[sistaid]] = false;
        tokenTraits[sistaid] = newTraitCombi;

        for (uint i=0; i < traitid.length; i++) {
            traitsContract.burn(msg.sender, traitid[i], 1);
        }

        emit SistaUpdated(sistaid, newTraitCombi);

        return newTraitCombi;
    }   

    function containsTrait(uint combi, uint traitnr) public view returns (bool) {
        require(traitnr > 99 && traitnr < lowerBounds[0], "trait does not exist");

        uint mod = 1000;
        uint div = 1;

        while(true) {
            if(combi % mod / div == traitnr) {
                return true;
            } else if(combi % mod / div == 0) {
                return false;
            }
            mod = mod*1000;
            div = div*1000;
        }
        return false;
    }

    function setTraitsContract(address niftysistasAddress) external onlyOwner {
       traitsContract=NiftysistasTraitsContract(niftysistasAddress);
    }

 }

interface NiftysistasTraitsContract {
    function mint(uint[] calldata traits, address to) external;
    function burn(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }

 interface NiftydudesContract {
    function balanceOf(address account) external view returns (uint256);
 }