pragma solidity ^0.8.14;
/**
* @title SupDucksVX contract
* @dev Extends ERC721Enumerable Non-Fungible Token Standard basic implementation
*/

/**
*  SPDX-License-Identifier: UNLICENSED
*/

/**
 @@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%&@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%&@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%&&&&&&&@@@@@@@@
@@@@@@@@@@@@@@@@@&%%%%%%%%%%%%%%%%%%%&&&%%@@@@@@@@
@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%&&&@@@@@
@@@@@@@@@@@@@@&&&&&&&&&%%%%%%%%%%%%%%%%%%&&&@@@@@@
@@@@@@@@@@@@@@@&&%%%%%%&&&&&&&&&&&&&&&&&&&&@@@@@@@
@@@@@@@@@@@@@@%%%%(//////%%%&&%%%%%%%%%%%&&&&&@@@@
@@@@@@@@@@@@@@@@///////////#(/////////%%%%%&&@&@@@
@@@@@@@@@@@@@@@@////@@%////##////(%%////%%%%@@@@@@
@@@@@@@@@@@@@@@@##((((((((###((((((((###%%%%@@@@@@
@@@@@@@@@@@@@@#((###((((%######((((#####%(#%@@@@@@
@@@@@@@@@@@@@@((((##((##(((((((((####(((((#%@@@@@@
@@@@@@@@@@@@@%#(((((((((((((((((((#((((#((%&@@@@@@
@@@@@@@@@@@@@%#######(((((((((((((((#((%##&@@@@@@@
@@@@@@@@@@@@@@@########################%##&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@((((((((#########%&@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&######%@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#######&@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@#####%%%%%%%%%#############@@@@@@@@
@@@@@@@@@@@@#########%%%%&###########(((((###@@@@@
@@@@@@@@@@##########################((((((((((@@@@
@@@@@@@@@@##########################((((((((((@@@@
@@@@@@@@@###########################(((((((((((@@@
@@@@@@@@&##############################((((((((@@@
@@@@@@@@%%&###########################((((((%%%%@@
@@@@@@@@&&&&&&&#######################%%%%%%%%%%@@
@@@@@@@@&&&&&&&%#######################%%%%%%%%%@@
@@@@@@@&&&&&&&&%#########((((((##((##(((%%%%%%%%%@
@@@@@@@&&&&&&&&@(((((((((((##((((((((((#%%%%%%%%%@
@@@@@@#######&@@(((((((((((##((((((((((#@%%%#((%%%
@@@@@#(#####&&@@########(##((((((((((((@@((#((%%%%
@@@@@######&&@@@%&&%%%#%%%%%%######((((@@(((((%%%%
@@@@######%&@@&%&%%%%%%%%%%&%%#%%##%%%%@((((((%%%@
@@@#######&&@&&%%%%%%%%%%%%%&&&%%%%###%#(((((%%%%@
@@%####((&&@@%%%%#%%%%%%%%####%######(((#%((%%%%%@
@@@%%%%#&&@@&%%&#%%%%%%%############////%#(%%%%&@@
&&&%&&&&&&%#@&&&##&##################%%%#(#%%%%%&@
&&&&&&%%%%%%%&&%##%################&&&&&&&&%%%%%@@
&&&%%&&&&&&&&&&##%###################&&&&&&&&%%@@@
@@@&&&&&&&@@&&&##&###################@@@@@@@@@@@@@
@@@@@@@@@@@@&&%######################@@@@@@@@@@@@@
@@@@@@@@@@@@@&&%%###################%@@@@@@@@@@@@@
@@@@@@@@@@@@@&&&####################@@@@@@@@@@@@@@
@@@@@@@@@@@@@&&&####################@@@@@@@@@@@@@@
@@@@@@@@@@@@&&&%#######(((##%&%######@@@@@@@@@@@@@
@@@@@@@@@@@@@@@&&%#######&&&&&%######@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@%&#######&&&%&&######%@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&&%######%%&&&&######%@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&%&#####%&%&&&#####%%@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@&%%####%&%%&&%###%%@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%####&&&%&%####%@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&&####&&&&&&#####@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&&&###&&&&&&#####@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@&%%&@&&&##&&&&&&@###%@@@@@@@@@@@@@
@@@@@@@@@@@%((&&%&&&&&&&&((((((%@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@%///////////((((((%&&&&&&&@@@@@@@@@@@@@
*/

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

