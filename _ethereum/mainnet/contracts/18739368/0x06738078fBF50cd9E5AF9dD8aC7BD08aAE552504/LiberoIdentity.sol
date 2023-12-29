// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

string constant TOKEN_ID = "Liberoverse";
string constant TOKEN_NAME = "Liberoverse Access Pass";
uint constant MAX_EDITION_SIZE = 10000;

contract LiberoIdentity is ERC721, ERC721Enumerable, Ownable {
    struct Edition {
        string metadataURL;
        uint64 tokenPrice;
        uint16 totalWhitelistTokens;
        uint16 totalTokens;
        uint8 maxWhitelistTokensPerWallet;
        uint8 maxMintTokensPerWallet;
        uint startDate;
        uint16 whitelistMinutes;
        uint16 mintMinutes;
        uint16 tokenNrs;
        uint16 whitelistTokenUsed;
        mapping(address => uint8) whitelistUsed;
        mapping(address => uint8) mintUsed;
    }
    Edition[] private _editionInfo;
    uint16 private _editionNr;
    address private _manager;

    constructor(
        address manager,
        string memory metadataURL,
        uint64 tokenPrice,
        uint16 totalWhitelistTokens,
        uint16 totalTokens,
        uint8 maxWhitelistTokensPerWallet,
        uint8 maxMintTokensPerWallet,
        uint startDate,
        uint16 whitelistMinutes,
        uint16 mintMinutes
    ) ERC721(TOKEN_ID, TOKEN_NAME) {
        _manager = msg.sender;
        newEdition(
            metadataURL,
            tokenPrice,
            totalWhitelistTokens,
            totalTokens,
            maxWhitelistTokensPerWallet,
            maxMintTokensPerWallet,
            startDate,
            whitelistMinutes,
            mintMinutes
        );
        _manager = manager;
    }

    modifier onlyManager() {
        require(_manager == msg.sender, "CALLER_NOT_MANAGER");
        _;
    }

    function setManager(address manager) public onlyOwner {
        _manager = manager;
    }

    function newEdition(
        string memory metadataURL,
        uint64 tokenPrice,
        uint16 totalWhitelistTokens,
        uint16 totalTokens,
        uint8 maxWhitelistTokensPerWallet,
        uint8 maxMintTokensPerWallet,
        uint startDate,
        uint16 whitelistMinutes,
        uint16 mintMinutes
    ) public onlyManager {
        require(totalTokens < MAX_EDITION_SIZE, "MAX_EDITION_SIZE_LIMIT");
        require(
            totalWhitelistTokens <= totalTokens,
            "WHITELST_NOT_GREATER_THAN_TOTAL"
        );
        _editionInfo.push();
        _editionNr = uint16(_editionInfo.length) - 1;

        Edition storage ed = _editionInfo[_editionNr];

        ed.metadataURL = metadataURL;
        ed.tokenPrice = tokenPrice;
        ed.totalWhitelistTokens = totalWhitelistTokens;
        ed.totalTokens = totalTokens;
        ed.maxWhitelistTokensPerWallet = maxWhitelistTokensPerWallet;
        ed.maxMintTokensPerWallet = maxMintTokensPerWallet;
        ed.startDate = startDate;
        ed.whitelistMinutes = whitelistMinutes;
        ed.mintMinutes = mintMinutes;
    }

    function _tokenIdToEdition(
        uint256 tokenId
    ) private pure returns (uint16 editionNr) {
        return uint16(tokenId / MAX_EDITION_SIZE);
    }

    function _tokenIdToEditionAndTokenNr(
        uint256 tokenId
    ) private pure returns (uint16 editionNr, uint240 tokenNr) {
        return (
            uint16(tokenId / MAX_EDITION_SIZE),
            uint240(tokenId % MAX_EDITION_SIZE)
        );
    }

    function _tokenIdFromEditionAndTokenNr(
        uint16 editionNr,
        uint240 tokenNr
    ) private pure returns (uint256 tokenId) {
        return uint256(editionNr * MAX_EDITION_SIZE) + uint256(tokenNr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _editionInfo[_tokenIdToEdition(tokenId)].metadataURL,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function getActiveEditionInfo()
        public
        view
        onlyManager
        returns (
            // edition constructor
            string memory metadataURL,
            uint64 tokenPrice,
            uint16 totalWhitelistTokens,
            uint16 totalTokens,
            uint8 maxWhitelistTokensPerWallet,
            uint8 maxMintTokensPerWallet,
            // ext info
            uint16 editionNr,
            uint256 editionTotalSupply,
            uint whitelistStart,
            uint mintStart,
            uint mintEnd
        )
    {
        (whitelistStart, mintStart, mintEnd) = getActiveEditionDates();
        Edition storage activeEdition = _editionInfo[_editionNr];

        return (
            // edition constructor
            activeEdition.metadataURL,
            activeEdition.tokenPrice,
            activeEdition.totalWhitelistTokens,
            activeEdition.totalTokens,
            activeEdition.maxWhitelistTokensPerWallet,
            activeEdition.maxMintTokensPerWallet,
            // ext info
            _editionNr,
            activeEdition.tokenNrs,
            whitelistStart,
            mintStart,
            mintEnd
        );
    }

    function getActiveEditionUsed(
        address accountNr
    ) public view returns (uint8 whitelistUsed, uint8 mintUsed) {
        Edition storage activeEdition = _editionInfo[_editionNr];

        return (
            activeEdition.whitelistUsed[accountNr],
            activeEdition.mintUsed[accountNr]
        );
    }

    function getActiveEditionDates()
        private
        view
        returns (uint whitelistStart, uint mintStart, uint mintEnd)
    {
        Edition storage activeEdition = _editionInfo[_editionNr];

        return (
            activeEdition.startDate,
            activeEdition.startDate + uint(activeEdition.whitelistMinutes) * 60,
            activeEdition.startDate +
                uint(
                    activeEdition.whitelistMinutes + activeEdition.mintMinutes
                ) *
                60
        );
    }

    function _mintCount(address to, uint8 count) private {
        require(count > 0, "MINT_AT_LEAST_ONE");
        Edition storage activeEdition = _editionInfo[_editionNr];

        uint16 startTokenNr = activeEdition.tokenNrs;
        activeEdition.tokenNrs += count;

        require(
            activeEdition.tokenNrs <= activeEdition.totalTokens,
            "MAX_TOKENS_EXCEEDED"
        );

        uint16 endTokenNr = startTokenNr + count;

        for (
            uint16 newTokenNr = startTokenNr + 1;
            newTokenNr <= endTokenNr;
            newTokenNr++
        ) {
            uint256 tokenId = _tokenIdFromEditionAndTokenNr(
                _editionNr,
                uint240(newTokenNr)
            );

            _safeMint(to, tokenId);
        }
    }

    function mint(uint8 count) public payable {
        uint whitelistStart;
        uint mintStart;
        uint mintEnd;
        (whitelistStart, mintStart, mintEnd) = getActiveEditionDates();
        Edition storage activeEdition = _editionInfo[_editionNr];

        require(
            block.timestamp >= mintStart && block.timestamp < mintEnd,
            "PUBLIC_MINT_NOT_ACTIVE"
        );
        require(
            msg.value == activeEdition.tokenPrice * count,
            string(
                abi.encodePacked(
                    "TOKEN_COST_GWEI:",
                    Strings.toString(activeEdition.tokenPrice / 1 gwei)
                )
            )
        );

        activeEdition.mintUsed[msg.sender] += count;
        require(
            activeEdition.mintUsed[msg.sender] <=
                activeEdition.maxMintTokensPerWallet,
            "MAX_ALREADY_MINTED"
        );

        payable(owner()).transfer(activeEdition.tokenPrice);
        _mintCount(address(msg.sender), count);
    }

    function mintWhitelist(uint8 count, bytes memory signature) public {
        uint whitelistStart;
        uint mintStart;
        uint mintEnd;
        (whitelistStart, mintStart, mintEnd) = getActiveEditionDates();
        Edition storage activeEdition = _editionInfo[_editionNr];

        require(
            block.timestamp >= whitelistStart && block.timestamp < mintStart,
            "WHITELIST_MINT_NOT_ACTIVE"
        );

        activeEdition.whitelistTokenUsed += count;
        require(
            activeEdition.whitelistTokenUsed <=
                activeEdition.totalWhitelistTokens,
            "MAX_WHITELIST_TOKENS_EXCEEDED"
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(_editionNr, uint160(msg.sender))
        );
        address recoveredSigner = ECDSA.recover(
            ethSignedMessageHash,
            signature
        );

        require(recoveredSigner == _manager, "WHITELIST_NEEDS_VALID_SIGNATURE");

        activeEdition.whitelistUsed[msg.sender] += count;
        require(
            activeEdition.whitelistUsed[msg.sender] <=
                activeEdition.maxWhitelistTokensPerWallet,
            "MAX_ALREADY_CLAIMED"
        );

        _mintCount(address(msg.sender), count);
    }
}
