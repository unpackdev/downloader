// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./ERC1155Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

contract NTR is
    ERC1155Upgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ContextMixin
{
    address internal proxyRegistryAddress;
    string internal _contractURI;
    string internal _uriBase;

    uint8 private QUOTA_BIT;
    uint256 private QUOTA_LIMIT;

    enum MintMode {
        NOTOPEN,
        FREE,
        PAID
    }

    struct Token {
        // In the following, users mean those in the whitelist
        bool isInitialized; // Whether this type of token is created (false before creation)
        uint32 tokenSupply; // The upper limit of minted tokens
        uint32 numIssuedToken; // The number of currently minted tokens
        uint32 numPossibleHolder; // How many address may be holding this type of token
        uint256 mintFee; // How much the users need to pay for each token (in PAID Mode)
        mapping(uint256 => address) possibleHolder; // The addresses that have ever hold the tokens
    }
    mapping(uint256 => Token) private _token;

    struct Whitelist {
        MintMode mintMode; // Whether users can whitelistMint (if startMintTime is past) and whether they need to pay
        uint32 defaultFreeQuota; // The quota for tokens minted for free (in FREE mode)
        uint32 defaultPaidQuota; // The quota for tokens minted with mintFee (in PAID mode)
        uint256 startMintTime; // When the users can start whitelistMint
        bytes32 whitelistRoot; // The Merkle root of the whitelist
        mapping(address => uint32) compactQuota; // The remaining (free & paid) quota for users who have ever minted
    }

    Whitelist private _whitelist;

    function initialize(string memory uri_) public initializer {
        __ERC1155_init(uri_);
        __Ownable_init();

        proxyRegistryAddress = address(
            0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101
        );
        _contractURI = uri_;
        _uriBase = uri_;

        QUOTA_BIT = 15;
        QUOTA_LIMIT = 1 << QUOTA_BIT;

        _whitelist.mintMode = MintMode.NOTOPEN;
        _setDefaultRoyalty(_msgSender(),0); // default 0% royalty
    }

    function renounceOwnership() public virtual override onlyOwner {
        require(false, "renounceOwnership is disabled");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _genQuotaUsedFreePaid(
        bool usedFree,
        bool usedPaid,
        uint32 freeQuota,
        uint32 paidQuota
    ) private view returns (uint32) {
        uint32 passFilter = ((uint32(1) << QUOTA_BIT) - 1);
        return
            ((usedFree ? uint32(1) : 0) << 31) |
            ((usedPaid ? uint32(1) : 0) << 30) |
            ((freeQuota & passFilter) << QUOTA_BIT) |
            (paidQuota & passFilter);
    }

    function _readQuotaUsedFreePaid(address account)
        private
        view
        returns (
            bool,
            bool,
            uint32,
            uint32
        )
    {
        uint32 passFilter = ((uint32(1) << QUOTA_BIT) - 1);
        uint32 compact = _whitelist.compactQuota[account];
        bool usedFree = ((compact >> 31) & 1) > 0;
        bool usedPaid = ((compact >> 30) & 1) > 0;
        uint32 freeQuota = uint32((compact >> QUOTA_BIT) & passFilter);
        uint32 paidQuota = uint32(compact & passFilter);
        if (usedFree == false) {
            freeQuota = _whitelist.defaultFreeQuota;
        }
        if (usedPaid == false) {
            paidQuota = _whitelist.defaultPaidQuota;
        }
        return (usedFree, usedPaid, freeQuota, paidQuota);
    }

    function readFreeQuota(address account)
        public
        view
        returns (uint32)
    {
        (, , uint32 res, ) = _readQuotaUsedFreePaid(account);
        return res;
    }

    function readPaidQuota(address account)
        public
        view
        returns (uint32)
    {
        (, , , uint32 res) = _readQuotaUsedFreePaid(account);
        return res;
    }

    function _setURI(string memory newuri) internal virtual override {
        _uriBase = newuri;
    }

    function setURI(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_token[tokenId].isInitialized == true, "Token Not Initialized");
        return
            string(
                abi.encodePacked(
                    _uriBase,
                    StringsUpgradeable.toString(tokenId),
                    ".json"
                )
            );
    }

    function createTokenType(
        uint256 tokenId,
        uint32 tokenSupply,
        uint256 mintFee
    ) external onlyOwner {
        require(_token[tokenId].isInitialized == false, "Used tokenId");
        Token storage currToken = _token[tokenId];
        currToken.isInitialized = true;
        currToken.numIssuedToken = 0;
        currToken.numPossibleHolder = 0;
        currToken.tokenSupply = tokenSupply;
        currToken.mintFee = mintFee;
    }

    function setWhitelistParam(
        bytes32 whitelistRoot,
        MintMode mintMode,
        uint256 startMintTime,
        uint32 defaultFreeQuota,
        uint32 defaultMintQuota
    ) external onlyOwner {
        require(defaultFreeQuota < QUOTA_LIMIT, "Exceed Quota Limit");
        require(defaultMintQuota < QUOTA_LIMIT, "Exceed Quota Limit");

        _whitelist.whitelistRoot = whitelistRoot;
        _whitelist.mintMode = mintMode;
        _whitelist.startMintTime = startMintTime;
        _whitelist.defaultFreeQuota = defaultFreeQuota;
        _whitelist.defaultPaidQuota = defaultMintQuota;
    }

    function batchUpdateMintQuota(
        address[] calldata accounts,
        uint32[] calldata freeQuotas,
        uint32[] calldata paidQuotas
    ) external onlyOwner {
        require(
            accounts.length == freeQuotas.length,
            "accounts and freeQuotas should have the same length"
        );
        require(
            paidQuotas.length == freeQuotas.length,
            "paidQuotas and freeQuotas should have the same length"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            address thisAccount = accounts[i];
            uint32 thisFree = freeQuotas[i];
            uint32 thisPaid = paidQuotas[i];
            require(thisFree < QUOTA_LIMIT, "Exceed Quota Limit");
            require(thisPaid < QUOTA_LIMIT, "Exceed Quota Limit");
            uint32 newCompact = _genQuotaUsedFreePaid(
                true,
                true,
                thisFree,
                thisPaid
            );
            if (_whitelist.compactQuota[thisAccount] != newCompact) {
                _whitelist.compactQuota[thisAccount] = newCompact;
            }
        }
    }

    function closeMint() external onlyOwner {
        _whitelist.mintMode = MintMode.NOTOPEN;
    }

    function _leaf(uint256 id, address addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, addr));
    }

    function _commonMint(
        uint256 tokenId,
        uint32 mintAmount,
        address to
    ) internal {
        require(
            SafeMathUpgradeable.add(
                mintAmount,
                _token[tokenId].numIssuedToken
            ) <= _token[tokenId].tokenSupply,
            "Minting amount exceeds tokenSupply"
        );

        _mint(to, tokenId, mintAmount, new bytes(0));
        _token[tokenId].numIssuedToken = SafeCastUpgradeable.toUint32(
            SafeMathUpgradeable.add(_token[tokenId].numIssuedToken, mintAmount)
        );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            uint32 id = uint32(ids[i]);
            if (balanceOf(to, id) == 0) {
                _token[id].possibleHolder[_token[id].numPossibleHolder] = to;
                _token[id].numPossibleHolder += 1;
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function whitelistMint(
        bytes32[] memory whitelistProof,
        uint256 tokenId,
        uint32 userId,
        uint32 mintAmount
    ) external payable {
        require(
            _whitelist.mintMode == MintMode.FREE ||
                _whitelist.mintMode == MintMode.PAID,
            "This token is not allowed to mint now"
        );
        require(
            block.timestamp >= _whitelist.startMintTime,
            "Please wait until start minting time"
        );
        require(
            MerkleProofUpgradeable.verify(
                whitelistProof,
                _whitelist.whitelistRoot,
                _leaf(uint256(userId), _msgSender())
            ),
            "Invalid merkle proof"
        );
        require(mintAmount > 0, "You are expected to mint something");

        (
            bool usedFree,
            bool usedPaid,
            uint32 tmpFreeQuota,
            uint32 tmpPaidQuota
        ) = _readQuotaUsedFreePaid(_msgSender());

        if (_whitelist.mintMode == MintMode.FREE) {
            usedFree = usedFree || (mintAmount > 0);
            require(mintAmount <= tmpFreeQuota, "Exceeding Free Quota");
            _commonMint(tokenId, mintAmount, _msgSender());
            tmpFreeQuota -= mintAmount;
        }

        if (_whitelist.mintMode == MintMode.PAID) {
            usedPaid = usedPaid || (mintAmount > 0);
            require(mintAmount <= tmpPaidQuota, "Exceeding Paid Quota");
            require(
                msg.value >= uint256(mintAmount) * _token[tokenId].mintFee,
                "User needs to pay more to use the paid mint quota"
            );
            _commonMint(tokenId, mintAmount, _msgSender());
            tmpPaidQuota -= mintAmount;
        }

        uint32 newCompact = _genQuotaUsedFreePaid(
            usedFree,
            usedPaid,
            tmpFreeQuota,
            tmpPaidQuota
        );
        _whitelist.compactQuota[_msgSender()] = newCompact;
    }

    function ownerMint(
        uint256 tokenId,
        uint32 mintAmount,
        address to
    ) external onlyOwner {
        _commonMint(tokenId, mintAmount, to);
    }

    function listOwner(uint256 tokenId) public view returns (address[] memory) {
        uint32 maxLength = _token[tokenId].numPossibleHolder;
        uint32 cnt = 0;
        address[] memory storing = new address[](maxLength);
        for (uint32 i = 0; i < maxLength; i++) {
            address curAddr = _token[tokenId].possibleHolder[i];
            if (balanceOf(curAddr, tokenId) == 0) continue;
            storing[cnt++] = curAddr;
        }
        address[] memory res = new address[](cnt);
        for (uint32 i = 0; i < cnt; i++) {
            res[i] = storing[i];
        }
        return res;
    }

    function whitelistMintInfo(uint256[] memory tokenIds)
        public
        view
        returns (
            MintMode activeMintMode,
            uint256[] memory mintFees,
            uint32[] memory tokenIssuedCounts,
            uint32[] memory tokenSupplyCounts
        )
    {
        activeMintMode =
            block.timestamp >= _whitelist.startMintTime ? _whitelist.mintMode : MintMode.NOTOPEN;

        mintFees = new uint256[](tokenIds.length);
        tokenIssuedCounts = new uint32[](tokenIds.length);
        tokenSupplyCounts = new uint32[](tokenIds.length);

        for (uint32 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_token[tokenId].isInitialized, "Token Not Initialized");
            mintFees[i] = _token[tokenId].mintFee;
            tokenIssuedCounts[i] = _token[tokenId].numIssuedToken;
            tokenSupplyCounts[i] = _token[tokenId].tokenSupply;
        }
    }

    function withdraw(address _wallet) public payable onlyOwner {
        require(payable(_wallet).send(address(this).balance));
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (_operator == proxyRegistryAddress) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI; // Contract-level metadata
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    function _msgSender() internal view override returns (address) {
        return ContextMixin.msgSender();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenType(
        uint256 tokenId,
        uint32 tokenSupply,
        uint256 mintFee
    ) external onlyOwner {
        require(_token[tokenId].isInitialized == true, "Token Not Initialized");
        _token[tokenId].tokenSupply = tokenSupply;
        _token[tokenId].mintFee = mintFee;
    }

}