interface IDucksV8 {
	function getTraits(uint tokenId) external view returns (uint, uint, uint, uint, uint, uint);
    function ownerOf(uint tokenId) external view returns (address);
}

interface IVoltV4 {
	function balanceOf(address user) external returns(uint);
    function spend(address user, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

contract SupDucksVXV2 is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    using MerkleProofUpgradeable for bytes32[];

    bool public saleIsActive;
    bool public claimIsActive;
    bool public bonusIsActive;
    
    IDucksV8 public SupDucks;
    string internal baseURI;
    uint256 public numPublicMinted;
    address internal splitterAddress;
    uint256 public constant MAX_VX_CLAIMED = 10001;
    IVoltV4 public VOLTAGE;
    bytes32 public merkleRoot;

    struct Duck {
        uint background;
        uint skin;
        uint clothes;
        uint hat;
        uint mouth;
        uint eyes;
    }

    function claimVXs(uint[] calldata duckTokenIds) external {
        require(claimIsActive, "Claim must be active to claim VX");
        require(duckTokenIds.length <= 20, "Limit 20 tokenIds");
        for(uint i = 0; i < duckTokenIds.length; i++){
            require(duckTokenIds[i] <= 10000, "Duck id out of range");
            uint claimedIndex = duckTokenIds[i] / 256;
            uint claimedBitShift = duckTokenIds[i] % 256;
            require((claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 0, "VX already claimed");
            require(msg.sender == SupDucks.ownerOf(duckTokenIds[i]), "You don't own this duck");
            _safeMint(msg.sender, duckTokenIds[i]);
            claimed[claimedIndex] = claimed[claimedIndex] | (uint256(1) << claimedBitShift);
        }
        VOLTAGE.spend(msg.sender, duckTokenIds.length * 750 ether);
    }

    function mintVX(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint VX");
        require(numberOfTokens <= 20, "Can only mint 20 tokens at a time");
        require(numPublicMinted + numberOfTokens <= publicMintSupply, "Purchase would exceed max supply of VXs");
        require(price * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, numPublicMinted + MAX_VX_CLAIMED);
            numPublicMinted++;
        }
    }

    function claimBonus(        
        bytes32[] calldata proof,
        bytes32 megalodon,
        uint amount
    ) external {
        require(bonusIsActive, "Bonus must be active to claim bonus VX");
        require(keccak256(abi.encodePacked(msg.sender, amount)) == megalodon, "Incorrent bonus amount or ineligible for bonus");
        require(proof.verify(merkleRoot, keccak256(abi.encodePacked(megalodon))), "You are not eligible for bonus");
        require(bonusClaimed[msg.sender] == false, "Bonus already claimed");

        uint idToMint = lastClaimed + 1;

        for(uint i = 0; i < amount; i++) {
            while(_exists(idToMint)){
                idToMint++;
            }
            uint claimedIndex = idToMint / 256;
            uint claimedBitShift = idToMint % 256;
            _safeMint(msg.sender, idToMint);
            claimed[claimedIndex] = claimed[claimedIndex] | (uint256(1) << claimedBitShift);
        }

        lastClaimed = idToMint;
        bonusClaimed[msg.sender] = true;
    }

    /**
     * Mold from 2D
     */
    function reserveVX(uint numberOfTokens) external onlyOwner {
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, numPublicMinted + MAX_VX_CLAIMED);
            numPublicMinted++;
        }
    }

    function claimFor(uint[] calldata duckTokenIds, address _address) external onlyOwner {
        for(uint i = 0; i < duckTokenIds.length; i++){
            uint claimedIndex = duckTokenIds[i] / 256;
            uint claimedBitShift = duckTokenIds[i] % 256;
            require((claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 0, "VX already claimed");
            _safeMint(_address, duckTokenIds[i]);
            claimed[claimedIndex] = claimed[claimedIndex] | (uint256(1) << claimedBitShift);
        }
    }

    function getTraits(uint tokenId) public view returns (uint, uint, uint, uint, uint, uint){    
        require(_exists(tokenId), "ERC721Metadata: trait query for nonexistent token");
        Duck memory duck;
        (duck.background, duck.skin, duck.clothes, duck.hat, duck.mouth, duck.eyes) = SupDucks.getTraits(tokenId);
        return(
            duck.background,
            duck.skin,
            duck.clothes,
            duck.hat,
            duck.mouth,
            duck.eyes
        );
    }

    uint256[40] public claimed; // bitfields

    function setClaimed(uint256[40] calldata newClaimedBitfields) external onlyOwner {
        claimed = newClaimedBitfields;
    }

    function isClaimed(uint256 duckTokenId) public view returns (bool){
        uint claimedIndex = duckTokenId / 256;
        uint claimedBitShift = duckTokenId % 256;
        return (claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 1;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function flipBonusState() external onlyOwner {
        bonusIsActive = !bonusIsActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(splitterAddress).transfer(balance);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setSupDucks(address supAddy) external onlyOwner {
		SupDucks = IDucksV8(supAddy);
	}

    function setVOLTAGE(address VOLTaddy) external onlyOwner {
		VOLTAGE = IVoltV4(VOLTaddy);
	}

    function setSplitterAddress(address splitter) external onlyOwner {
        splitterAddress = splitter;
    }

    uint256 public constant MAX_VX_PUBLIC = 10000;
    uint256 public price;
    uint256 public publicMintSupply;

    function setMintOptions(uint _price, uint _publicMintSupply) external onlyOwner {
        require(MAX_VX_PUBLIC >= _publicMintSupply, "exceeds maximum supply");
        price = _price;
        publicMintSupply = _publicMintSupply;
    }
    
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function exists(uint tokenId) view external returns (bool){
        return _exists(tokenId);
    }

    function exist(uint[] calldata tokenIds) view external returns (bool[] memory) {
        bool[] memory existArr = new bool[](tokenIds.length);
        for(uint i = 0; i < tokenIds.length; i++){
            existArr[i] = _exists(tokenIds[i]);
        }
        return existArr;
    }

    function getClaimIsActive() view external returns (bool) {
        return claimIsActive;
    }

    function isEligibleForBonus(        
        bytes32[] calldata proof,
        bytes32 megalodon,
        uint amount,
        address account
    ) external view returns (bool) {
        return (!bonusClaimed[account] && keccak256(abi.encodePacked(account, amount)) == megalodon && proof.verify(merkleRoot, keccak256(abi.encodePacked(megalodon))));
    }

    function initialize() initializer public {
        __ERC721_init("SupDucksVX", "SDVX");
        __ERC721Enumerable_init();
        __Ownable_init();

        price = 5 ether;

        splitterAddress = 0xD28DBD19B93b6CC55D85dEbe9d93644097Fed773;
        setBaseURI("https://api.supducks.com/supducksvx/metadata/");
        SupDucks = IDucksV8(0x3Fe1a4c1481c8351E91B64D5c398b159dE07cbc5);
        VOLTAGE = IVoltV4(0xfFbF315f70E458e49229654DeA4cE192d26f9b25);
    }

    mapping(address => bool) public bonusClaimed;
    uint public lastClaimed;
    bool public openClaimIsActive;

    function openClaimVX(uint amount) external {
        require(openClaimIsActive, "Claim must be active to claim VX");
        require(amount <= 20, "Limit 20 tokenIds");
        uint idToMint = lastClaimed + 1;

        for(uint i = 0; i < amount; i++) {
            while(_exists(idToMint)){
                idToMint++;
            }

            uint claimedIndex = idToMint / 256;
            uint claimedBitShift = idToMint % 256;
            require((claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 0, "VX already claimed");
            _safeMint(msg.sender, idToMint);
            claimed[claimedIndex] = claimed[claimedIndex] | (uint256(1) << claimedBitShift);

        }

        lastClaimed = idToMint;
        VOLTAGE.spend(msg.sender, amount * 1500 ether);
    }

    function flipOpenClaimState() external onlyOwner {
        openClaimIsActive = !openClaimIsActive;
    }
}
