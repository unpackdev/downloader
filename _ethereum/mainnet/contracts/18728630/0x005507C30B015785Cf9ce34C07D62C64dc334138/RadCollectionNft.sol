// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract RadCollectionNft is ERC1155, Ownable, ERC1155Supply {
    struct RevenueSplit {
        address wallet;
        uint256 percentange; // 22 = 2.2%
        string nickname;
    }
    struct NftDetailStruct {
        address createdBy;
        bool status;
        uint256 mintPrice;
        uint256 maxSupply;
    }

    uint256 public totalNFTs;
    mapping(uint256 => string) public UriOf;
    mapping(uint256 => NftDetailStruct) public nftDetailOf;
    mapping(uint256 => uint256) public currentSupplyOf;
    mapping(uint256 => RevenueSplit[]) public revenueSplitsOfNFT;

    uint256 platformCommisionPercentage = 300; // 30%
    address platformAddress = 0x02232a2de6C1d673D19ee48f556A3933AC987eCc; // 30%

    event NFTcreated(uint256 indexed id, uint256 mintPrice, uint256 time);

    constructor() ERC1155("Rad Collection") {
        totalNFTs = 0;
    }

    //  Only let the function run if the NFT is created
    modifier onlyNftExist(uint256 id) {
        require(totalNFTs >= id, "NFT doesnot exits");
        _;
    }

    // Only the user who minted the nft can call the function
    modifier onlyNftMinter(uint256 id) {
        require(
            nftDetailOf[id].createdBy == msg.sender,
            "Only the minter can perform this action"
        );
        _;
    }

    modifier onlyPlatform() {
        require(
            msg.sender == platformAddress,
            "Only platform can call this function"
        );
        _;
    }

    // Owner can create NFT and add its Metadat URI and mint price
    function createNFT(
        string memory _nftUri,
        uint256 _mintPrice,
        uint256 _maxSupply,
        RevenueSplit[] memory revenueSplits
    ) public returns (uint256) {
        uint256 _nftId = totalNFTs + 1;
        _checkPercentage(revenueSplits);
        nftDetailOf[_nftId] = NftDetailStruct(
            msg.sender,
            true,
            _mintPrice,
            _maxSupply
        );
        UriOf[_nftId] = _nftUri;
        emit NFTcreated(_nftId, _mintPrice, block.timestamp);
        _addRevenueSplitOfToken(_nftId, revenueSplits);
        totalNFTs++;
        return _nftId;
    }

    // Owner can update uri of created nft
    // params: id - nft id which uri you want to update
    // tokenUri - new URI
    function updateURIOfToken(
        uint256 id,
        string memory tokenUri
    ) public onlyNftMinter(id) onlyNftExist(id) {
        UriOf[id] = tokenUri;
    }

    // Owner can update uri of created nft
    // params: id - nft id which uri you want to update
    // tokenUri - new URI
    function updateNftDetails(
        uint256 id,
        NftDetailStruct memory _details
    ) public onlyNftMinter(id) onlyNftExist(id) {
        nftDetailOf[id] = _details;
    }

    function updateRevenueSplitOfToken(
        uint256 _nftId,
        RevenueSplit[] memory revenueSplits
    ) public onlyNftMinter(_nftId) onlyNftExist(_nftId) {
        _checkPercentage(revenueSplits);
        _addRevenueSplitOfToken(_nftId, revenueSplits);
    }

    function getRevenueSplitsOfToken(
        uint256 _nftId
    ) public view returns (RevenueSplit[] memory) {
        return revenueSplitsOfNFT[_nftId];
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public payable onlyNftExist(id) {
        require(
            msg.value >= nftDetailOf[id].mintPrice,
            "Please send full mint price"
        );

        // maxSupply 0  means unlimited supply
        if (nftDetailOf[id].maxSupply != 0) {
            require(
                currentSupplyOf[id] + amount <= nftDetailOf[id].maxSupply,
                "Max supply exceeds for this nft"
            );
        }

        _mint(account, id, amount, "");
        currentSupplyOf[id] += amount;
        splitRevenue(id, nftDetailOf[id].mintPrice);
    }

    function splitRevenue(uint256 nftid, uint256 totalAmount) private {
        uint256 platformCommissionAmount = (totalAmount *
            platformCommisionPercentage) / 1000;
        (bool sent, ) = platformAddress.call{value: platformCommissionAmount}(
            ""
        );
        require(sent, "Not able to send payment to platform");

        uint256 remainingAmount = totalAmount - platformCommissionAmount;
        RevenueSplit[] memory revenueSplits = revenueSplitsOfNFT[nftid];
        _checkPercentage(revenueSplits);
        for (uint i = 0; i < revenueSplits.length; i++) {
            RevenueSplit memory oneUserSplit = revenueSplits[i];
            uint256 userAmount = (remainingAmount * oneUserSplit.percentange) /
                1000;
            (bool sentOther, ) = oneUserSplit.wallet.call{value: userAmount}(
                ""
            );
            require(sentOther, "Not able to send payment to account");
        }
    }

    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return UriOf[id];
    }

    function transferEth(address _to, uint256 amount) public onlyPlatform {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _checkPercentage(
        RevenueSplit[] memory revenueSplits
    ) internal pure {
        uint256 _totalPercentage = 0;
        for (uint i = 0; i < revenueSplits.length; i++) {
            _totalPercentage += revenueSplits[i].percentange;
        }
        require(
            _totalPercentage <= 1000,
            "Percentage Calculation is not correct."
        );
    }

    function updatePlatform(address _newPlatform) public onlyPlatform {
        platformAddress = _newPlatform;
    }

    function _addRevenueSplitOfToken(
        uint256 _nftId,
        RevenueSplit[] memory revenueSplits
    ) internal {
        _checkPercentage(revenueSplits);
        delete revenueSplitsOfNFT[_nftId];
        for (uint256 i = 0; i < revenueSplits.length; i++) {
            revenueSplitsOfNFT[_nftId].push(
                RevenueSplit(
                    revenueSplits[i].wallet,
                    revenueSplits[i].percentange,
                    revenueSplits[i].nickname
                )
            );
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
