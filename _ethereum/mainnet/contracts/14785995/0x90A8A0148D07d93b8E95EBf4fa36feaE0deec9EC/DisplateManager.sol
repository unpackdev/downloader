// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CloneFactory.sol";
import "./INFT.sol";
import "./IAccessManager.sol";
import "./Ownable.sol";
import "./BytesLib.sol";

contract DisplateManager is CloneFactory, Ownable {
    string public baseTokenUri;
    address accessManagerAddress;
    address public templateAddress;

    IAccessManager accessManager;

    event NFTDropped(address _NFTAddress, uint32 _nftId);

    modifier isOperationalAddress() {
        require(
            accessManager.isOperationalAddress(msg.sender) == true,
            "You are not allowed to use this function"
        );
        _;
    }

    constructor(
        address _accessManangerAddress,
        address _templateAddress,
        string memory _baseTokenUri
    ) {
        setAccessManagerAddress(_accessManangerAddress);
        accessManager = IAccessManager(accessManagerAddress);
        templateAddress = _templateAddress;
        baseTokenUri = _baseTokenUri;
    }

    function NFTDrop(bytes memory _data) external isOperationalAddress {
        uint32 staticDataLength = BytesLib.toUint32(
            BytesLib.slice(_data, 0, 4),
            0
        );

        bytes memory staticData = BytesLib.slice(
            _data,
            4,
            staticDataLength / 2
        );

        uint32 amountOfNFT = BytesLib.toUint32(
            BytesLib.slice(_data, staticDataLength / 2 + 3, 4),
            0
        );

        bytes memory dynamicDataForLoop = BytesLib.slice(
            _data,
            staticDataLength / 2 + 7,
            _data.length - (staticDataLength / 2 + 7)
        );

        for (uint32 i = 0; i < amountOfNFT * 160; i += 160) {
            bytes memory dynamicData = BytesLib.slice(
                dynamicDataForLoop,
                0 + i,
                160
            );

            uint32 nftId = uint32(
                BytesLib.toUint256(
                    BytesLib.slice(dynamicDataForLoop, 32 + i, 32),
                    0
                )
            );

            address clonedNFTAddress = createClone(templateAddress);
            INFT clonedNFT = INFT(clonedNFTAddress);

            clonedNFT.init(accessManagerAddress, staticData, dynamicData);

            emit NFTDropped(clonedNFTAddress, nftId);
        }
    }

    function setAccessManagerAddress(address _newAccessManagerAddress)
        public
        onlyOwner
    {
        accessManagerAddress = _newAccessManagerAddress;
    }

    function setBaseTokenUri(string memory _newBaseTokenUri)
        public
        isOperationalAddress
    {
        baseTokenUri = _newBaseTokenUri;
    }

    function setTemplateAddress(address _newTemplateAddress)
        public
        isOperationalAddress
    {
        templateAddress = _newTemplateAddress;
    }
}
