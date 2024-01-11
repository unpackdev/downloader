// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./TierManager.sol";
import "./Agreement.sol";
import "./Greenlist.sol";

/**
 * @title ERC721 Cedar contract
 * @notice The contract supports preminting and distribution. It supports user terms and checks the greenlist status before transfer
 * @author Monax Labs
 */
contract ERC721CedarPremint is Ownable, ERC721A, ERC2981, TierManager, Agreement, Greenlist {
    using Address for address;
    using Strings for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 maxLimit;
    uint256 tokenId;
    uint64 maxMintPerBatch;
    uint64 preMintMaxPerBatch;
    string public baseURI;

    struct TransferRequest {
        address to;
        uint256 tokenId;
    }

    event TransferOwnership(address _address);
    event TokenMinted(uint256 tokenId, uint96 tierId, address receiver);
    event BaseURI(string baseURI);
    event MaxLimit(uint256 maxLimit);
    event PreMintMaxPerBatch(uint64 preMintMaxPerBatch);
    event Received(address sender, uint256 value);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxLimit,
        address _greenlistManagerAddress,
        address _signatureVerifier,
        string memory _userAgreement,
        string memory baseURI_
    ) ERC721A(_name, _symbol) Agreement(_userAgreement, _signatureVerifier) Greenlist(_greenlistManagerAddress) {
        maxLimit = _maxLimit;
        baseURI = baseURI_;
    }

    /// @notice batch mints tokens for a specified tier and transfer to Owner
    /// @dev This function mints 200 tokens per batch up to maxLimit. It sets the tier ID for the token ID and returns an array of the token IDs.
    function mintBatch(
        uint256 _quantity,
        uint96 _tierId,
        address _to
    ) external onlyOwner {
        require(_totalMinted() + _quantity <= maxLimit, "ERC721Cedar: max limit exceeded, reverting batch call");
        require(_tierId > 0 && _tierId <= totalTiers, "ERC721Cedar: tier ID does not exist");
        require(
            totalTokensPerTier[_tierId] + _quantity <= maxLimitPerTier[_tierId],
            "ERC721Cedar: Mint count exceeds tier token limit"
        );
        _mint(_to, _quantity, "", false);
        totalTokensPerTier[_tierId] += _quantity;
        uint256 id = tokenId;
        for (uint256 i; i < _quantity; i++) {
            _setTierForToken(id, _tierId);
            id++;
        }
        tokenId = id;
    }

    function transferFromBatch(TransferRequest[] calldata transferRequests) external onlyOwner {
        for (uint256 i; i < transferRequests.length; i++) {
            transferFrom(_msgSender(), transferRequests[i].to, transferRequests[i].tokenId);
        }
    }

    /// @dev this function takes an array of max limits and adds tier max limits
    function addTiersInfo(uint256[] calldata _maxLimitPerTier) external onlyOwner {
        _addTiersInfo(_maxLimitPerTier);
    }

    ///@dev this function updates the max limit per tier
    function updateTierInfoByTierId(uint96 _tierID, uint256 _maxLimitPerTier) external onlyOwner {
        _updateTierInfoByTierId(_tierID, _maxLimitPerTier);
    }

    /// @dev this function sets the max limit in the collection
    function setMaxLimit(uint256 _maxLimit) external onlyOwner {
        maxLimit = _maxLimit;
        emit MaxLimit(_maxLimit);
    }

    function setRoyalties(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteRoyalties() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
    @dev _beforeTokenTransfer
    Hook that is called before any token transfer. This includes minting and burning.

    Hook will check transfers after mint. 

    It checks whether the terms are activated, if yes check whether the caller is a contract. 
    If yes, check the greenlist and if the greenlist is activated, check whether the caller is an approved caller.

    If yes, check whether the Transferee has accepted the terms. 

    If terms are not activated, check the greenlist.
    */

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
        if (_to != owner()) {
            address caller = getCaller();
            if (termsActivated) {
                require(
                    termsAccepted[_to],
                    string(
                        abi.encodePacked(
                            "ERC721 Cedar: Receiver address has not accepted the collection's terms of use at ",
                            ownerDomain
                        )
                    )
                );
            }
            checkGreenlist(caller);
        }
    }

    /// @dev this function returns the address for the *direct* caller of this contract.
    function getCaller() internal view returns (address _caller) {
        assembly {
            _caller := caller()
        }
    }

    /// @notice upgrades the baseURI
    /// @dev this function upgrades the baseURI. All token metadata is stored in the baseURI as a JSON
    function upgradeBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev this function returns the baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice gets token URI
    /// @dev this function overrides the ERC721 tokenURI function. It returns the URI as `${baseURI}/${tokenId}`
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, "/", _tokenId.toString())) : "";
    }

    /* ========== VIEWS ========== */
    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
