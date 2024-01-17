// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MerkleProof.sol";
import "./LibNftCommon.sol";
import "./LibAppStorage.sol";
import "./LibMeta.sol";
import "./LibERC721.sol";

contract PreSaleFacet is Modifiers {
    function isSaleActive() external view returns (bool) {
        return s.saleIsActive;
    }

    function isWhitelistActive() external view returns (bool) {
        return s.whitelistIsActive;
    }

    function isFreeMintEnabled() external view returns (bool) {
        return s.freeMintEnabled;
    }

    function isWhitelistSaleClaimed(address owner) external view returns (bool) {
        return s.whitelistClaimed[owner];
    }

    function setSaleIsActive(bool _isActive) external onlyOwner {
        s.saleIsActive = _isActive;
    }

    function setWhitelistIsActive(bool _isActive) external onlyOwner {
        s.whitelistIsActive = _isActive;
    }

    function setFreeMintEnabled(bool _isEnabled) external onlyOwner {
        s.freeMintEnabled = _isEnabled;
    }

    function setWhitelistMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        s.whitelistMerkleRoot = _newMerkleRoot;
    }

    function whitelistSale(bytes32[] memory proof, uint256 _nftCount) external {
        // merkle tree list related
        require(s.whitelistIsActive, "PreSaleFacet: whitelist sale is disabled");
        require(s.whitelistClaimed[msg.sender] == false, "PreSaleFacet: address already used whitelist sale");
        require(s.whitelistMerkleRoot != "", "PreSaleFacet: whitelist claim merkle root not set");
        require(
            MerkleProof.verify(
                proof,
                s.whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, _nftCount))
            ),
            "PreSaleFacet: whitelist claim validation failed"
        );

        // start minting
        //require(s.whitelistSalePrice * _nftCount <= msg.value, "PreSaleFacet: Insufficient ethers value");
        mint(_nftCount);

        s.whitelistClaimed[msg.sender] = true;
    }

    function purchaseNft(uint256 _nftCount) external payable {
        require(s.saleIsActive, "PreSaleFacet: sale is disabled");
        require(s.nftSalePrice * _nftCount <= msg.value, "PreSaleFacet: Insufficient ethers value");
        mint(_nftCount);
    }

    function mint(uint256 _nftCount) internal virtual {
        address receiver = LibMeta.msgSender();

        require(_nftCount + s.tokenIdsCount <= s.maxNftCount, "PreSaleFacet: Exceeded maximum Nfts supply");
        require(_nftCount + s.ownerTokenIds[receiver].length <= s.maxNftSalePerUser, "PreSaleFacet: Exceeded maximum Nfts per user");

        uint256 tokenId = s.tokenIdsCount;
        for (uint256 i = 0; i < _nftCount; i++) {
            s.nfts[tokenId].tokenId = tokenId;
            LibNftCommon.setOwner(tokenId, receiver);

            s.tokenIdsCount++;
            tokenId++;
        }
    }

    function freeMint() external {
        require(s.freeMintEnabled, "PreSaleFacet: free mint is disabled");
        require(s.ownerTokenIds[msg.sender].length == 0, "PreSaleFacet: address already obtained the nft");

        mint(1);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(LibMeta.msgSender()).transfer(balance);
    }
}