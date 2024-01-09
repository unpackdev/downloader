//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleWithRoyalties.sol";

import "./SignedAllowance.sol";

import "./VisualMassageErrors.sol";

/// @title VisualMassageModule
/// @author Simon Fremaux (@dievardump)
contract VisualMassageModule is
    Ownable,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties,
    SignedAllowance
{
    using Strings for uint256;

    event CollectActiveChanged(bool isActive);
    event CurrentHelixChanged(uint256 helix);
    event HelixChanged(uint256 helix);
    event Claimed(bytes signature);

    struct Helix {
        uint16 startId;
        uint16 endId;
        address signer; // if this helix needs a signer to be able to collect
        uint256 price;
    }

    /// @notice baseURI containing all metadata files
    string public baseURI;

    /// @notice the contract containing the NFTs
    address public nftContract;

    /// @notice if the collect of nfts is active or not
    bool public collectActive;

    /// @notice the current helix to mint from
    uint256 public currentHelixId;

    /// @notice all helixes
    mapping(uint256 => Helix) public helixes;

    /// @notice overrides a tokenURI
    mapping(uint256 => string) public tokenURIOverride;

    /// @notice keep track of minted elements
    mapping(uint256 => bool) public minted;

    /// @notice constructor
    /// @param contractURI_ The module URI (containing its metadata) - can be empty ''
    /// @param baseURI_ the baseURI containing the tokens metadata
    /// @param signer the signer for phase 0
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    constructor(
        string memory contractURI_,
        string memory baseURI_,
        address signer,
        address owner_
    ) NFBaseModule(contractURI_) {
        if (bytes(baseURI_).length == 0) {
            revert ConfigError({where: "baseURI"});
        }

        if (signer == address(0)) {
            revert ConfigError({where: "signer"});
        }

        // phase 0 is a private event for contributors & previous holders & H
        // only people with a valid signature can claim
        configureHelix(0, 1, 299, 0, signer);

        // phases 1 to 3
        configureHelix(1, 1, 100, 1 ether, address(0));
        configureHelix(2, 101, 200, 2 ether, address(0));
        configureHelix(3, 201, 300, 3 ether, address(0));

        baseURI = baseURI_;

        if (address(0) != owner_) {
            transferOwnership(owner_);
        }

        emit CurrentHelixChanged(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(msg.sender, tokenId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256)
        public
        view
        override
        returns (address receiver, uint256 basisPoint)
    {
        receiver = owner();
        basisPoint = 1000;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(msg.sender, tokenId);
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        // some tokens, for reasons, might have a specific URI.
        string memory tokenURIOverride_ = tokenURIOverride[tokenId];
        if (bytes(tokenURIOverride_).length > 0) {
            return tokenURIOverride_;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /// @notice Helper to calculate the nonce to sign for a given tuple (helix, nonce)
    /// @param helixId the helix id
    /// @param nonce the nonce for this signature
    /// @return the nonce to sign
    function nonceForHelix(uint256 helixId, uint256 nonce)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(helixId, nonce)));
    }

    /// @notice Returns a token id price to collect (reverts if token id not in current helix or already collected)
    /// @param tokenId to check price for
    /// @return the price for the token id in this helix
    function getPrice(uint256 tokenId) external view returns (uint256) {
        uint256 helixId = currentHelixId;
        Helix memory helix = helixes[helixId];

        // verify helix tokenId
        if (tokenId < helix.startId || tokenId > helix.endId) {
            revert WrongHelix();
        }

        if (minted[tokenId]) revert AlreadyCollected();

        // this means the token does not exist, so it's up to collect
        return helix.price;
    }

    /// @notice getter for recipients & their shares
    /// @return recipients the recipients
    /// @return shares their shares
    function getSplit()
        public
        view
        returns (address[] memory recipients, uint256[] memory shares)
    {
        recipients = new address[](4);
        recipients[0] = address(0xA22Dff3bB28C224b6e5F4421d55997656eE34CeA);
        recipients[1] = address(0x20224C07d1Baab220d7ef859312789C34c444DA4);
        recipients[2] = address(0xeaf03CD48f9B6B5B9C776c1517ff5fdB958dc94e);
        recipients[3] = owner();

        uint256 value = address(this).balance;
        shares = new uint256[](4);
        shares[0] = (value * 3) / 100;
        shares[1] = (value * 5) / 100;
        shares[2] = (value * 15) / 100;
        shares[3] = value - shares[0] - shares[1] - shares[2];
    }

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    /// @inheritdoc	INFModule
    function onAttach()
        external
        virtual
        override(INFModule, NFBaseModule)
        returns (bool)
    {
        // only allows attachment if nftContract is not set
        // this saves one tx
        if (nftContract == address(0)) {
            nftContract = msg.sender;
            return true;
        }

        return false;
    }

    ////////////////////////////////////////////////////
    ///// Collect                                     //
    ////////////////////////////////////////////////////

    /// @notice collect tokenId
    /// @param tokenId the token to buy
    function collect(uint16 tokenId) external payable {
        if (!collectActive) revert CollectInactive();

        uint256 helixId = currentHelixId;
        Helix memory helix = helixes[helixId];

        // no signer allowed here
        if (helix.signer != address(0)) revert PrivateEventOnly();

        _collect(helix, tokenId, msg.sender);
    }

    /// @notice Collect with a signature (ie: private sales)
    /// @param tokenId the tokenId to collect
    /// @param nonce a simple nonce, allowing multiple claims for one address
    /// @param signature the signature from helixes[currentHelixId].signer
    function collectWithSignature(
        uint16 tokenId,
        uint256 nonce,
        bytes memory signature
    ) external payable {
        if (!collectActive) revert CollectInactive();

        uint256 helixId = currentHelixId;
        Helix memory helix = helixes[helixId];

        // need signer here
        if (helix.signer == address(0)) revert NotClaimable();

        // create a unique nonce using nonce and helixId
        // this can allow one address to claim more than one per helix
        // if they get more signed messages
        uint256 _nonce = nonceForHelix(helixId, nonce);

        // verifies that (msg.sender, (nonce, helix), address(this)) was signed
        // by helix.signer
        bytes32 message = _validateSignature(
            msg.sender,
            _nonce,
            signature,
            helix.signer
        );
        usedAllowances[message] = true;

        _collect(helix, tokenId, msg.sender);

        emit Claimed(signature);
    }

    ////////////////////////////////////////////////////
    ///// Only owner                                  //
    ////////////////////////////////////////////////////

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        (address[] memory recipients, uint256[] memory shares) = getSplit();
        uint256 length = recipients.length;
        for (uint256 i; i < length; i++) {
            (bool success, ) = recipients[i].call{value: shares[i]}("");
        }
    }

    /// @notice Allows the owner of the contract to gift tokenId to recipient
    /// @param tokenId the tokenId to mint
    /// @param recipient the recipient to mint to
    function gift(uint16 tokenId, address recipient) external onlyOwner {
        // create a dummy helix for owner to gift whatever they want
        Helix memory helix = Helix({
            startId: 1,
            endId: 300,
            signer: address(0),
            price: 0
        });

        _collect(helix, tokenId, recipient);
    }

    /// @notice sets new base uri
    /// @param newBaseURI the new base uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice sets nft contract
    /// @param nftContract_ the contract containing nft
    function setNFTContract(address nftContract_) external onlyOwner {
        nftContract = nftContract_;
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        _setContractURI(newURI);
    }

    /// @notice override a tokenURI. For reasons.
    /// @param tokenId tokenId
    /// @param newTokenURI the new token uri
    function overrideTokenURI(uint256 tokenId, string memory newTokenURI)
        external
        onlyOwner
    {
        tokenURIOverride[tokenId] = newTokenURI;
    }

    /// @notice sets new helix
    /// @param newHelix the new helix to mint from
    function setCurrentHelix(uint256 newHelix) external onlyOwner {
        if (helixes[newHelix].endId == 0) {
            revert HelixNotConfigured();
        }

        currentHelixId = newHelix;
        emit CurrentHelixChanged(newHelix);
    }

    /// @notice sets collect active
    /// @param isActive the new state (active or not)
    function setCollectActive(bool isActive) external onlyOwner {
        collectActive = isActive;
        emit CollectActiveChanged(isActive);
    }

    /// @notice Configure an helix
    /// @param helixId the helix to configure
    /// @param startId the lowest token id to collect when this helix is active
    /// @param endId the highest id to collect when this helix is active
    /// @param price the price of collect for this helix
    /// @param signer the signer address (for private sale helixes)
    function configureHelix(
        uint256 helixId,
        uint16 startId,
        uint16 endId,
        uint256 price,
        address signer
    ) public onlyOwner {
        helixes[helixId] = Helix({
            startId: startId,
            endId: endId,
            price: price,
            signer: signer
        });

        emit HelixChanged(helixId);
    }

    /// @notice Allows to change startId and endId of an helix
    /// @param helixId the helix to configure
    /// @param startId the lowest token id to collect when this helix is active
    /// @param endId the highest id to collect when this helix is active
    function setHelixIds(
        uint256 helixId,
        uint16 startId,
        uint16 endId
    ) external onlyOwner {
        if (startId > endId || endId == 0) {
            revert ErrorInIds();
        }

        Helix storage helix = helixes[helixId];
        if (helix.endId == 0) {
            revert HelixNotConfigured();
        }

        helix.startId = startId;
        helix.endId = endId;
        emit HelixChanged(helixId);
    }

    /// @notice Allows to change the price for an helix
    /// @param helixId the helix to configure
    /// @param price the price
    function setHelixPrice(uint256 helixId, uint256 price) external onlyOwner {
        Helix storage helix = helixes[helixId];
        if (helix.endId == 0) {
            revert HelixNotConfigured();
        }

        helix.price = price;
        emit HelixChanged(helixId);
    }

    /// @notice Allows to change the signer for an helix
    /// @param helixId the helix to configure
    /// @param signer the signer address
    function setHelixSigner(uint256 helixId, address signer)
        external
        onlyOwner
    {
        Helix storage helix = helixes[helixId];
        if (helix.endId == 0) {
            revert HelixNotConfigured();
        }

        helix.signer = signer;
        emit HelixChanged(helixId);
    }

    ////////////////////////////////////////////////////
    ///// Internal                                    //
    ////////////////////////////////////////////////////

    /// @dev used to collect
    function _collect(
        Helix memory helix,
        uint16 tokenId,
        address recipient
    ) internal {
        // verify helix tokenId
        if (tokenId < helix.startId || tokenId > helix.endId) {
            revert WrongHelix();
        }

        // verify helix price
        if (msg.value != helix.price) {
            revert WrongValue();
        }

        if (minted[tokenId]) revert AlreadyCollected();
        minted[tokenId] = true;

        // mint tokenId
        INiftyForge721(nftContract).mint(
            recipient,
            "",
            uint256(tokenId),
            address(0),
            0,
            address(0)
        );
    }
}
