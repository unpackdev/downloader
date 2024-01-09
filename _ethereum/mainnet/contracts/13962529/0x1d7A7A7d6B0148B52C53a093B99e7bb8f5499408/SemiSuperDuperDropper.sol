// SemiSupers
// Website: https://semisupers.com
// Twitter: https://twitter.com/semisupers
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

interface ISemiSupers {
    function allowlistMint(
        uint256 numSupers,
        bytes32 _leaf,
        bytes32[] calldata _merkleProof
    ) external;

    function nextSuperId() external returns (uint256);
}

contract SemiSuperDuperDropper is Ownable, ERC721Holder {
    address public semisupers;
    bytes32 public leaf;
    bytes32[] public proof;

    constructor(address _semisupers) Ownable() {
        setSemiSupers(_semisupers);
    }

    function mintEm(address[] calldata addresses, uint256[] calldata counts)
        public
        onlyOwner
    {
        require(addresses.length == counts.length, 'WRONG_LENGTH');
        uint256 tokenId = ISemiSupers(semisupers).nextSuperId();
        uint256 offset = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            ISemiSupers(semisupers).allowlistMint(counts[i], leaf, proof);
            for (uint256 j = 0; j < counts[i]; j++) {
                try
                    IERC721(semisupers).transferFrom(
                        address(this), // from
                        addresses[i], // to
                        tokenId + offset // tokenId
                    )
                {} catch {}
                offset += 1;
            }
        }
    }

    function setSemiSupers(address newSemiSupers) public onlyOwner {
        semisupers = newSemiSupers;
    }

    function setLeafAndProof(bytes32 newLeaf, bytes32[] memory newProof)
        public
        onlyOwner
    {
        leaf = newLeaf;
        proof = newProof;
    }

    function transferFrom(
        IERC721 token,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        token.transferFrom(address(this), to, tokenId);
    }

    function setApprovalForAll(
        IERC721 token,
        address operator,
        bool approved
    ) public onlyOwner {
        token.setApprovalForAll(operator, approved);
    }

    function renounceOwnership() public override onlyOwner {}
}
