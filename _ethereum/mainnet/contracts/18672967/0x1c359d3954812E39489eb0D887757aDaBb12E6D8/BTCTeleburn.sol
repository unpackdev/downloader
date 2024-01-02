// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IERC721.sol";
import "./Ownable.sol";

abstract contract BTCTeleburn is Ownable {
    IERC721 public immutable nft;
    address public teleburnSigner;

    uint256 public teleburnedCount = 0;
    mapping(uint256 tokenId => bool) public isTokenTeleburned;

    event Teleburn(
        uint256 indexed tokenId, address sender, address teleburnAddress, string btcAddress, string inscriptionId
    );

    error InvalidRequest();

    constructor(address nft_, address teleburnSigner_) Ownable(msg.sender) {
        nft = IERC721(nft_);
        teleburnSigner = teleburnSigner_;
    }

    function teleburnedTokens(uint256 startTokenId, uint256 endTokenId) external view returns (uint256[] memory) {
        uint256 count = teleburnedCount;
        if (count == 0) return new uint256[](0);
        uint256[] memory tokens = new uint256[](count);

        uint256 index;
        for (uint256 i = startTokenId; i <= endTokenId; ++i) {
            if (isTokenTeleburned[i]) {
                tokens[index] = i;
                ++index;
            }
        }

        return tokens;
    }

    function getTokenSatNumber(uint256 tokenId) external view returns (uint256) {
        if (!isTokenTeleburned[tokenId]) return 0;

        return 45017800000 + tokenId;
    }

    function teleburnMultipleTokens(
        uint256[] calldata tokenIds,
        address[] calldata teleburnAddresses,
        string[] calldata btcAddresses,
        string[] calldata inscriptionIds,
        bytes[] calldata data
    ) external {
        uint256 count = tokenIds.length;

        for (uint256 i; i < count; ++i) {
            teleburnToken(tokenIds[i], teleburnAddresses[i], btcAddresses[i], inscriptionIds[i], data[i]);
        }
    }

    function teleburnToken(
        uint256 tokenId,
        address teleburnAddress,
        string calldata btcAddress,
        string calldata inscriptionId,
        bytes calldata data
    ) public {
        if (!_isValidRequest(tokenId, teleburnAddress, btcAddress, inscriptionId, data)) {
            revert InvalidRequest();
        }

        _teleburn(tokenId, teleburnAddress, btcAddress, inscriptionId);
    }

    function updateTeleburnSigner(address newTeleburnSigner) external onlyOwner {
        teleburnSigner = newTeleburnSigner;
    }

    function _teleburn(
        uint256 tokenId,
        address teleburnAddress,
        string calldata btcAddress,
        string calldata inscriptionId
    ) private {
        isTokenTeleburned[tokenId] = true;

        ++teleburnedCount;
        nft.safeTransferFrom(msg.sender, teleburnAddress, tokenId);
        emit Teleburn(tokenId, msg.sender, teleburnAddress, btcAddress, inscriptionId);
    }

    /// @dev args: tokenId, teleburnAddress, btcAddress, inscriptionId, data
    function _isValidRequest(uint256, address, string calldata, string calldata, bytes calldata)
        internal
        view
        virtual
        returns (bool)
    {
        return true;
    }
}
