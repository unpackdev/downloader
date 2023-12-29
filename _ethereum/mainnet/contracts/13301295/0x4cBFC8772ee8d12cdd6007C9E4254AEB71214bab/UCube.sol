// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./ERC721.sol";
import "./Context.sol";
import "./Ownable.sol";

contract UCube is Context, Ownable, ERC721 {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    
    address private packContractAddress;


    uint128 private basisPoints = 10000;
    
    mapping(address => uint256[]) private cubesByAddress;
    
    
    string private baseURI = "https://ucubemeta.com/cube/meta/";
    string private contractBaseURI = "https://ucubemeta.com/cube/contract_meta";
    
    struct Collaborators {
        address addr;
        uint256 cut;
    }
    
    Collaborators[] internal collaborators;

    
    uint16 constant startCubeId = 1;
    uint16 constant giftCubes = 400;
    uint16 constant mintpassCubes = 1000;
    
    uint16 constant numOfPacks = 9600;
    
    uint16 constant twoPackNum = 6154;
    uint16 constant threePackNum = 2588;
    uint16 constant fourPackNum = 762;
    uint16 constant fivePackNum = 96;

    mapping (uint8 => uint16[]) private packsByCubeCount;

    
    uint16 private totalCubes = 25000;
    uint16 private totalMintedCubes = 0;

    uint16 private currentCubeIdForMintPass = startCubeId + giftCubes;
    uint16 private remainsToAirdrop = mintpassCubes;
    uint16 private remainsToGift = giftCubes;
    uint16 private currentCubeIdForRegularMint = startCubeId + giftCubes + mintpassCubes;

    uint8[] private setsToMint;


    constructor () ERC721("UCube", "UCube") {
        uint256 regularCubesNumber = (totalCubes - giftCubes - mintpassCubes);
        
        require(regularCubesNumber == (2*twoPackNum + 3*threePackNum + 4*fourPackNum + 5*fivePackNum), "Wrong set numbers");
        require(numOfPacks == (twoPackNum + threePackNum + fourPackNum + fivePackNum), "Sets quantity is not equal to packs quantity");
        
        packsByCubeCount[2] = [0, twoPackNum];
        packsByCubeCount[3] = [0, threePackNum];
        packsByCubeCount[4] = [0, fourPackNum];
        packsByCubeCount[5] = [0, fivePackNum];
    }
    
    
    
    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }
    
    function addSets(uint8 cubesInSet, uint16 numOfSets) external onlyOwner
    {
        require(2 == packsByCubeCount[cubesInSet].length, "This value of cubes in set is not allowed.");
        require((packsByCubeCount[cubesInSet][0] + numOfSets) <= packsByCubeCount[cubesInSet][1], "Total exceed for set.");
        
        uint16 i;

        for (i = 0; i < numOfSets; i++) {
            setsToMint.push(cubesInSet);
        }
        
        packsByCubeCount[cubesInSet][0] = packsByCubeCount[cubesInSet][0] + numOfSets;
    }
    
    function setPackContractAddr(address _addr) external onlyOwner {
       packContractAddress = _addr;
    }


    // ONLY collaborators
    
    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }
    
    function setContractBaseTokenURI(string memory _uri) external onlyCollaborator {
        contractBaseURI = _uri;
    }

    function makeGift(address owner, uint256 cubeId) external onlyCollaborator {
        require(!_exists(cubeId), "Cube already owned");
        require(cubeId < (startCubeId + giftCubes), "Cube Id is out of gift list");
        
        _mint(owner, cubeId);

        totalMintedCubes++;
    }

    
    function airdropMint(address[] calldata _gifted) external onlyCollaborator {
        require(remainsToAirdrop >= _gifted.length, "No enough cubes to airdrop.");

        for (uint i = 0; i < _gifted.length; i++) {
             require(!_exists(currentCubeIdForMintPass), "Cube already owned");
             
            _mint(_gifted[i], currentCubeIdForMintPass);

            currentCubeIdForMintPass++;
            totalMintedCubes++;
            remainsToAirdrop--;
        }
    }
    
    
    function setCurrentCubeForMintPass(uint16 _val, uint _fuse) external onlyCollaborator {
        require(_fuse == 111, "Fuse is incorrect.");
        
        currentCubeIdForMintPass = _val;
    }
    
    function getRemainsToAirdrop() external view onlyCollaborator returns (uint16) {
        return remainsToAirdrop;
    }
    
    function getRemainsToGift() external view onlyCollaborator returns (uint16) {
        return remainsToGift;
    }
    

    // END ONLY COLLABORATORS
    
    
    fallback() external payable {}
    
    receive() external payable {}
    
    
    
    function mintByPack(address owner) external {
        require(msg.sender == packContractAddress, "Unauthorized");
        require(setsToMint.length > 0, "Out of cubes");
        
        uint8 numOfCubesToMint = getNumOfCubesToRegularMint();

        for (uint8 i = 0; i < numOfCubesToMint; i++) {
            
            _mint(owner, currentCubeIdForRegularMint);

            cubesByAddress[owner].push(currentCubeIdForRegularMint);

            totalMintedCubes++;
            currentCubeIdForRegularMint++;
        }
    }
    
    
    
    function contractURI() public view returns (string memory) {
        return contractBaseURI;
    }


    function getTokensByAddress(address _addr) public view returns (uint256[] memory) {
        return cubesByAddress[_addr];
    }


    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedCubes;
    }

    
    // INTERNAL 
    
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
    
    
    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
    function getNumOfCubesToRegularMint() internal returns (uint8) {
        uint256 random = _getRandomNumberWithSets((setsToMint.length - 1));
        uint8 numOfCubesToMint = setsToMint[random];
        setsToMint[random] = setsToMint[setsToMint.length - 1];
        setsToMint.pop();

        return numOfCubesToMint;
    }
    

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumberWithSets(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    setsToMint.length,
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % (_upper + 1);
    }
}