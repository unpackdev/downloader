// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./Strings.sol";

contract ETHNFTBridgeContract is IERC721Receiver {
    using Address for address;
    using Strings for uint256;
    address public owner;
    bytes public bridgedBASENFTContractAddress;
    bool public acceptETHNFTs;
    bool public acceptBridgedBASENFTs;
    mapping(bytes => mapping(uint256 => address)) nftStore;
    mapping(address => uint) _balance;

    event ReceivedNFT(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    event WithdrawnNFT(
        address nftContractAddress,
        uint256 tokenId,
        address toAddres
    );

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(bytes memory bridgedBASENFTAddress) {
        owner = msg.sender;
        bridgedBASENFTContractAddress = bridgedBASENFTAddress;
        acceptETHNFTs = false;
        acceptBridgedBASENFTs = false;
    }

    fallback() external payable {
        _balance[msg.sender] = msg.value;
    }

    receive() external payable {
        _balance[msg.sender] = msg.value;
    }

    function withdrawFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function toggleAcceptEthNfts() public onlyOwner {
        acceptETHNFTs = !acceptETHNFTs;
    }

    function toggleAcceptBridgedBaseNfts() public onlyOwner {
        acceptBridgedBASENFTs = !acceptBridgedBASENFTs;
    }

    function getNftStoreData(
        bytes calldata nftContractAddress,
        uint256 tokenId
    ) public view returns (address) {
        return nftStore[nftContractAddress][tokenId];
    }

    function getUserBalance(address userAddress) public view returns (uint) {
        return _balance[userAddress];
    }

    function compareStringsbyBytes(
        bytes calldata s1,
        bytes memory s2
    ) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        bool isBridgedBASEToken = compareStringsbyBytes(
            data,
            bridgedBASENFTContractAddress
        );

        if (isBridgedBASEToken) {
            if (!acceptBridgedBASENFTs) return "0x";
        } else {
            if (!acceptETHNFTs) return "0x";
            require(
                _balance[msg.sender] >= 10000000000000000,
                "You need to have at least 0.01 ETH in the bridge to bridge once."
            );
            _balance[msg.sender] = 0;
        }

        nftStore[data][tokenId] = from;

        emit ReceivedNFT(operator, from, tokenId, data);

        return this.onERC721Received.selector;
    }

    function triggerNFTWithdrawalToAddress(
        address nftContractAddress,
        bytes calldata nftContractAddressInBytes,
        uint256 tokenId,
        address toAddress
    ) public onlyOwner {
        address storedFromAddress = nftStore[nftContractAddressInBytes][
            tokenId
        ];
        require(
            storedFromAddress != address(0),
            "The bridge does not have the NFT"
        );

        delete nftStore[nftContractAddressInBytes][tokenId];

        IERC721(nftContractAddress).safeTransferFrom(
            address(this),
            toAddress,
            tokenId,
            "0x"
        );

        emit WithdrawnNFT(nftContractAddress, tokenId, toAddress);
    }
}
