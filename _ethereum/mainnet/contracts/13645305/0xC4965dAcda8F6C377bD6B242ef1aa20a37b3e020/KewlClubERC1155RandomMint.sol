// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract KewlClubERC1155RandomMint is ERC1155, Ownable {
    bytes32 public merkleRoot;

    string public name;
    string public symbol;

    uint256 public totalSupply;

    uint256 public constant TOKEN_0 = 0;
    uint256 public constant TOKEN_1 = 1;

    mapping(address => uint256) public claimedAmounts;

    event Claimed(
        address indexed account,
        uint256 token0Amount,
        uint256 token1Amount
    );

    event MerkleRootUpdate(bytes32 oldMerkleRoot, bytes32 newMerkleRoot);

    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        string memory url
    ) ERC1155(url) {
        name = _name;
        symbol = _symbol;
        merkleRoot = _merkleRoot;
    }

    function mint(
        address account,
        uint256 entitledAmount,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external {
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(account, entitledAmount))
            ),
            "KewlClubERC1155RandomMint: invalid proof"
        );

        require(
            claimAmount > 0,
            "KewlClubERC1155RandomMint: claim amount is zero"
        );
        uint256 claimedAmount = claimedAmounts[account];
        require(
            entitledAmount >= claimAmount + claimedAmount,
            "KewlClubERC1155RandomMint: claim amount too large"
        );

        claimedAmounts[account] = claimAmount + claimedAmount;

        totalSupply += claimAmount;

        uint256 token0ToMint;
        uint256 token1ToMint;

        for (uint256 i = 0; i < claimAmount; i++) {
            uint256 kindOfRandomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        i
                    )
                )
            );

            if (kindOfRandomNumber % 2 == 0) {
                token1ToMint += 1;
            } else {
                token0ToMint += 1;
            }
        }

        if (token0ToMint > 0) _mint(account, TOKEN_0, token0ToMint, "");
        if (token1ToMint > 0) _mint(account, TOKEN_1, token1ToMint, "");

        emit Claimed(account, token0ToMint, token1ToMint);
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        bytes32 oldMerkleRoot = merkleRoot;
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdate(oldMerkleRoot, _merkleRoot);
    }
}
