// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./MerkleProof.sol";

import "./Dam.sol";

contract BuildingBeaverz is ERC721A, Ownable {
    using SafeMath for uint256;
    using Address for address;
    Dam public damToken;

    string public baseURI;
    bytes32[4] public unlockRoots;
    bytes32[4] public boosterRoots;
    bytes32 public whiteListMerkleRoot = 0x2530b0ea0ea6774c3c0adea06b21c92b4a7b90832127597dc111a69109fc57c8;
    uint256 public mintPrice = 0.05 ether;
    uint256 public GEAR_EM_UP_PRICE = 25 ether;
    uint256 public BREED_PRICE = 50 ether;
    uint256 public DAM_PRICE = 60 ether;
    bool public publicMintLive;
    bool public preSaleMintLive;
    
    mapping(address => uint256) public balanceGen;
    mapping(uint256 => bool) public isAlpha;
    mapping(uint256 => bool) public isGameIDLive;
    mapping(uint256 => bool) public isGameIDWon;
    mapping(uint256 => mapping(uint256 => bool)) public houseHasWonGameId;
    mapping(uint256 => mapping(uint256 => bool)) public houseHasUnlockedGameId;
    mapping(uint256 => mapping(uint256 => bool)) public houseHasUnlockedBoosterId;
    mapping(uint256 => uint256) public houseAlphaPopulation;
    mapping(uint256 => uint256) public houseBabyPopulation;
    mapping(uint256 => uint256) public houseDamPopulation;
    mapping(uint256 => uint256) public houseVillagePopulation;
    mapping(uint256 => bool) public babyIsInColony;
    mapping(uint256 => uint256) public tokenIdToHouse;
    uint256 public amountBeavendor;
    uint256 public amountBeavranos;
    uint256 public amountBeaverzStrikeBack;
    uint256 public amountTarbeavyen;

    constructor() ERC721A("Building Beaverz", "Beaver") {
        baseURI = "https://buildingbeaverz.com/api/token/";

        unlockRoots[0] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        unlockRoots[1] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        unlockRoots[2] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        unlockRoots[3] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;


        boosterRoots[0] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        boosterRoots[1] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        boosterRoots[2] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
        boosterRoots[3] = 0xb28561fb51803da58532f87c653b33d6aef008a9972a4f87b5094b920018412f;
    }


    function changeUnlockSecret(uint256 index, bytes32 _merkleRoot) external onlyOwner {
        unlockRoots[index] = _merkleRoot;
    }

    function changeWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function changeBoosterSecret(uint256 index, bytes32 _merkleRoot) external onlyOwner {
        boosterRoots[index] = _merkleRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function changeBase(string memory _newBase) external onlyOwner {
        baseURI = _newBase;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setGearEmUpPrice(uint256 _price) external onlyOwner {
        GEAR_EM_UP_PRICE = _price;
    }

    function setBreedPrice(uint256 _price) external onlyOwner {
        BREED_PRICE = _price;
    }

    function setDamPrice(uint256 _price) external onlyOwner {
        DAM_PRICE = _price;
    }

    function random() private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encode(block.difficulty, block.timestamp)));
        return randomHash % 1000;
    } 

    function setDamToken(address _dam) external onlyOwner {
        damToken = Dam(_dam);
    }
    function flipPublicMintLive() external onlyOwner {
        publicMintLive = !publicMintLive;
    }
    function flipPreSaleMintLive() external onlyOwner {
        preSaleMintLive = !preSaleMintLive;
    }
    function flipGameIDIsLive(uint256 gameId) external onlyOwner {
        isGameIDLive[gameId] = !isGameIDLive[gameId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override  {
		damToken.updateReward(from, to, tokenId);
		if (tokenId < 10001)
		{
			balanceGen[from]--;
			balanceGen[to]++;
		}
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override  {
		damToken.updateReward(from, to, tokenId);
		if (tokenId < 10001)
		{
			balanceGen[from]--;
			balanceGen[to]++;
		}
		super.safeTransferFrom(from, to, tokenId, _data);
	}


    function getReward() external {
        damToken.updateReward(msg.sender, address(0), 0);
        damToken.getReward(msg.sender);
    }

    function fetchBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function amountMinted() public view returns (uint256) {
        return totalSupply();
    }

    function beavendorSupply() public view returns (uint256) {
        return amountBeavendor;
    }
    function beaveranosSupply() public view returns (uint256) {
        return amountBeavranos;
    }
    function beaverzStrikeBackSupply() public view returns (uint256) {
        return amountBeaverzStrikeBack;
    }
    function tarbeavynSupply() public view returns (uint256) {
        return amountTarbeavyen;
    }

    function canMintHouse(uint256 houseId, uint256 num) internal view returns (bool) {
        if (houseId == 1) {
            return(amountBeavendor + num <= 2500);
        } else if(houseId == 2) {
            return(amountBeavranos + num <= 2500);
        } else if(houseId == 3) {
            return(amountBeaverzStrikeBack + num <= 2500);
        } else if(houseId == 4) {
            return(amountTarbeavyen + num <= 2500);
        }
    }

    //Used for airdrops, giveaways, and vault storage
    function devMint(uint256 num, uint256 houseId) external payable onlyOwner {
        require(canMintHouse(houseId, num), "House full!");
        uint256 currentTotalSupply = totalSupply();
        for (uint i = 0; i < num; i++) {
            tokenIdToHouse[currentTotalSupply + i] = houseId;
        }
        if (houseId == 1) {
            amountBeavendor = amountBeavendor + num;
        } else if(houseId == 2) {
            amountBeavranos = amountBeavranos + num;
        } else if(houseId == 3) {
            amountBeaverzStrikeBack = amountBeaverzStrikeBack + num;
        } else if(houseId == 4) {
            amountTarbeavyen = amountTarbeavyen + num;
        }
        _safeMint(msg.sender, num);
        balanceGen[msg.sender] = balanceGen[msg.sender] + num;
        damToken.updateRewardOnMint(msg.sender, num);
    }

    // Let there be Beaverz!
    function publicMint(uint256 num, uint256 houseId) public payable {
        require(publicMintLive, "Public mint not live");
        require(totalSupply() < 10001, "Sold Out!");
        require(tx.origin == msg.sender, "No bots");
        require(num <= 4, "You can only mint 4 at a time");
        require(balanceGen[msg.sender] < 8, "Cant own more than 8 per address");
        require(msg.value == mintPrice * num, "Valid price not sent");
        require(canMintHouse(houseId, num), "House full!");
        uint256 currentTotalSupply = totalSupply();
        for (uint i = 0; i < num; i++) {
            tokenIdToHouse[currentTotalSupply + i] = houseId;
        }
        if (houseId == 1) {
            amountBeavendor = amountBeavendor + num;
        } else if(houseId == 2) {
            amountBeavranos = amountBeavranos + num;
        } else if(houseId == 3) {
            amountBeaverzStrikeBack = amountBeaverzStrikeBack + num;
        } else if(houseId == 4) {
            amountTarbeavyen = amountTarbeavyen + num;
        }
        _safeMint(msg.sender, num);
        balanceGen[msg.sender] = balanceGen[msg.sender] + num;
        damToken.updateRewardOnMint(msg.sender, num);
    }

    // Whitelist Mint!
    function whitelistMint(uint256 num, bytes32[] calldata whitelistProof, uint256 houseId) public payable {
        require(preSaleMintLive, "Whitelist mint not live");
        require(totalSupply() < 10001, "Sold Out!");
        require(tx.origin == msg.sender, "No bots");
        require(num <= 4, "You can only mint 4 at a time");
        require(balanceGen[msg.sender] < 8, "Cant own more than 8 per address");
        require(msg.value == mintPrice * num, "Valid price not sent");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(whitelistProof, whiteListMerkleRoot, leaf), "Invalid whitelistProof");
        require(canMintHouse(houseId, num), "House full!");
        uint256 currentTotalSupply = totalSupply();
        for (uint i = 0; i < num; i++) {
            tokenIdToHouse[currentTotalSupply + i] = houseId;
        }
        if (houseId == 1) {
            amountBeavendor = amountBeavendor + num;
        } else if(houseId == 2) {
            amountBeavranos = amountBeavranos + num;
        } else if(houseId == 3) {
            amountBeaverzStrikeBack = amountBeaverzStrikeBack + num;
        } else if(houseId == 4) {
            amountTarbeavyen = amountTarbeavyen + num;
        }
        _safeMint(msg.sender, num);
        balanceGen[msg.sender] = balanceGen[msg.sender] + num;
        damToken.updateRewardOnMint(msg.sender, num);
    }

    function unlockXGame(uint256 tokenId, uint256 gameId, bytes32[] calldata proof, bytes32 leaf) external {
        require(ERC721A.ownerOf(tokenId) == msg.sender, "must own a beaver");
        bytes32 merkleRoot = unlockRoots[gameId];
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Proof");
        uint256 houseId = whatHouse(tokenId);
        houseHasUnlockedGameId[houseId][gameId] = true;
    }

    function unlockXBooster(uint256 tokenId, uint256 gameId, bytes32[] calldata proof, bytes32 leaf) external {
        require(ERC721A.ownerOf(tokenId) == msg.sender, "must own a beaver");
        bytes32 merkleRoot = boosterRoots[gameId];
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid Proof");
        uint256 houseId = whatHouse(tokenId);
        houseHasUnlockedBoosterId[houseId][gameId] = true;
    }

    function whatHouse(uint256 tokenId) public view returns (uint256) {
        return tokenIdToHouse[tokenId];
    }
 
    function gearEmUp(uint256 tokenId) external payable returns (bool) {
        require(isGameIDLive[0], "Game not live");
        require(ERC721A.ownerOf(tokenId) == msg.sender, "must own a beaver");
        uint256 houseId = whatHouse(tokenId);

        // Check if that house has unlocked this game
        require(houseHasUnlockedGameId[houseId][0], "House has not unlocked this game");
    
        // Burn $damn
        damToken.burn(msg.sender, GEAR_EM_UP_PRICE);

        // Upgrade 70% of the time or 100% if booster unlocked
        if (houseHasUnlockedBoosterId[houseId][0] || random() > 700) {
            houseAlphaPopulation[houseId]++;
            // Check if winner
            if(houseAlphaPopulation[houseId] == 250 && !isGameIDWon[0]){
                houseHasWonGameId[houseId][0] = true;
                isGameIDWon[0] = true;
            }
            isAlpha[tokenId] = true;
            return true;
        }
        return false;
    }

    function spreadThySeed(uint256 tokenIdOne, uint256 tokenIdTwo) external payable returns (bool) {
        require(isGameIDLive[1], "Game not live");
        require(ERC721A.ownerOf(tokenIdOne) == msg.sender && ERC721A.ownerOf(tokenIdTwo) == msg.sender, "not your beaverz");
        uint256 houseId = whatHouse(tokenIdOne);
        require(houseId == whatHouse(tokenIdTwo), "Beaverz must be same house");

        // Check if that house has unlocked this game
        require(houseHasUnlockedGameId[houseId][1], "House has not unlocked this game");
    
        // Burn $damn
        damToken.burn(msg.sender, BREED_PRICE);

        // Upgrade 70% of the time or 100% if booster unlocked
        if (houseHasUnlockedBoosterId[houseId][1] || random() > 700) {
            houseBabyPopulation[houseId]++;
            // Check if winner
            if(houseBabyPopulation[houseId] == 2500 && !isGameIDWon[1]){
                houseHasWonGameId[houseId][1] = true;
                isGameIDWon[1] = true;
            }
            _safeMint(msg.sender, 1);
            return true;
        }
        return false;
    }

    function toxicWasteSpill(uint256 tokenIdOne, uint256 tokenIdTwo, uint256 babyIdOne, uint256 babyIdTwo) external payable returns (bool) {
        require(isGameIDLive[2], "Game not live");
        require(ERC721A.ownerOf(tokenIdOne) == msg.sender && ERC721A.ownerOf(tokenIdTwo) == msg.sender, "not your beaverz");
        require(ERC721A.ownerOf(babyIdOne) == msg.sender && ERC721A.ownerOf(babyIdTwo) == msg.sender, "not your babies");
        uint256 houseId = whatHouse(tokenIdOne);
        require(houseId == whatHouse(tokenIdTwo) && whatHouse(tokenIdTwo) == whatHouse(babyIdOne) && whatHouse(babyIdOne) == whatHouse(babyIdTwo), "Must be in same colony");

        // Check if that house has unlocked this game
        require(houseHasUnlockedGameId[houseId][2], "House has not unlocked this game");
    
        // Burn $damn
        damToken.burn(msg.sender, DAM_PRICE);

        // Upgrade 70% of the time or 100% if booster unlocked
        if (houseHasUnlockedBoosterId[houseId][2] || random() > 700) {
            houseDamPopulation[houseId]++;
            // Check if winner
            if(houseDamPopulation[houseId] == 1250 && !isGameIDWon[2]){
                houseHasWonGameId[houseId][2] = true;
                isGameIDWon[2] = true;
            }
            babyIsInColony[babyIdOne] = true;
            babyIsInColony[babyIdTwo] = true;
            return true;
        }
        return false;
    }

    function saveTheHelplessHumans(uint256 tokenIdOne, uint256 tokenIdTwo, uint256 babyIdOne, uint256 babyIdTwo) external payable returns (bool) {
        require(isGameIDLive[3], "Game not live");
        require(ERC721A.ownerOf(tokenIdOne) == msg.sender && ERC721A.ownerOf(tokenIdTwo) == msg.sender, "not your beaverz");
        require(ERC721A.ownerOf(babyIdOne) == msg.sender && ERC721A.ownerOf(babyIdTwo) == msg.sender, "not your babies");
        uint256 houseId = whatHouse(tokenIdOne);
        require(houseId == whatHouse(tokenIdTwo) && whatHouse(tokenIdTwo) == whatHouse(babyIdOne) && whatHouse(babyIdOne) == whatHouse(babyIdTwo), "Must be in same colony");


        // Check if that house has unlocked this game
        require(houseHasUnlockedGameId[houseId][3], "House has not unlocked this game");
    
        // Burn $damn
        damToken.burn(msg.sender, DAM_PRICE);

        // Upgrade 70% of the time or 100% if booster unlocked
        if (houseHasUnlockedBoosterId[houseId][3] || random() > 700) {
            if(houseDamPopulation[houseId] > 29) {
                houseVillagePopulation[houseId]++;
                // Check if winner
                if(houseVillagePopulation[houseId] == 99 && !isGameIDWon[3]){
                    houseHasWonGameId[houseId][3] = true;
                    isGameIDWon[3] = true;
                }
                houseDamPopulation[houseId] = houseDamPopulation[houseId] - 30;
                return true;
            }
        }
        return false;
    }

}
