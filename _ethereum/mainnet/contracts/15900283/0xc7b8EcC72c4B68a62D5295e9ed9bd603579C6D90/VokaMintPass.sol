//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error SaleNotStarted();
error RoundSoldOut();
error PublicSaleStillLive();
error TokenBurned();
error MaxMints();
error SoldOut();
error Underpriced();
error NotWL();
error NotVIP();
error ArraysNotSameLength();
error NotOwner();
error BurningNotLive();
error NotApprovedToBurn();
error NotAccessPassContract();
error ZeroAddress();
error TokenAlreadyUsed();
error CallerNotArtContract();
/// @title Voka Mint Pass
/// @author Twitter: @0xSimon_
/// @notice Allows users to mint a mint pass that can be used later in the Voka Collection and the Voka Access Pass.
/// @dev Voka Mint Pass is released in batches. Each batch has its own maximum supply, whitelist, waitlist, and public sale.
/// @dev Whitelist per batch is handled by ECDSA Signature Recovery. We change the first argument of the abi.encodePacked function to mix up the hashes
/// @dev This ensures that a signature cannot be reused.
/// @dev Batches are mutually exclusive. A wallet in batch one cannot mint again in batch 3. Therefore, we can use _numberMinted to track number of mints on whitelist
/// @dev many globals are set post-construction to limit bytecode size upon deployment

import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721AStorage.sol";

import "./OwnableUpgradeable.sol";
import "./ECDSA.sol";
import "./TokenIdUsage.sol";

