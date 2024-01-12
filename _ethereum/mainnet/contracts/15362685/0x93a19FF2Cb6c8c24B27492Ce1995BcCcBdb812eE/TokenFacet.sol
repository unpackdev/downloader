// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Context.sol";
import "./Base64.sol";
import "./ERC721Holder.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./IERC721A.sol";
import "./ERC721A.sol";
import "./AppStorage.sol";
import "./LibDiamond.sol";
import "./Constants.sol";
import "./IOpenseaSeaportConduitController.sol";
import "./console.sol";

contract TokenFacet is ERC721A, EIP712, ERC721Holder, Context {
    IOpenseaSeaportConduitController public constant OPENSEA_SEAPORT_CONDUIT_CONTROLLER =
        IOpenseaSeaportConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);
    address public constant OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    constructor() ERC721A(Constants.NAME, Constants.SYMBOL) EIP712(Constants.NAME, Constants.VERSION) {}

    // =================================
    // Minting
    // ================================
    modifier mintWhitelisting(bytes calldata signature) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(keccak256("Mask(address to,string contents)"), _msgSender(), keccak256(bytes(getState().description))))
        );
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(recoveredSigner == getState().whitelistingSignatureAddress, "TokenFacet: Whitelist signature fails");
        _;
    }

    modifier reducePublicPool(uint256 n) {
        // Determine whether the whitelist mint has reached the maximum
        require(n <= getState().publicPoolRemaining, "TokenFacet: The number of mints for the whitelist has reached its maximum");
        getState().publicPoolRemaining -= n;
        _;
    }

    function mintPublic(uint256 tokenCount, bytes calldata signature) external whenNotPaused reducePublicPool(tokenCount) mintWhitelisting(signature) {  
        // Determine if mint is enabled
        require(getState().wlMinting, "TokenFacet: Whitelist minting suspended");

        // To determine whether it has been mint, an address can only be minted once and a maximum of 9 coins can be minted at a time
        require(tokenCount <= Constants.MAX_MINT_PER_WALLET, "TokenFacet: The whitelist can mint up to 9 coins at a time");
        // Each account can only be minted once
        require(_numberMinted(_msgSender()) < 1, "TokenFacet: Each account can only be minted once");

        // If the user wants to mint more than 1 mask, the account needs to have sufficient balance
        if (tokenCount > 1) {
            uint256 minETHBalance = tokenCount * Constants.MIN_ETH_BALANCE;
            require(_msgSender().balance >= minETHBalance, "TokenFacet: Account balance does not support minting multiple masks");
        }

        _safeMint(_msgSender(), tokenCount);

        if (getState().publicPoolRemaining == 0) {
            LibDiamond.setContractOwner(address(0));
            getState().unmaskTimestamp = block.timestamp;
        }
    }


    // =================================
    // PROOF Minting
    // ================================
    /**
    @dev Used by both PROOF-holder and PROOF-admin minting from the pool. 
     */
    modifier reducePROOFPool(uint256 n) {
        require(n <= getState().proofPoolRemaining, "TokenFacet:  PROOF pool exhausted");
        getState().proofPoolRemaining -= n;
        _;
    }

    function mintPROOF(uint256[] calldata proofTokenIds) external reducePROOFPool(proofTokenIds.length) {
        require(getState().proofMinting, "TokenFacet: PROOF minting closed");
        
        for (uint256 i = 0; i < proofTokenIds.length; i++) {
            uint256 tokenId = proofTokenIds[i];
            require(!getState().proofTokenIdsUsed[tokenId], "TokenFacet: PROOF used");
            address owner = IERC721A(getState().proofToken).ownerOf(tokenId);
            require(owner == _msgSender(), "TokenFacet: PROOF owns this is not you");
        }
        _safeMint(_msgSender(), proofTokenIds.length);
    }

    /**
    @notice Mint unclaimed tokens from the PROOF-holder pool. 
     */
    function mintPROOFUnclaimed(address to, uint256 n) external reducePROOFPool(n) {
        if (LibDiamond.contractOwner() == address(0)) {
            to = getState().defaultMintPROOFAddress;
        }else {
            require(msg.sender == LibDiamond.contractOwner(), "LibDiamond: Must be contract owner");
        }
        _safeMint(to, n);
    }


    // =================================
    // ProjectParty Minting
    // =================================
    modifier reduceProjectPartyPool(uint256 n) {
        require(n <= getState().projectPartyPoolRemaining, "TokenFacet: ProjectParty pool exhausted");
        getState().projectPartyPoolRemaining -= n;
        _;
    }

    function mintProjectParty(uint256 n) external reduceProjectPartyPool(n) {
        require(n <= getState().projectPartyMintQuantity[_msgSender()], "TokenFacet: You have exceeded your mintable amount");
        _safeMint(_msgSender(), n);
        getState().projectPartyMintQuantity[_msgSender()] -= n;
    }

    function mintProjectPartyAfterDecentralization(uint256 n) external reduceProjectPartyPool(n) {
        require(LibDiamond.contractOwner() == address(0), "TokenFacet: This method cannot be used without relinquishing permissions");
        _safeMint(getState().defaultMintProjectPartyAddress, n);
    }
    

    function unmask(uint256[] calldata tokenIds) external {
        uint256 currentTimestamp = block.timestamp;
        require(getState().unmaskTimestamp != 0 && getState().unmaskTimestamp < currentTimestamp, "TokenFacet: It's not time to lift the mask");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address owner = IERC721A(address(this)).ownerOf(tokenIds[i]);
            require(owner == _msgSender(), "TokenFacet: You are not the owner of this mask");
            // Determine whether the mask has been uncovered
            bool isUnmask = getState().unmaskIds[tokenIds[i]];
            require(!isUnmask, "TokenFacet: The mask has been lifted");
        }
        
        uint256 maskElapsedTime = currentTimestamp - getState().unmaskTimestamp;
        if (maskElapsedTime < Constants.MASK_VALIDITY_TIME) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                getState().unmaskIds[tokenIds[i]] = true;    
            }
        } else {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 maskGetsTime = currentTimestamp - getState().maskLastTransactionTimestamp[tokenIds[i]];
                // If it is judged whether the last transaction time of this mask is more than 7 days away from now, it will prompt failure.
                require(maskGetsTime < Constants.MASK_VALIDITY_TIME, "TokenFacet: The mask has passed the reveal time");
                getState().unmaskIds[tokenIds[i]] = true;    
            }
        }
    }


    function _afterTokenTransfers(
        address ,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (to != address(0)) {
                getState().maskLastTransactionTimestamp[tokenId] = block.timestamp;
            } 
        }
    }


    // 获取合约信息
    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            '"name": ',
                            getState().name,
                            ", ",
                            '"description": ',
                            getState().description,
                            " ,",
                            '"image": "',
                            getState().contractLevelImageUrl,
                            '", ',
                            '"external_url": "',
                            getState().contractLevelExternalUrl,
                            '", ',
                            '"seller_fee_basis_points": ',
                            getState().royaltyBasisPoints,
                            ", ",
                            '"fee_recipient": "',
                            getState().royaltyWalletAddress,
                            '"',
                            "}"
                        )
                    )
                )
            );
    }

    /**
     * Override isApprovedForAll to whitelist Seaport's conduit contract to enable gas-less listings.
     */
    function isNFTApprovedForAll(address owner, address operator) external view returns (bool) {
        try OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(operator, OPENSEA_SEAPORT) returns (bool isOpen) {
            if (isOpen) {
                return true;
            }
        } catch {}

        return super.isApprovedForAll(owner, operator);
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }

    function getVersion() external view returns (string memory) {
        return getState().version;
    }

    function getDescription() external view returns (string memory) {
        return getState().description;
    }

    function getProjectPartyMintQuantity(address projectParty) external view returns (uint256) {
        return getState().projectPartyMintQuantity[projectParty];
    }

    function getProofPoolRemaining() external view returns (uint256) {
        return getState().proofPoolRemaining;
    }

    function getProjectPartyPoolRemaining() external view returns (uint256) {
        return getState().projectPartyPoolRemaining;
    }

    function getPublicPoolRemaining() external view returns (uint256) {
        return getState().publicPoolRemaining;
    }

    function uncovered(uint256 tokenId) external view returns (bool) {
        return getState().unmaskIds[tokenId];
    }

    // =================================
    // Config
    // =================================

    function setWlMinting(bool state) public onlyOwner {
        getState().wlMinting = state;
    }

    function setTokenBaseExternalUrl(string memory url) public onlyOwner {
        getState().tokenBaseExternalUrl = url;
    }

    function setContractLevelImageUrl(string memory url) public onlyOwner {
        getState().contractLevelImageUrl = url;
    }

    function setContractLevelExternalUrl(string memory url) public onlyOwner {
        getState().contractLevelExternalUrl = url;
    }

    function setWhitelistingSignatureAddress(address signatureAddress) public onlyOwner {
        getState().whitelistingSignatureAddress = signatureAddress;
    }

    function setProof(address proof) public onlyOwner {
        getState().proofToken = proof;
    }

    function setPROOFMintingOpen(bool open) public onlyOwner {
        getState().proofMinting = open;
    }

    function setProjectPartyMintQuantity(address projectParty, uint256 n) public onlyOwner {
        getState().projectPartyMintQuantity[projectParty] = n;
    }

    function setUnmaskTimestamp(uint256 unmaskTimestamp) public onlyOwner {
        getState().unmaskTimestamp = unmaskTimestamp;
    }

    function setDefaultMintPROOFAddress(address defaultMintPROOFAddress) public onlyOwner {
        getState().defaultMintPROOFAddress = defaultMintPROOFAddress;
    }

    function setDefaultMintProjectPartyAddress(address defaultMintProjectPartyAddress) public onlyOwner {
        getState().defaultMintProjectPartyAddress = defaultMintProjectPartyAddress;
    }

}
