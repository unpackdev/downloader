// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import "./ERC1155.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./Helper.sol";
import "./MintVoucher.sol";
import "./CloneableNFT.sol";

contract FrozenERC1155 is ERC1155, ERC2981, MintVoucherContract, CloneableNFT {
    mapping(uint256 => TokenDetails) public tokenDetails;
    struct TokenDetails {
        uint128 tokenMaxSupply;
        uint128 tokenCurrentSupply;
        string uri;
    }

    constructor() ERC1155("") CloneableNFT() {}

    /**********************************************************************************************************
    EXTERNAL
    **********************************************************************************************************/
    function initialize(
        address admin,
        address owner_,
        address signer,
        uint128 maxSupply_,
        bool soulBound_,
        string memory name_,
        string memory symbol_,
        string memory baseContractURI_
    ) external initializer {
        _initialize(admin, owner_, signer, maxSupply_, soulBound_, name_, symbol_, "", baseContractURI_);
    }

    /**
     * @dev Create an ERC1155 token with a max supply
     * @dev The contract owner can mint tokens on demand up to the max supply
     */
    function createForAdminMint(
        uint256 tokenId_,
        uint256 tokenInitialSupply_,
        uint256 tokenMaxSupply_,
        string memory uri_
    ) external adminOrOwnerOnly {
        if (currentSupply + 1 > maxSupply) {
            revert CommonError.ValueExceedsMaxSupply();
        }
        if (tokenMaxSupply_ == 0) {
            revert CommonError.ValueCannotBeZero();
        }
        if (isCreated(tokenId_)) {
            revert CommonError.TokenAlreadyExists();
        }
        if (tokenInitialSupply_ > tokenMaxSupply_) {
            revert CommonError.ValueExceedsMaxSupply();
        }
        tokenDetails[tokenId_].uri = uri_;
        emit PermanentURI(uri_, tokenId_);

        currentSupply++;
        tokenDetails[tokenId_].tokenMaxSupply = uint128(tokenMaxSupply_);

        if (tokenInitialSupply_ > 0) {
            tokenDetails[tokenId_].tokenCurrentSupply += uint128(tokenInitialSupply_);
            _mint(msg.sender, tokenId_, tokenInitialSupply_, hex"");
        }
    }

    /**
     * @dev Mint an NFT with a valid MintVoucher and signature
     * @param voucher The MintVoucher that contains the specific mint details
     * @param signature The signature that must originate from an authorized signer
     */
    function mintWithVoucher(MintVoucher calldata voucher, bytes calldata signature) external payable {
        if (
            tokenDetails[voucher.tokenId].tokenCurrentSupply + voucher.quantity >
            tokenDetails[voucher.tokenId].tokenMaxSupply
        ) {
            revert CommonError.ValueExceedsMaxSupply();
        }
        tokenDetails[voucher.tokenId].tokenCurrentSupply += uint128(voucher.quantity);
        _mintWithVoucher(voucher, signature);
    }

    /**
     * @dev Mint an NFT with amount by an admin or contract owner
     * @param to The address to send the NFT tokens to
     * @param tokenId The ID of the NFT token
     * @param amount The amount of NFT tokens to mint
     */
    function adminMint(address to, uint256 tokenId, uint256 amount) external adminOrOwnerOnly {
        if (tokenDetails[tokenId].tokenCurrentSupply + amount > tokenDetails[tokenId].tokenMaxSupply) {
            revert CommonError.ValueExceedsMaxSupply();
        }
        tokenDetails[tokenId].tokenCurrentSupply += uint128(amount);
        _mint(to, tokenId, amount, hex"");
    }

    /**
     * @dev Burn an amount of NFTs by the contract owner or the token owner
     * @param account The address of the contract owner or token owner
     * @param tokenId The ID of the NFT token to burn
     * @param amount The amount of NFT tokens to burn
     */
    function burn(address account, uint256 tokenId, uint128 amount) external {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert CommonError.NotApprovedNorOwner();
        }
        tokenDetails[tokenId].tokenCurrentSupply -= amount;
        _burn(account, tokenId, amount);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external adminOrOwnerOnly {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external adminOrOwnerOnly {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external adminOrOwnerOnly {
        _resetTokenRoyalty(tokenId);
    }

    function setContractURI(string memory contractURI_) external adminOrOwnerOnly {
        emit ContractURIUpdated(contractURI, contractURI_);
        contractURI = contractURI_;
    }

    /**********************************************************************************************************
    PUBLIC
    **********************************************************************************************************/
    // Override to return initialized values
    function name() public view returns (string memory) {
        return _tokenName;
    }

    // Override to return initialized values
    function symbol() public view returns (string memory) {
        return _tokenSymbol;
    }

    /**
     * @dev Set max token supply of the NFT collection
     * @param maxSupply_ The max token supply of the NFT collection
     */
    function setMaxSupply(uint128 maxSupply_) public adminOrOwnerOnly {
        if (maxSupply_ > maxSupply) {
            revert CommonError.CannotIncreaseMaxSupply();
        }
        if (maxSupply_ == maxSupply) {
            return;
        }
        if (maxSupply_ < currentSupply) {
            revert CommonError.ValueBelowCurrentSupply();
        }
        emit MaxSupplyUpdated(maxSupply, maxSupply_);
        maxSupply = maxSupply_;
    }

    /**
     * @dev Set max supply for a token ID
     * @param tokenId the ID of the NFT token
     * @param tokenMaxSupply_ The max supply of the NFT token
     */
    function setMaxSupplyPerToken(uint256 tokenId, uint128 tokenMaxSupply_) public adminOrOwnerOnly {
        if (!isCreated(tokenId)) {
            revert CommonError.TokenNonExistent();
        }
        if (tokenMaxSupply_ > tokenDetails[tokenId].tokenMaxSupply) {
            revert CommonError.CannotIncreaseMaxSupply();
        }
        if (tokenMaxSupply_ == tokenDetails[tokenId].tokenMaxSupply) {
            return;
        }
        if (tokenMaxSupply_ < tokenDetails[tokenId].tokenCurrentSupply) {
            revert CommonError.ValueBelowCurrentSupply();
        }
        emit TokenMaxSupplyUpdated(tokenId, tokenDetails[tokenId].tokenMaxSupply, tokenMaxSupply_);
        tokenDetails[tokenId].tokenMaxSupply = tokenMaxSupply_;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!isCreated(tokenId)) {
            revert CommonError.TokenNonExistent();
        }
        return tokenDetails[tokenId].uri;
    }

    function isCreated(uint256 tokenId) public view returns (bool) {
        return tokenDetails[tokenId].tokenMaxSupply != 0;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override isTransferAllowed {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override isTransferAllowed {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override isTransferAllowed {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function getTokenSupply(uint256 tokenId) public view returns (uint256, uint256) {
        return (uint256(tokenDetails[tokenId].tokenCurrentSupply), uint256(tokenDetails[tokenId].tokenMaxSupply));
    }

    /**********************************************************************************************************
    INTERNAL
    **********************************************************************************************************/

    /**
     * @dev Caller inside _mintWithVoucher function
     * @param to The address to send the NFT token to
     * @param voucher The MintVoucher that contains the specific mint details
     */
    function _handleMint(address to, MintVoucher calldata voucher) internal override {
        _mint(to, voucher.tokenId, voucher.quantity, hex"");
    }
}
