// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract WGA is ERC721, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public constant PRICE = 0.01 * 10**18; // 0.01 ETH
    address public WINGS_CONTRACT = 0x0CB5b2Cb404f9A18a4D0d17B85aDA514b864768F;
    // Mapping NFT contract address to contract metadata.
    mapping(address => uint256) public allow_contracts;

    event Minted(address minter, address grantee, uint256 wingsId, address targetContract, uint256 targetId, uint256 tokenId);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor() ERC721("WINGS X AVATARS GENESIS", "WGA") {
        // BAYC
        allow_contracts[0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D] = 1;
        // MAYC
        allow_contracts[0x60E4d786628Fea6478F785A6d7e704777c86a7c6] = 1;
        // AZUKI
        allow_contracts[0xED5AF388653567Af2F388E6224dC7C4b3241C544] = 1;
        // Mfers
        allow_contracts[0x79FCDEF22feeD20eDDacbB2587640e45491b757f] = 1;
        // WOW
        allow_contracts[0xe785E82358879F061BC3dcAC6f0444462D4b5330] = 1;
        // Beanz
        allow_contracts[0x306b1ea3ecdf94aB739F1910bbda052Ed4A9f949] = 1;
        // Doodles
        allow_contracts[0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e] = 1;
    }

    function MintNFT(address grantee, uint256 wingsId, address targetContract, uint256 targetId) external payable {
        require(status == Status.Started, "WGA: Not started yet.");
        require(checkOwnerOf(WINGS_CONTRACT, wingsId, grantee), "WGA: Not wings owner.");
        require(allow_contracts[targetContract] == 1, "WGA: NFT contract not in allow list.");
        require(checkOwnerOf(targetContract, targetId, grantee), "WGA: Not target NFT owner.");
        uint256 tokenId = generateTokenId(wingsId, targetContract, targetId);
        _mint(grantee, tokenId);
        refundIfOver(PRICE);
        emit Minted(msg.sender, grantee, wingsId, targetContract, targetId, tokenId);
    }

    function generateTokenId(uint256 wingsId, address targetContract, uint256 targetId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(wingsId, targetContract, targetId)));
    }

    function checkOwnerOf(address nftContract, uint256 tokenId, address user) public view returns (bool) {
        address tokenOwner = IERC721(nftContract).ownerOf(tokenId);
        return tokenOwner == user;
    }

    function refundIfOver(uint256 amount) private {
        require(msg.value >= amount, "WGA: No enough ETH in transaction.");
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function setAllowContract(address nftContract, uint256 metadata) external onlyOwner {
        allow_contracts[nftContract] = metadata;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "WGA: Can't withdraw.");
    }
}
