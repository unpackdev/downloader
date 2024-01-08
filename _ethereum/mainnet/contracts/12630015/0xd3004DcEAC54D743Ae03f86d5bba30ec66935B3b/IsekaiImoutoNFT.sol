// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./MerkleTreeManager.sol";
import "./HasSecondarySaleFees.sol";
import "./iIsekaiImoutoNFT.sol";

contract IsekaiImoutoNFT is iIsekaiImoutoNFT, ERC721, HasSecondarySaleFees, Ownable, MerkleTreeManager {
    using SafeMath for uint256;
    using Strings for uint256;

    address private distributor;
    string private _baseURI;
    uint256 public constant price = 0.1 ether;
    SaleRound[] private saleRounds;

    modifier isSaleRoundsFinished() {
        require(saleRounds[nextTreeId.sub(1)].endAt < block.timestamp, "Current round is not finished");

        _;
    }

    constructor(
        string memory initialBaseURI,
        address payable _distributor
    ) ERC721("Isekai Imouto NFT", "IINFT") {
        require(_distributor != address(0), "Invalid address");

        // Fill index 0
        SaleRound memory saleRound = SaleRound(0, 0);
        saleRounds.push(saleRound);

        _baseURI = initialBaseURI;
        address payable[] memory marketRoyaltyRecipients = new address payable[](1);
        marketRoyaltyRecipients[0] = _distributor;
        distributor = _distributor;
        uint256[] memory marketRoyaltyFees = new uint256[](1);
        marketRoyaltyFees[0] = 1000;
        // 10%

        _setDefaultRoyalty(marketRoyaltyRecipients, marketRoyaltyFees);
    }

    function getCurrentRoundStartDate() external view override returns (uint256) {
        return saleRounds[nextTreeId.sub(1)].startAt;
    }

    function getCurrentRoundEndDate() external view override returns (uint256) {
        return saleRounds[nextTreeId.sub(1)].endAt;
    }

    function addSaleRound(
        string calldata merkleTreeCid,
        bytes32 merkleRoot,
        uint256 startAt,
        uint256 endAt
    ) external override onlyOwner {
        SaleRound memory saleRound = SaleRound(startAt, endAt);
        saleRounds.push(saleRound);

        emit AddSaleRound(
            merkleTreeCid,
            startAt,
            endAt
        );

        super.addTree(merkleRoot);
    }

    function addTree(bytes32) public virtual override {
        revert("disabled function");
    }

    function proof(uint256, uint256, address, uint256, bytes32[] calldata) virtual public override returns (bool) {
        revert("disabled function");
    }

    function buy(
        uint256 index,
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external payable override {
        require(msg.value >= price, "Insufficient value");
        require(
            saleRounds[nextTreeId.sub(1)].startAt <= block.timestamp &&
            block.timestamp < saleRounds[nextTreeId.sub(1)].endAt,
            "Invalid sale period"
        );
        require(super.proof(nextTreeId.sub(1), index, account, tokenId, merkleProof));

        _mint(account, tokenId);
    }

    function withdrawETH() external override {
        Address.sendValue(payable(distributor), address(this).balance);
    }

    function mint(uint256 tokenId) external override onlyOwner isSaleRoundsFinished {
        _mint(msg.sender, tokenId);
    }

    function batchMint(uint256[] calldata tokenIdList) external override onlyOwner isSaleRoundsFinished {
        for (uint256 i = 0; i < tokenIdList.length; i++) {
            _mint(msg.sender, tokenIdList[i]);
        }
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, HasSecondarySaleFees)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

