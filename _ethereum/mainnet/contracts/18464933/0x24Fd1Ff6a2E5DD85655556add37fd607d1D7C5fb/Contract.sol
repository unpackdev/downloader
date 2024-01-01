// SPDX-License-Identifier: MIT



pragma solidity 0.8.19;

import "./ERC721AOpensea.sol";
import "./IWCNFTErrorCodes.sol";
import "./WCNFTMerkle.sol";
import "./WCNFTToken.sol";
import "./IDelegationRegistryExcerpt.sol";

contract sheepparade is
    IWCNFTErrorCodes,
    WCNFTMerkle,
    WCNFTToken,
    ERC721AOpensea
{
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 100;
    address private constant _DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    uint256 public pricePerToken = 0 ether;

    string public provenance;
    string private _baseURIExtended;

    mapping(address => uint256) public allowListMinted;

    address payable public immutable shareholderAddress;
    bool public saleActive;

    // *************************************************************************
    // CUSTOM ERRORS

    /// not accepting mints from contracts on public sale
    error NoContractMinting();

    /// caller is not delegated for requested vault wallet. See delegate.xyz.
    error NotDelegatedForAll();

    // *************************************************************************
    // EVENTS

    /**
     * @dev emit when a user mints on the public sale
     * @param userAddress the minting wallet and token recipient
     * @param numberOfTokens the quantity of tokens purchased
     */
    event Mint(address indexed userAddress, uint256 numberOfTokens);

    /**
     * @dev emit when a user claims tokens on the allow list
     * @param userAddress the minting wallet and token recipient
     * @param vault an address in the allow list if using delegation, 
     *  or 0x00..00
     * @param numberOfTokens the quantity of tokens claimed
     */
    event AllowListClaimMint(
        address indexed userAddress,
        address indexed vault,
        uint256 numberOfTokens
    );

    // *************************************************************************
    // MODIFIERS

    /**
     * @dev revert if this quantity of tokens would exceed the maximum supply
     * @param numberOfTokens the quantity of tokens requested
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        if (_totalMinted() + numberOfTokens > MAX_SUPPLY) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    // *************************************************************************
    // FUNCTIONS

    /**
     * @param shareholderAddress_ recipient for all ETH withdrawals
     */
    constructor(address payable shareholderAddress_)
        ERC721A("sheepparade", "SHEEPPARADE")
        ERC721AOpensea()
        WCNFTToken()
    {
        if (shareholderAddress_ == address(0)) revert ZeroAddressProvided();
        shareholderAddress = shareholderAddress_;
    }

    // *************************************************************************
    // CLAIM - Allowlist claim from snapshot

    /**
     * @notice claim tokens from your allow list quota.
     *  If the allowlist features a "cold" or "vault" wallet, delegate.xyz may
     *  be used to delegate a different wallet to make this claim, (e.g. a
     *  "hot wallet").
     *  If using delegation, ensure the hot wallet is delegated for the entire
     *  vault wallet by using 'delegate wallet' at delegate.xyz.
     *  NOTE delegate.xyz is an unaffiliated external service, use it at your
     *  own risk! Their docs are available at http://delegate.xyz
     *
     * @param vault if using delegate.xyz, the address that features in the
     *  allow list. Set this to 0x000..000 if not using delegation.
     * @param numberOfTokens the number of tokens to claim
     * @param tokenQuota the total quota of tokens for the claiming address
     * @param proof the Merkle proof for this claimer
     */
    function mintAllowList(
        address vault,
        uint256 numberOfTokens,
        uint256 tokenQuota,
        bytes32[] calldata proof
    )
        external
        payable
        isAllowListActive
        supplyAvailable(numberOfTokens)
    {
        // set address of the wallet that appears on the allow list
        address claimer = msg.sender;

        // check for delegation
        if (vault != address(0) && vault != msg.sender) {
            if (
                !IDelegationRegistry(_DELEGATION_REGISTRY)
                    .checkDelegateForAll(
                        msg.sender,
                        vault
                    )
            ) {
                // msg.sender is not delegated for vault
                revert NotDelegatedForAll();
            }

            // msg.sender is delegated for vault
            claimer = vault;
        }

        // check if the claimer has tokens remaining in their quota
        if (getAllowListMinted(claimer) + numberOfTokens > tokenQuota) {
            revert ExceedsAllowListQuota();
        }

        // check if the claimer is on the allow list
        if (!onAllowListC(claimer, tokenQuota, 69000000000000000000, proof)) {
            revert NotOnAllowList();
        }

        if (msg.value != numberOfTokens * pricePerToken) {
            revert WrongETHValueSent();
        }
        
        // claim tokens
        _setAllowListMinted(claimer, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens, "");
        emit AllowListClaimMint(msg.sender, vault, numberOfTokens);
    }

    // *************************************************************************
    // MINT - Public sale

    /**
     * @notice mint tokens on the public sale
     * @param numberOfTokens the quantity of tokens to mint
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        supplyAvailable(numberOfTokens)
    {
        if (!saleActive) revert PublicSaleIsNotActive();
        if (tx.origin != msg.sender) revert NoContractMinting();
        if (numberOfTokens > MAX_TOKENS_PER_PURCHASE) {
            revert ExceedsMaximumTokensPerTransaction();
        }
        if (msg.value != numberOfTokens * pricePerToken) {
            revert WrongETHValueSent();
        }
        
        _safeMint(msg.sender, numberOfTokens, "");
        emit Mint(msg.sender, numberOfTokens);
    }

    // *************************************************************************
    // DEV - Admin functions

    /**
     * @dev mint reserved tokens
     * @param to the recipient address
     * @param numberOfTokens the quantity of tokens to mint
     */
    function devMint(address to, uint256 numberOfTokens) 
        external
        supplyAvailable(numberOfTokens)
        onlyRole(SUPPORT_ROLE)
    {
        _safeMint(to, numberOfTokens);
    }

    /**
     * @notice start and stop the allow list sale
     * @param state true activates the sale, false de-activates it
     */
    function setAllowListActive(bool state)
        external
        override
        onlyRole(SUPPORT_ROLE)
    {
        if (merkleRoot == bytes32(0)) revert MerkleRootNotSet();

        _setAllowListActive(state);
    }

    /**
     * @notice set baseURI for the collection
     * @param newBaseURI the new baseURI
     */
    function setBaseURI(string calldata newBaseURI)
        external
        onlyRole(SUPPORT_ROLE)
    {
        _baseURIExtended = newBaseURI;
    }

    /**
     * @dev set the price per token
     * @param newPriceInWei the price per token in wei
     */
    function setPricePerToken(uint256 newPriceInWei)
        external
        onlyRole(SUPPORT_ROLE)
    {
        pricePerToken = newPriceInWei;
    }

    /**
     * @dev set the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string calldata provenance_)
        external
        onlyRole(SUPPORT_ROLE)
    {
        provenance = provenance_;
    }

    /**
     * @notice start and stop the public sale
     * @param state true activates the sale, false de-activates it
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    /**
     * @dev withdraw all funds
     */
    function withdraw() external onlyOwner {
        (bool success, ) = shareholderAddress.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }

    // *************************************************************************
    // OVERRIDES

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, WCNFTToken, ERC721AOpensea)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721A-_baseURI}
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}
