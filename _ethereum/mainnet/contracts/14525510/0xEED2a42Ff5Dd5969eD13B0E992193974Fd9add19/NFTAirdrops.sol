// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./INFT721.sol";

contract NFTAirdrops is Ownable {
    address public immutable nftContract;
    mapping(bytes32 => Airdrop) public airdrops;
    mapping(bytes32 => mapping(bytes32 => bool)) _minted;
    uint256 internal _tokenId;

    struct Airdrop {
        address signer;
        uint32 deadline;
        uint32 max;
        uint32 minted;
    }

    event Add(bytes32 indexed slug, address signer, uint32 deadline, uint32 max);
    event Claim(bytes32 indexed slug, bytes32 indexed id, address indexed to, uint256 tokenId);

    constructor(address _nftContract, uint256 fromTokenId) {
        nftContract = _nftContract;
        _tokenId = fromTokenId;
    }

    function add(
        bytes32 slug,
        address signer,
        uint32 deadline,
        uint32 max
    ) external onlyOwner {
        Airdrop storage airdrop = airdrops[slug];
        require(airdrop.signer == address(0), "LEVX: ADDED");

        airdrop.signer = signer;
        airdrop.deadline = deadline;
        airdrop.max = max;

        emit Add(slug, signer, deadline, max);
    }

    function claim(
        bytes32 slug,
        bytes32 id,
        address to,
        bytes calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        Airdrop storage airdrop = airdrops[slug];
        (address signer, uint32 deadline, uint32 max, uint32 minted) = (
            airdrop.signer,
            airdrop.deadline,
            airdrop.max,
            airdrop.minted
        );

        require(signer != address(0), "LEVX: INVALID_SLUG");
        require(deadline == 0 || uint32(block.timestamp) < deadline, "LEVX: EXPIRED");
        require(max == 0 || minted < max, "LEVX: FINISHED");
        require(!_minted[slug][id], "LEVX: MINTED");

        {
            bytes32 message = keccak256(abi.encodePacked(slug, id));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }

        airdrop.minted = minted + 1;
        _minted[slug][id] = true;

        uint256 tokenId = _tokenId++;
        emit Claim(slug, id, to, tokenId);
        INFT721(nftContract).mint(to, tokenId, data);
    }
}
