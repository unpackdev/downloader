// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IShibaDogeArmy is IERC1155 {
    function crateContentMint(
        uint256 eftID,
        uint256 amount,
        address receiver,
        bytes calldata data
    ) external;

    function depositLockedCrateFromManager(
        address holder,
        uint256 crateId
    ) external;
}

contract ShibaDogeLabsCrateOpener_V1 is
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IShibaDogeArmy SHIBADOGEARMY;

    mapping(uint256 => bool) public crateInitialized;

    mapping(uint256 => uint256[]) public crateItems;
    mapping(uint256 => uint256[]) public crateItemSupplies;

    mapping(uint256 => uint256) public sealedCrateCount;

    mapping(uint256 => bool) public cratePaused;

    // crate id => user address => depositedBlockNumber;
    mapping(uint256 => mapping(address => uint256))
        public crateAddressDepositBlock;

    event CrateDeposited(uint256 indexed crateID, address indexed sender);
    event CrateContentsWithdrawn(
        uint256 indexed crateID,
        address indexed sender,
        uint256 indexed contentsID,
        uint256 randomSeed
    );
    event CrateBurned(
        uint256 indexed crateID,
        address indexed sender,
        uint256 withdrawBlockNumber
    );
    event CrateInitializationComplete(
        uint256 indexed crateID,
        uint256[] items,
        uint256[] supplies,
        uint256 totalCrates
    );
    event CratePauseToggled(bool paused);

    function initialize(address shibaDogeArmy) public initializer {
        SHIBADOGEARMY = IShibaDogeArmy(shibaDogeArmy);

        __Pausable_init();
        __Ownable2Step_init();
        __ReentrancyGuard_init();
    }

    struct NFTCrate {
        address contractAddress;
        uint256 tokenId;
    }

    struct TokenCrate {
        address contractAddress;
        uint256 tokenAmount;
    }

    mapping(uint256 => NFTCrate) public contentIDToERC721;
    mapping(uint256 => TokenCrate) public contentIDToERC20;

    event NFTCrateAdded(
        uint256 crateContentsId,
        address contractAddress,
        uint256 tokenId
    );
    event TokenCrateAdded(
        uint256 crateContentsId,
        address contractAddress,
        uint256 tokenAmount
    );

    event NFTCrateRemoved(uint256 crateContentsId);
    event TokenCrateRemoved(uint256 crateContentsId);

    function addNFTContentsId(
        uint256 crateContentsId,
        address contractAddress,
        uint256 tokenId
    ) external onlyOwner {
        contentIDToERC721[crateContentsId] = NFTCrate(contractAddress, tokenId);
        emit NFTCrateAdded(crateContentsId, contractAddress, tokenId);
    }

    function addTokenContentsId(
        uint256 crateContentsId,
        address contractAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        contentIDToERC20[crateContentsId] = TokenCrate(
            contractAddress,
            tokenAmount
        );
        emit TokenCrateAdded(crateContentsId, contractAddress, tokenAmount);
    }

    function removeNFTContentsId(uint256 crateContentsId) external onlyOwner {
        contentIDToERC721[crateContentsId] = NFTCrate(address(0), 0);
        emit NFTCrateRemoved(crateContentsId);
    }

    function removeTokenContentsId(uint256 crateContentsId) external onlyOwner {
        contentIDToERC20[crateContentsId] = TokenCrate(address(0), 0);
        emit TokenCrateRemoved(crateContentsId);
    }

    function viewCrateItems(
        uint256 crateId
    ) external view returns (uint256[] memory) {
        return crateItems[crateId];
    }

    function viewCrateItemSupplies(
        uint256 crateId
    ) external view returns (uint256[] memory) {
        return crateItemSupplies[crateId];
    }

    // crate id => user address => depositedBlockNumber;

    function initializeCrate(
        uint256 crateID,
        uint256[] calldata items,
        uint256[] calldata supplies,
        uint256 totalCrates
    ) external onlyOwner {
        crateInitialized[crateID] = true;
        crateItems[crateID] = items;
        crateItemSupplies[crateID] = supplies;
        sealedCrateCount[crateID] = totalCrates;
        emit CrateInitializationComplete(crateID, items, supplies, totalCrates);
    }

    function toggleCratePaused(uint256 id) external onlyOwner {
        cratePaused[id] = !cratePaused[id];
        emit CratePauseToggled(cratePaused[id]);
    }

    function depositLockedCrate(uint256 crateID) external {
        require(crateInitialized[crateID]);
        require(!cratePaused[crateID]);
        require(SHIBADOGEARMY.balanceOf(msg.sender, crateID) > 0);
        require(crateAddressDepositBlock[crateID][msg.sender] == 0); // must not have a crate waiting to be unlocked

        crateAddressDepositBlock[crateID][msg.sender] = block.number;
        SHIBADOGEARMY.depositLockedCrateFromManager(msg.sender, crateID);

        emit CrateDeposited(crateID, msg.sender);
    }

    // address CrateOpener;
    // function depositLockedCrateFromManager(address holder, uint256 crateId) onlyManager(CrateOpener) {
    //     _burn(msg.sender, crateID, 1);
    // }

    function withdrawUnlockedCrateContents(
        uint256 crateID,
        bytes calldata data
    ) external nonReentrant returns (uint256 crateContentId) {
        require(!cratePaused[crateID]);

        uint256 depositBlock = crateAddressDepositBlock[crateID][msg.sender];
        require(depositBlock != 0); // must have deposited a crate

        uint256 withdrawBlock = depositBlock + 5; // must wait 5 blocks
        require(withdrawBlock <= block.number);

        uint256 withdrawBlockHash = uint256(blockhash(withdrawBlock));

        uint256 crateContentsId;
        uint256 crateContentsIndex;
        uint256 randomSeed = 0;

        //If more than 256 blocks have passed, crate contents are the last available item in array
        if (withdrawBlockHash == 0) {
            // only the last 256 blockhashes are stored onchain, otherwise it's 0
            uint256[] memory FUCK = crateItems[crateID];
            crateContentsIndex = FUCK.length - 1;

            // give the user the item that is the last one in the array with a positive balance

            while (crateItemSupplies[crateID][crateContentsIndex] == 0) {
                crateContentsIndex = FUCK.length - 1;
            }

            crateContentsId = crateItems[crateID][crateContentsIndex];
        } else {
            // get randomseed
            randomSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        withdrawBlockHash,
                        msg.sender,
                        withdrawBlock
                    )
                )
            );

            // Get the item in the crate and its index for subtraction
            (crateContentsId, crateContentsIndex) = getCrateContents(
                crateID,
                randomSeed
            );

            // ensure that the crateContentsId is valid
            require(crateContentsId != 0, "contents not valid");
        }

        // remove that content from cratesupply

        sealedCrateCount[crateID] -= 1;
        crateItemSupplies[crateID][crateContentsIndex] -= 1;
        crateAddressDepositBlock[crateID][msg.sender] = 0;

        // code for handling erc20 and erc721

        if (contentIDToERC20[crateContentsId].contractAddress != address(0)) {
            // crate is a token
            IERC20(contentIDToERC20[crateContentsId].contractAddress).transfer(
                msg.sender,
                contentIDToERC20[crateContentsId].tokenAmount
            );
        } else if (
            contentIDToERC721[crateContentsId].contractAddress != address(0)
        ) {
            // crate is an NFT
            IERC721(contentIDToERC721[crateContentsId].contractAddress)
                .transferFrom(
                    address(this),
                    msg.sender,
                    contentIDToERC721[crateContentsId].tokenId
                );
        } else {
            // crate is an EFT
            SHIBADOGEARMY.crateContentMint(
                crateContentsId,
                1,
                msg.sender,
                data
            );
        }

        emit CrateContentsWithdrawn(
            crateID,
            msg.sender,
            crateContentsId,
            randomSeed
        );

        return crateContentsId;
    }

    function getCrateContents(
        uint256 crateID,
        uint256 randomseed
    )
        public
        view
        returns (uint256 crateContentsEftId, uint256 crateContentsIndex)
    {
        uint256 selectedCrateContents = 0;

        uint256 supplyCounter = 0;
        uint256 i;

        uint256 randomIndex = randomseed % sealedCrateCount[crateID];

        uint256 crateItemSupplyLength = crateItemSupplies[crateID].length;

        for (i = 0; i < crateItemSupplyLength;) {
            unchecked {
                if (crateItemSupplies[crateID][i] == 0){
                    continue;
                }

                supplyCounter += crateItemSupplies[crateID][i];

                // If item is within range of the counter, break the loop
                if (supplyCounter > randomIndex) {
                    break;
                }

                i++;
            }
        }

        selectedCrateContents = crateItems[crateID][i];

        return (selectedCrateContents, i);
    }

    function rescueEth() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueTokens(IERC20 _stuckToken) external onlyOwner {
        IERC20(_stuckToken).transfer(
            owner(),
            _stuckToken.balanceOf(address(this))
        );
    }
}
