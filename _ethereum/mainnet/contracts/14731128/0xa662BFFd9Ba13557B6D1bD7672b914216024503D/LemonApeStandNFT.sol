pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
//SPDX-License-Identifier: MIT

/// @notice Thrown when completing the transaction results in overallocation of LemonApe Stands.
error MintedOut();
/// @notice Thrown when a user is trying to upgrade a stand, but does not have the previous stand in the upgrade flow.
error MissingPerviousStand();
/// @notice Thrown when the dutch auction phase has not yet started, or has already ended.
error MintNotStarted();
/// @notice Thrown when the upgrade phase has not yet started
error UpgradeNotStarted();
/// @notice Thrown when the user has already minted two LemonApe Stands in the dutch auction.
error MintingTooMany();
/// @notice Thrown when the value of the transaction is not enough for the current dutch auction or mintlist price.
error ValueTooLow();
/// @notice Thrown when a user is trying to upgrade past the highest stand level.
error MissingPreviousNFT();
/// @notice Thrown when a user doesn't have the previous stand level.
error UnknownUpgrade();

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
}

/// @title Generation 0 and 1 LemonApeStand NFTs
// contract LemonApeStandNFT is ERC721, Ownable {
contract LemonApeStandNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Determines the order of the species for each tokenId, mechanism for choosing starting index explained post mint, explanation hash: acb427e920bde46de95103f14b8e57798a603abcf87ff9d4163e5f61c6a56881.
    uint constant public provenanceHash = 0x9912e067bd3802c3b007ce40b6c125160d2ccb5352d199e20c092fdc17af8057;

    /// @dev Sole receiver of collected contract $LAS - dev wallet until staking contract live. Dev wallet will move tokens to staking
    address public stakingContract = 0x73199233184A4F01CCcbB30f31989f8e6e9cf34E;

    /// @dev Address of $LAS to mint Lemon Stands
    address public lasToken = 0x84c071CbFa571Af3c6c966f80530867D0d407F6E;

    /// @dev Address of $POTION to mint higher tier stands
    address public potionToken = 0x980693AbB2D6A92Bc67e95C9c646d24275D8236d;

    /// @dev 435 total nfts can ever be made
    uint constant lemonStandTotalSupply = 300;
    uint constant grapeStandTotalSupply = 100;
    uint constant dragonStandTotalSupply = 25;
    uint constant fourTwentyStandTotalSupply = 10;
    uint constant mintSupply = lemonStandTotalSupply + grapeStandTotalSupply + dragonStandTotalSupply + fourTwentyStandTotalSupply;
    uint256 public currentLemonStandPrice = 1000 * 10**18;

    /// @dev The offsets are the tokenIds that the corresponding evolution stage will begin minting at.

    uint constant grapeStandOffset = lemonStandTotalSupply;
    uint constant dragonStandOffset = grapeStandOffset + grapeStandTotalSupply;
    uint constant fourTwentyStandOffset = dragonStandOffset + dragonStandTotalSupply;

    /*///////////////////////////////////////////////////////////////
                        UPGRADE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev The next tokenID to be minted for each of the stand stages
    uint lemonStandSupply; //300
    uint grapeStandSupply; //100
    uint dragonStandSupply; //25
    uint fourTwentyStandSupply; //10

    /*///////////////////////////////////////////////////////////////
                            MINT STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice The timestamp the minting for Lemon Stands started
    bool public canStartMint;
    bool public canUpgradeStand;

    /// @notice The timestamp of the last time a Lemon Stand was minted
    uint256 public lastTimeMinted;
    uint256 public reductionTime = 1 hours;

    /// @notice Starting price of the Lemon Stand in $LAS (1,000 $LAS)
    uint256 constant public startPrice = 1000 * 10**18;

    uint256 public mintLimit = 3;

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public baseURI;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys the contract, airdropping to presalers.
    constructor(string memory _baseURI, address[] memory dropLemonStands) ERC721("LEMONAPESTAND NFT", "LASNFT") {
        baseURI = _baseURI;
        unchecked {
            for (uint256 i = 0; i < dropLemonStands.length; i++) {
                uint256 mintIndex = totalSupply();
                _mint(dropLemonStands[i], mintIndex);
                lemonStandSupply++;
                emit Transfer(address(0), dropLemonStands[i], i);
            }
        }
    }

    function setMintLimit(uint256 _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function enableMint() public onlyOwner {
        canStartMint = true;
        lastTimeMinted = block.timestamp;
    }

    function enableUpgrade() public onlyOwner {
        canUpgradeStand = true;
    }

    function updateStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = _stakingContract;
    }

    /*///////////////////////////////////////////////////////////////
                            METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to set the metadata URI.
    /// @param _baseURI The new metadata URI.
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /*///////////////////////////////////////////////////////////////
                        REVERSE-DUTCH AUCTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates the mint price with the accumulated rate deduction since the mint's started. Every hour there is no mint the price goes down 100 tokens. After every mint the price goes up 100 tokens.
    /// @return The mint price at the current time, or 0 if the deductions are greater than the mint's start price.
    function getCurrentTokenPrice() public view returns (uint) {
        uint priceReduction = ((block.timestamp - lastTimeMinted) / reductionTime) * 25 * 10**18;
        return currentLemonStandPrice >= priceReduction ? (currentLemonStandPrice - priceReduction) :  25 * 10**18;
    }

    /// @notice Purchases a LemonApeStand NFT in the reverse-dutch auction
    /// @param amountToMint the amount of NFTs to mint in one transcation.
    function mint(uint256 amountToMint) public {
        if(!canStartMint) revert MintNotStarted();
        uint price = getCurrentTokenPrice();
        if(IERC20(lasToken).balanceOf(msg.sender) < price * amountToMint) revert ValueTooLow();
        if(amountToMint > mintLimit) revert MintingTooMany();
        if(totalSupply() + amountToMint > lemonStandTotalSupply) revert MintedOut();
        //to save gas we calcualte the amount of $LAS token needed to mint the amount of NFTs a user has selected
        IERC20(lasToken).transferFrom(msg.sender, stakingContract, price * amountToMint);
        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
            unchecked {
                lemonStandSupply++;
            }
        }
        //to save gas we calcualte the currentLemonStandPrice after the minting loop
        lastTimeMinted = block.timestamp;
        currentLemonStandPrice += amountToMint * 25 * 10**18;
    }

    /*///////////////////////////////////////////////////////////////
                        UPGRADE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints an upgraded LemonApe Stand
    /// @param receiver Receiver of the upgraded LemonApe Stand
    /// @param standIdToUpgrade The upgrade (2-4) that the LemonApeStand NFT is undergoing
    function mintUpgradedStand(address receiver, uint standIdToUpgrade) public {
        if(!canUpgradeStand) revert UpgradeNotStarted();
        uint upgradeToStand;
        if(standIdToUpgrade <= lemonStandTotalSupply - 1){
            upgradeToStand = 2;
        } else if(standIdToUpgrade <= lemonStandTotalSupply + grapeStandTotalSupply - 1){
            upgradeToStand = 3;
        } else if(standIdToUpgrade <= lemonStandTotalSupply + grapeStandTotalSupply + dragonStandTotalSupply - 1){
            upgradeToStand = 4;
        } else {
            revert UnknownUpgrade();
        }

        if (upgradeToStand == 2) {
            if(grapeStandSupply >= grapeStandTotalSupply) revert MintedOut();
            if(IERC20(potionToken).balanceOf(msg.sender) < 1 * 10**18) revert ValueTooLow();
            if(!isExistVersionOfNFT(receiver, 1)) revert MissingPreviousNFT();
            IERC20(potionToken).transferFrom(msg.sender, stakingContract, 1 * 10**18);
            _mint(receiver, grapeStandOffset + grapeStandSupply);
            unchecked {
                grapeStandSupply++;
            }
        } else if (upgradeToStand == 3) {
            if(dragonStandSupply >= dragonStandTotalSupply) revert MintedOut();
            if(IERC20(potionToken).balanceOf(msg.sender) < 2 * 10**18) revert ValueTooLow();
            if(!isExistVersionOfNFT(receiver, 2)) revert MissingPreviousNFT();
            IERC20(potionToken).transferFrom(msg.sender, stakingContract, 2 * 10**18);
            _mint(receiver, dragonStandOffset + dragonStandSupply);
            unchecked {
                dragonStandSupply++;
            }
        } else if (upgradeToStand == 4) {
            if(fourTwentyStandSupply >= fourTwentyStandTotalSupply) revert MintedOut();
            if(IERC20(potionToken).balanceOf(msg.sender) < 3 * 10**18) revert ValueTooLow();
            if(!isExistVersionOfNFT(receiver, 3)) revert MissingPreviousNFT();
            IERC20(potionToken).transferFrom(msg.sender, stakingContract, 3 * 10**18);
            _mint(receiver, fourTwentyStandOffset + fourTwentyStandSupply);
            unchecked {
                fourTwentyStandSupply++;
            }
        } else  {
            revert UnknownUpgrade();
        }
    }
    /*///////////////////////////////////////////////////////////////
        This is a function to check what version NFT 
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints an upgraded LemonApe Stand
    /// @param id Id of the NFT
    /// @return version of the NFT

    function getVersionFromNFTId(uint id) public pure returns (uint version) 
    {

        if(id<=lemonStandTotalSupply - 1){
            return 1;
        }
        else if(id<=lemonStandTotalSupply + grapeStandTotalSupply - 1){
            return 2;
        }
        else if(id<=lemonStandTotalSupply + grapeStandTotalSupply + dragonStandTotalSupply - 1)
        {
            return 3;
        }
        else if(id<=lemonStandTotalSupply + grapeStandTotalSupply + dragonStandTotalSupply + fourTwentyStandTotalSupply - 1){
            return 4;
        }
        else{
            return 0;
        }
    }
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    /// Check if the user has version of the NFT
    /// @param _owner Address of the selected user
    /// @param version Version Number of the NFT to check if user has
    /// @return isExist true if it's exist
    function isExistVersionOfNFT(address _owner, uint version) public view returns (bool isExist) {
        uint256[] memory tokensId;
        tokensId = walletOfOwner(_owner);
        for (uint256 i = 0; i < tokensId.length; i++) {
            if (getVersionFromNFTId(tokensId[i])==version) return true;
        }
        return false;
    }

}