contract VokaMintPass is ERC721AQueryableUpgradeable, OwnableUpgradeable {
    using ECDSA for bytes32;
    //We Have Packed Token Usage In Case Of Proxy Upgrades and We Would Like To Add More Functionality To A Token
    //Past Versions Used Packed Data that has been simplified. To make sure the team is all in synch we haven't changed the name
    //For now _packedTokenUsage simply will return 1 if the token is used by Voka, and 0 if not. All other usages are handled inside getter functions
    mapping(uint256 => uint256) private _packedTokenUsage;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => string) public batchNames;
    uint256 private constant USED_BY_ART_CONTRACT_BITPOS = 0x1;
    uint256 private constant MAX_TOTAL_SUPPLY = 1500;
    address private constant USDC_ADDRESS_MAINNET =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    enum SaleStatus {
        INACTIVE,
        PRESALE,
        PUBLIC
    }

    address private vokaArtContract;
    address private vokaAccessPassContract;
    uint256 public currentBatchNumber;
    uint256 public publicPrice;
    uint256 public presalePrice;
    uint256 public usdcPrice;
    address private signer;
    address public membershipPassContract;
    uint256 public maxPublicMints;
    SaleStatus public saleStatus;
    bool private burningEnabled;
    string private unusedUri;
    string private usedUri;

    //OZ Initializer
    ///@notice We don't initialize the storage vars in the initializer to save bytecode upon deployment
    ///@dev Those vars are individually set in the deployment scripts
    function initialize() public initializerERC721A initializer {
        __ERC721A_init('Arties Mint Pass', 'ART');
        __Ownable_init();
    }

    /* ------------
        MINTING 
    --------------*/

    ///@param account specifies who to send NFTs to
    ///@param amount specifies the amount to send that account
    ///@dev to reduce bytecode size, we don't pass in an array of accounts & amounts. We can make a transfer contract afterwards for that function
    function airdrop(address account, uint256 amount) external onlyOwner {
        //Next Token ID More Representative of Use Case Than Total Supply Since Burning Will Be A Part Of This Collection
        supplyCheck(amount);
        _mint(account, amount);
    }

    ///@dev takes in an amount and reverts if adding that amount to the supply would overflow. Else returns true
    function supplyCheck(uint256 amount) internal view {
        if (amount + _nextTokenId() > maxSupplies[currentBatchNumber])
            revert SoldOut();
    }

    ///@param amount - the amount a user would like to mint
    ///@dev public mint function
    function publicMint(uint256 amount) external payable {
        //Ensure sale status is public
        if (saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        //Require that the supply check is true
        supplyCheck(amount);
        //If user sends 0 ether, then we assume they're minting with USDC
        if (msg.value == 0) {
            //Will Revert If It Doesen't Go Through
            transferUSDC(usdcPrice * amount);
        } else {
            if (msg.value < amount * publicPrice) revert Underpriced();
        }
        //Get How Many The User Has Already Minted on Public Sale
        uint64 numMintedPublic = _getAux(msg.sender);
        //Ensure user does not mint over the maxPublicMints limit
        if (numMintedPublic + amount > maxPublicMints) revert MaxMints();
        //Imposible To Overflow Since Max Will Be Less Than 10
        _setAux(msg.sender, numMintedPublic + uint64(amount));
        _mint(msg.sender, amount);
    }

    ///@param amount - the amount a user would like to mint
    ///@param max  - the max amount of mints we are allowing that user.
    ///@param signature the signature that we verify on-chain
    ///@notice max is safe to pass into function args since it's encoded into the signature that we are verifying
    ///@dev The whitelist mint function also serves as the WAITLIST mint function since we can add those signatures to the backend dynamically
    function whitelistMint(
        uint256 amount,
        uint256 max,
        bytes memory signature
    ) external payable {
        if (saleStatus != SaleStatus.PRESALE) revert SaleNotStarted();
        supplyCheck(amount);

        if (msg.value == 0) {
            //Will Revert If It Doesen't Go Through
            transferUSDC(usdcPrice * amount);
        } else {
            if (msg.value < amount * presalePrice) revert Underpriced();
        }
        // We Hash ['string','uint','address'] [batchName,maxAmount,signer]
        bytes32 hash = keccak256(
            abi.encodePacked(batchNames[currentBatchNumber], max, msg.sender)
        );
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert NotWL();
        if (_numberMinted(msg.sender) + amount > max) revert MaxMints();
        _mint(msg.sender, amount);
    }

    ///@notice This function is designed to be called from the Voka Art Contract
    ///@notice - The packedTokenData is set to binary 0000......1
    ///@param  mintPassId - the mintPassId in which a user want's to use
    function useMintPassFromArtContract(uint256 mintPassId) external {
        if (msg.sender != vokaArtContract) revert CallerNotArtContract();
        //Can only be used once by either the art contract or access pass contract
        //If used by either contract, the bitpos at
        if (_packedTokenUsage[mintPassId] & USED_BY_ART_CONTRACT_BITPOS != 0)
            revert TokenAlreadyUsed();
        _packedTokenUsage[mintPassId] = USED_BY_ART_CONTRACT_BITPOS;
    }

    ///@notice This contract is called strictly from the Access Pass Contract.
    ///@notice If a user hasn't used their token in the voka art collection to claim their Voka, this function will automatically do so
    ///@notice the packedTokenData is set to binary 0.......11 therefore, after this function, the art pass won't be able to use the pass which is what we want
    ///@param to - the user who's token is being used
    ///@param tokenIds - an array of the tokenIds that user would like to "use"
    function useMintPassesFromAccessPassContract(
        address to,
        uint256[] memory tokenIds
    ) external {
        //init for later
        uint256 numToMintFromVokaArtContract;
        if (msg.sender != vokaAccessPassContract) revert NotApprovedToBurn();
        if (!burningEnabled) revert BurningNotLive();
        for (uint256 i; i < tokenIds.length; ) {
            uint256 mintPassId = tokenIds[i];
            //If the token has been burned, this will revert
            if (to != ownerOf(mintPassId)) revert NotOwner();
            //We ensure that the user has given permission to the access pass contract to burn their mint pass
            if (!isApprovedForAll(ownerOf(mintPassId), msg.sender))
                revert TransferCallerNotOwnerNorApproved();

            _burn(tokenIds[i]);
            uint256 packedTokenData = _packedTokenUsage[mintPassId];

            //If the token hasn't been used then we need to make sure that we use that token to mint from the Voka collection
            if (packedTokenData == 0) {
                unchecked {
                    ++numToMintFromVokaArtContract;
                }
            }

            unchecked {
                ++i;
            }
        }
        if (numToMintFromVokaArtContract > 0) {
            IMinimalVoka(vokaArtContract).mintVokasFromMintPass(
                to,
                numToMintFromVokaArtContract
            );
        }
    }

    /* ---------------
        GETTERS
    ----------------*/

    function getNumMintedPublic(address account)
        external
        view
        returns (uint256)
    {
        return _getAux(account);
    }

    function getNumMintedWhitelist(address account)
        external
        view
        returns (uint256)
    {
        return _numberMinted(account);
    }

    function isTokenBurned(uint256 tokenId) internal view returns (bool) {
        //BITMASK_BURNED = (1 << 224)
        return
            ERC721AStorage.layout()._packedOwnerships[tokenId] & (1 << 224) !=
            0;
    }

    function tokenUsageInformation(uint256 tokenId)
        public
        view
        returns (TokenIdUsage memory)
    {
        uint256 packedInfo = _packedTokenUsage[tokenId];
        //First Bit Will Be 1 If Used By Voka Art Contract
        bool usedToClaimVoka = (packedInfo & 0x1) == 0x1;
        bool isBurned = isTokenBurned(tokenId);
        bool usedToClaimAccessPass;
        //If the token address == 0 this means that the ownerOf call reverted, in which case the token has been burned and
        //the token has been used to claim the access pass as well as the voka pass
        if (isBurned) {
            usedToClaimVoka = true;
            usedToClaimAccessPass = true;
        }
        TokenIdUsage memory info = TokenIdUsage(
            usedToClaimVoka,
            usedToClaimAccessPass
        );
        return info;
    }

    /* ---------------
        SETTERS
    ----------------*/
    function setCurrentBatchNumber(uint256 _newBatchNumber) external onlyOwner {
        currentBatchNumber = _newBatchNumber;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }

    function setUsdcPrice(uint256 _price) external onlyOwner {
        usdcPrice = _price;
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0));
        signer = _signer;
    }

    function setUnusedUri(string memory _unusedUri) external onlyOwner {
        unusedUri = _unusedUri;
    }

    function setUsedUri(string memory _usedUri) external onlyOwner {
        usedUri = _usedUri;
    }

    //0 = Inactive
    //1 = Presale
    //2 = Public
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    function setMaxPublicMints(uint256 _newMax) external onlyOwner {
        maxPublicMints = _newMax;
    }

    function setMaxSupplyAtIndex(uint256 index, uint256 val)
        external
        onlyOwner
    {
        maxSupplies[index] = val;
    }

    function setBatchNamesAtIndex(uint256 index, string memory batchName)
        external
        onlyOwner
    {
        batchNames[index] = batchName;
    }

    function setBurningEnabled(bool _burningEnabled) external onlyOwner {
        burningEnabled = _burningEnabled;
    }

    function setVokaArtContract(address _artContract) external onlyOwner {
        vokaArtContract = _artContract;
    }

    function setVokaAccessPassContract(address _accessPassContract)
        external
        onlyOwner
    {
        vokaAccessPassContract = _accessPassContract;
    }

    function transferUSDC(uint256 amount) internal {
        MinimalERC20(USDC_ADDRESS_MAINNET).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /* ----------------
        FACTORY
    ------------------*/
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        TokenIdUsage memory tokenUsage = tokenUsageInformation(tokenId);
        // uint256 packedTokenData = _packedTokenUsage[tokenId];
        if (tokenUsage.usedToClaimAccessPass) revert TokenBurned();
        if (!(tokenUsage.usedToClaimVoka)) {
            return unusedUri;
        } else {
            return usedUri;
        }

    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        uint256 usdcBalance = MinimalERC20(USDC_ADDRESS_MAINNET).balanceOf(
            address(this)
        );
        if (usdcBalance > 0) {
            MinimalERC20(USDC_ADDRESS_MAINNET).transfer(
                msg.sender,
                usdcBalance
            );
        }
    }
}

interface MinimalERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IMinimalVoka {
    function mintVokasFromMintPass(address to, uint256 amount) external;
}
