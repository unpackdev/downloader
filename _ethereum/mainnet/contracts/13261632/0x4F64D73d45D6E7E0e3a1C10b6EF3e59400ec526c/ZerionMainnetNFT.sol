// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./ERC1155Supply.sol";
import "./IZerionMainnetNFT.sol";

contract ZerionMainnetNFT is ERC1155Supply, IZerionMainnetNFT {
    /// @inheritdoc IZerionMainnetNFT
    string public override name;
    /// @inheritdoc IZerionMainnetNFT
    string public override symbol;
    /// @inheritdoc IZerionMainnetNFT
    string public override contractURI;

    uint256 internal constant TOKEN_AMOUNT = 123;
    string internal constant IPFS_PREFIX = "ipfs://";
    bytes4 internal constant INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    mapping(uint256 => string) internal ipfsHashes;

    /// @notice Creates Zerion Mainnet NFTs, stores all the required parameters.
    /// @param name_ Collection name.
    /// @param symbol_ Collection symbol.
    /// @param contractIpfsHash_ IPFS hash for the collection metadata.
    /// @param ipfsHashes_ IPFS hashes for `tokenId` from 1 to 4.
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractIpfsHash_,
        string[4] memory ipfsHashes_
    ) ERC1155("") {
        name = name_;
        symbol = symbol_;
        contractURI = hashToURI(contractIpfsHash_);

        address msgSender = _msgSender();

        for (uint256 i = 0; i < 4; i++) {
            ipfsHashes[i + 1] = ipfsHashes_[i];
            emit URI(hashToURI(ipfsHashes_[i]), i + 1);
            _mint(msgSender, i + 1, TOKEN_AMOUNT, new bytes(0));
        }
    }

    /// @inheritdoc IZerionMainnetNFT
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155, IZerionMainnetNFT)
        returns (string memory)
    {
        if (tokenId == 0 || tokenId > 4) return "";

        return hashToURI(ipfsHashes[tokenId]);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return interfaceId == INTERFACE_ID_CONTRACT_URI || super.supportsInterface(interfaceId);
    }

    /// @dev Adds IPFS prefix for a given IPFS hash.
    function hashToURI(string memory ipfsHash) internal pure returns (string memory) {
        return string(abi.encodePacked(IPFS_PREFIX, ipfsHash));
    }
}
