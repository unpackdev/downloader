// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./IBrawlerBearzDynamicItems.sol";
import "./FxBaseRootTunnel.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**
 * @title BrawlerBearzBattlePassSeason4
 * @author @scottybmitch
 * @dev Battle pass public mint and L2 sync on mint, non-transferable, or sellable
 */
contract BrawlerBearzBattlePassSeason4 is
    FxBaseRootTunnel,
    ERC721AQueryable,
    ERC721ABurnable,
    Ownable
{
    using Strings for uint256;

    /// @dev Sync actions
    bytes32 public constant MINTED = keccak256("MINTED");

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    // @dev Base uri for the nft
    string private baseURI =
        "ipfs://bafybeielzvnm3axmc4fy5bd26ootdscrybbi6hezhu7gzristdroaxt4au/";

    /// @notice Pro battle pass tier
    uint256 constant PRO_PASS = 1;

    /// @notice Pro pass mint price
    uint256 public proPrice = 0.045 ether;

    /// @notice Pro battle pass tier
    uint256 constant ENTRY_PASS = 2;

    /// @notice Pro pass mint price
    uint256 public entryPrice = 0.01 ether;

    // @dev Treasury
    address public treasury =
        payable(0x39bfA2b4319581bc885A2d4b9F0C90C2e1c24B87);

    /*
     * @notice All mints live ~ December 2nd, 9AM EST
     * @dev Mints go live date
     */
    uint256 public liveAt = 1701525600;

    /*
     * @notice All mints expired
     * @dev Mints expire at
     */
    uint256 public expiresAt = 1702746000;

    /// @notice Mapping of token id to the pass type
    mapping(uint256 => uint256) private tokenIdToPassType;

    /// @dev Thrown on approval
    error CannotApproveAll();

    /// @dev Thrown on transfer
    error Nontransferable();

    modifier mintIsActive() {
        require(
            block.timestamp > liveAt && block.timestamp < expiresAt,
            "Minting is not active."
        );
        _;
    }

    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _vendorContractAddress
    )
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
        ERC721A("Brawler Bearz Battle Pass: S4", "BBBPS4")
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Pro pass mints
     * @param _amount The amount of passes to mint
     **/
    function proPassMint(uint256 _amount) external payable mintIsActive {
        require(msg.value >= _amount * proPrice, "Not enough funds.");
        address to = _msgSender();

        // Mint a supply crate per mint
        uint256[] memory itemIds = new uint256[](_amount);
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 nextTokenId = _nextTokenId();

        for (uint256 i; i < _amount; ) {
            itemIds[i] = 364; // https://opensea.io/assets/ethereum/0xbd24a76f4135f930f5c49f6c30e0e30a61b97537/364
            tokenIds[i] = nextTokenId + i;
            tokenIdToPassType[nextTokenId + i] = PRO_PASS; // Set pass type
            unchecked {
                ++i;
            }
        }

        vendorContract.dropItems(to, itemIds);

        // Mint passes
        _mint(to, _amount);

        // Sync w/ child
        _sendMessageToChild(
            abi.encode(MINTED, abi.encode(to, PRO_PASS, tokenIds))
        );
    }

    /**
     * @notice Entry pass mints
     * @param _amount The amount of passes to mint
     **/
    function entryPassMint(uint256 _amount) external payable mintIsActive {
        require(msg.value >= _amount * entryPrice, "Not enough funds.");
        address to = _msgSender();

        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 nextTokenId = _nextTokenId();

        for (uint256 i; i < _amount; ) {
            tokenIds[i] = nextTokenId + i;
            tokenIdToPassType[nextTokenId + i] = ENTRY_PASS;
            unchecked {
                ++i;
            }
        }

        // Mint passes
        _mint(to, _amount);

        // Sync w/ child
        _sendMessageToChild(
            abi.encode(MINTED, abi.encode(to, ENTRY_PASS, tokenIds))
        );
    }

    /**
     * @notice Returns the URI for a given token id
     * @param _tokenId A tokenId
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(tokenIdToPassType[_tokenId])
                )
            );
    }

    // @dev Check if mint is live
    function isLive() public view returns (bool) {
        return block.timestamp > liveAt && block.timestamp < expiresAt;
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Sets entries price
     * @param _entryPrice A base uri
     */
    function setEntryPrice(uint256 _entryPrice) external onlyOwner {
        entryPrice = _entryPrice;
    }

    /**
     * @notice Sets pro price
     * @param _proPrice A base uri
     */
    function setProPrice(uint256 _proPrice) external onlyOwner {
        proPrice = _proPrice;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param _baseURI A base uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Treasury mints
     * @param _amount The amount of passes to mint to the treasury wallet
     **/
    function treasuryMint(uint256 _amount) external onlyOwner {
        _mint(treasury, _amount);
    }

    /**
     * @notice Sets timestamps for live and expires timeframe
     * @param _liveAt A unix timestamp for live date
     * @param _expiresAt A unix timestamp for expiration date
     */
    function setMintWindow(
        uint256 _liveAt,
        uint256 _expiresAt
    ) external onlyOwner {
        liveAt = _liveAt;
        expiresAt = _expiresAt;
    }

    /**
     * @notice Sets the treasury recipient
     * @param _treasury The treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * Set FxChildTunnel
     * @param _fxChildTunnel - the fxChildTunnel address
     */
    function setFxChildTunnel(
        address _fxChildTunnel
    ) public override onlyOwner {
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContractAddress(
        address _vendorContractAddress
    ) external onlyOwner {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /// @notice Withdraws funds from contract
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "999");
    }

    /// @dev Prevent approvals of token outside of the treasury wallet
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (_msgSenderERC721A() != treasury) {
            revert CannotApproveAll();
        }
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Prevent token transfer unless burning
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        // Treasury is allowed to sell passes
        if (from == treasury) {
            // If the item is coming from the treasury, we process as if it were a processing a pro pass mint
            uint256[] memory itemIds = new uint256[](quantity);
            uint256[] memory tokenIds = new uint256[](quantity);
            uint256 nextTokenId = startTokenId;

            for (uint256 i; i < quantity; ) {
                itemIds[i] = 364; // https://opensea.io/assets/ethereum/0xbd24a76f4135f930f5c49f6c30e0e30a61b97537/364
                tokenIds[i] = nextTokenId + i;
                tokenIdToPassType[nextTokenId + i] = PRO_PASS;
                unchecked {
                    ++i;
                }
            }

            // Mint a supply crate per mint
            vendorContract.dropItems(to, itemIds);

            // Sync w/ child
            _sendMessageToChild(
                abi.encode(MINTED, abi.encode(to, PRO_PASS, tokenIds))
            );
        } else if (to != address(0) && from != address(0)) {
            // Cannot transfer otherwise, soul bound
            revert Nontransferable();
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // noop
    }
}
