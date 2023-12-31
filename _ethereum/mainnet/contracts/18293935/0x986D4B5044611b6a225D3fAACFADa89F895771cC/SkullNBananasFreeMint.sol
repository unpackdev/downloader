// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

interface ISkullNBananas {
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract SkullNBananasFreeMint is IERC721Receiver, ReentrancyGuard, Ownable {
    mapping(address => uint16) public addressMapping;

    uint16[] private nftsId;

    ISkullNBananas private nftContractAddress;

    constructor(ISkullNBananas _contractAddress) {
        nftContractAddress = _contractAddress;
    }

    function setNftContractAddress(
        ISkullNBananas _contractAddress
    ) public onlyOwner {
        nftContractAddress = _contractAddress;
    }

    function addAddress(
        address[] calldata _addresses,
        uint16[] calldata _nftToSend
    ) public onlyOwner {
        require(
            _addresses.length == _nftToSend.length,
            "Addresses and NFTs to send must be the same length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            addressMapping[_addresses[i]] = _nftToSend[i];
        }
    }

    function redeemFreeNft() public {
        uint16 nftToSend = addressMapping[msg.sender];

        uint256 initialLenght = nftsId.length;

        require(nftToSend > 0, "No NFT to redeem");

        require(initialLenght >= nftToSend, "No NFT available");

        uint256 limit = initialLenght - nftToSend;
        for (
            uint256 i = initialLenght - 1;
            i > limit;
            i--
        ) {
            nftContractAddress.transferFrom(
                address(this),
                msg.sender,
                nftsId[i]
            );
            nftsId.pop();
        }

        addressMapping[msg.sender] = 0;
    }

    function withdrawNfts(uint256 withdrawAmount) public onlyOwner {
        require(withdrawAmount > 0, "Invalid value");

        uint256 initialLenght = nftsId.length;

        require(nftsId.length > withdrawAmount, "No NFT available");

        for (
            uint256 i = initialLenght - 1;
            i > initialLenght - withdrawAmount;
            i--
        ) {
            nftContractAddress.transferFrom(
                address(this),
                msg.sender,
                nftsId[i]
            );
            nftsId.pop();
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 _id,
        bytes calldata
    ) external override returns (bytes4) {
        nftsId.push(uint16(_id));
        return this.onERC721Received.selector;
    }
}
