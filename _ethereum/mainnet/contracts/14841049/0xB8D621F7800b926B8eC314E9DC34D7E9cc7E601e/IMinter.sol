//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    event SignerChanged(address signer);
    event WhitelistMintConfChanged(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    );
    event GenesisMintConfChanged(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    );
    event PublicMintPriceChanged(uint256 price);

    function toggleWhitelistMintStatus() external;

    function togglePublicMintStatus() external;

    function toggleGenesisMintStatus() external;

    function devMint(uint16 quantity, address to) external;

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external;

    function devMintVaryToMultiAddr(
        uint16[] calldata quantities,
        address[] calldata addresses
    ) external;

    function setWhitelistMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external;

    function setGenesisMintConf(
        uint16 maxMint,
        uint16 maxPerAddrMint,
        uint256 price
    ) external;

    function isWhitelist(string calldata salt, bytes calldata token)
        external
        returns (bool);

    function isGenesis(string calldata salt, bytes calldata token)
        external
        returns (bool);

    function whitelistMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable;

    function genesisMint(
        uint16 quantity,
        string calldata salt,
        bytes calldata token
    ) external payable;

    function setPublicMintPrice(uint256 price) external;

    function publicMint(uint16 quantity, address to) external payable;

    function whitelistAddrMinted(address sender) external view returns (uint16);

    function genesisAddrMinted(address sender) external view returns (uint16);

    function getSigner() external view returns (address);

    function setSigner(address signer) external;

    function withdraw() external;
}
