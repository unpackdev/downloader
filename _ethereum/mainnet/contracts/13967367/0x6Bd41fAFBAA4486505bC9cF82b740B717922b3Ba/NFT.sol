//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ECDSAUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract NFT is
    UUPSUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    // Whether or not the NFT has been revealed yet.
    // When the presale is happening, then no NFT's are revealed.
    // When the public sale is happening, then all NFT's are revealed.
    // Therefore, the moment NFT's are revealed, the public sale is considered to have been started.
    bool public revealed;

    // The max number of NFT's.
    uint256 public maxSupply;

    // The max number of possible NFT mints which may take place in a single transaction.
    // This is set in order to prevent users from exceeding the gas limit.
    uint256 public maxMintsPerTransaction;

    // A mapping used to count the number of times a user has minted a NFT from this
    // contract.
    mapping(address => uint256) public userMintCount;

    // The content identifier of the NFT's metadata.
    string public metadataCid;

    // An array which maps NFT ID's to a shuffled permutation of itself.
    uint256[10**9] public ids;

    struct RoyaltyAddress {
        address id;
        uint256 share;
        uint256 balance;
        uint256 minUnlockTime;
    }

    struct RoyaltyAddressEntry {
        address id;
        uint256 share;
        uint256 minUnlockTime;
    }

    // List of addresses that share royalties from the sales.
    RoyaltyAddress[] public royaltyAddresses;

    event Minted(
        address indexed buyer,
        uint256 amount,
        uint256 price,
        bytes32 hash
    );

    event Revealed(string metadataCid);

    event RoyaltyClaimed(address indexed user, uint256 amount);

    function initialize() public initializer {
        __ERC721_init("Maskbyte", "BYTE");
        __Ownable_init();

        revealed = false;
        maxSupply = 1000;
        maxMintsPerTransaction = 3;
        metadataCid = "bafyreich6lnrqtm5npuldtidxajxiy2u7r6nbz4tak5dlqbv5jdclmimmm/metadata.json";
    }

    function _authorizeUpgrade(address) internal view override onlyOwner {
        return;
    }

    function getNumRoyaltyAddresses() public view returns (uint256) {
        return royaltyAddresses.length;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!revealed) return string(abi.encodePacked("ipfs://", metadataCid));

        require(_exists(id), "uri query for nonexistent token");

        return
            string(
                abi.encodePacked("ipfs://", metadataCid, "/", id.toString())
            );
    }

    function randn(uint256 max) internal view returns (uint256) {
        if (max == 0) return 0;

        return
            uint256(
                keccak256(
                    abi.encode(
                        _msgSender(),
                        block.difficulty,
                        blockhash(block.number - 1)
                    )
                )
            ) % max;
    }

    function reveal(string calldata revealedMetadataCid) external onlyOwner {
        require(!revealed, "nft has already been revealed");

        metadataCid = revealedMetadataCid;
        revealed = true;

        emit Revealed(revealedMetadataCid);
    }

    function mintPublicSale(uint256 numToMint) external payable {
        require(revealed, "public sale not open");
        require(totalSupply() + numToMint <= maxSupply, "no supply left");
        require(numToMint <= maxMintsPerTransaction, "transaction too large");

        uint256 totalPrice = 1 ether * numToMint;
        require(msg.value >= totalPrice, "insufficient funds");

        distributeRoyalties(totalPrice);
        randomlyMint(_msgSender(), numToMint);
        emit Minted(_msgSender(), numToMint, 1 ether, bytes32(0));

        // Refund any remaining ETH.
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    function mintPresale(
        uint256 nonce,
        uint256 price,
        uint256 numToMint,
        uint256 maxNumAllowedToMint,
        bytes memory signature
    ) external payable {
        require(totalSupply() + numToMint <= maxSupply, "no supply left");
        require(
            userMintCount[_msgSender()] + numToMint <= maxNumAllowedToMint,
            "too many attempted to be minted"
        );
        require(numToMint <= maxMintsPerTransaction, "transaction too large");

        uint256 totalPrice = price * numToMint;
        require(msg.value >= totalPrice, "insufficient funds");

        bytes32 hash = mintSignatureHash(
            _msgSender(),
            nonce,
            price,
            maxNumAllowedToMint
        );
        require(hash.recover(signature) == owner(), "invalid signature");

        distributeRoyalties(totalPrice);
        randomlyMint(_msgSender(), numToMint);
        emit Minted(_msgSender(), numToMint, price, hash);

        // Refund any remaining ETH.
        payable(_msgSender()).transfer(msg.value - totalPrice);
    }

    function verifySignature(
        address user,
        uint256 nonce,
        uint256 price,
        uint256 maxNumAllowedToMint,
        bytes memory signature
    ) public view {
        bytes32 hash = mintSignatureHash(
            user,
            nonce,
            price,
            maxNumAllowedToMint
        );
        require(hash.recover(signature) == owner(), "invalid signature");
    }

    function mintSignatureHashToSign(
        address user,
        uint256 nonce,
        uint256 price,
        uint256 maxNumAllowedToMint
    ) public view returns (bytes32) {
        require(_msgSender() == owner(), "invalid signer");
        return mintHash(user, nonce, price, maxNumAllowedToMint);
    }

    function mintSignatureHash(
        address user,
        uint256 nonce,
        uint256 price,
        uint256 maxNumAllowedToMint
    ) internal view returns (bytes32) {
        return
            ECDSAUpgradeable.toEthSignedMessageHash(
                mintHash(user, nonce, price, maxNumAllowedToMint)
            );
    }

    function mintHash(
        address user,
        uint256 nonce,
        uint256 price,
        uint256 maxNumAllowedToMint
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    // address(this),
                    // block.chainid,
                    owner(),
                    user,
                    nonce,
                    price,
                    maxNumAllowedToMint
                )
            );
    }

    function randomlyMint(address user, uint256 amount) internal {
        userMintCount[user] += amount;

        uint256 remainingSupply = maxSupply - totalSupply();
        for (uint256 i = 0; i < amount; i++) {
            uint256 index = randn(remainingSupply);

            uint256 id;
            if (ids[index] == 0) {
                id = index;
            } else {
                id = ids[index];
            }

            if (ids[remainingSupply - 1] == 0) {
                ids[index] = remainingSupply - 1;
            } else {
                ids[index] = ids[remainingSupply - 1];
            }

            _safeMint(user, id + 1);
            remainingSupply--;
        }
    }

    function addRoyaltyAddress(
        address id,
        uint256 percentage,
        uint256 minUnlockTime
    ) internal onlyOwner {
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            if (royaltyAddresses[i].id == id) {
                royaltyAddresses[i].share = percentage;
                return;
            }
        }

        royaltyAddresses.push(RoyaltyAddress(id, percentage, 0, minUnlockTime));
    }

    function addRoyaltyAddresses(RoyaltyAddressEntry[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            addRoyaltyAddress(
                entries[i].id,
                entries[i].share,
                entries[i].minUnlockTime
            );
        }
    }

    function removeRoyaltyAddress(address id) external onlyOwner {
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            RoyaltyAddress memory royaltyAddress = royaltyAddresses[i];
            if (royaltyAddress.id == id) {
                if (i != royaltyAddresses.length - 1) {
                    royaltyAddresses[i] = royaltyAddresses[
                        royaltyAddresses.length - 1
                    ];
                }
                royaltyAddresses.pop();
                if (royaltyAddress.balance > 0) {
                    emit RoyaltyClaimed(
                        royaltyAddress.id,
                        royaltyAddress.balance
                    );
                    payable(royaltyAddress.id).transfer(royaltyAddress.balance);
                }
                return;
            }
        }
        revert("address not found");
    }

    function claimRoyalties() external {
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            RoyaltyAddress memory royaltyAddress = royaltyAddresses[i];
            if (royaltyAddress.id == _msgSender()) {
                if (royaltyAddress.minUnlockTime != 0) {
                    require(
                        block.timestamp >= royaltyAddress.minUnlockTime,
                        "not enough time has passed"
                    );
                }

                if (royaltyAddress.balance > 0) {
                    royaltyAddresses[i].balance = 0;
                    emit RoyaltyClaimed(
                        royaltyAddress.id,
                        royaltyAddress.balance
                    );
                    payable(royaltyAddress.id).transfer(royaltyAddress.balance);
                }
                return;
            }
        }
        revert("ineligible to claim royalties");
    }

    function distributeRoyalties(uint256 amount) internal {
        uint256 maxShares = 0;
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            maxShares += royaltyAddresses[i].share;
        }

        require(maxShares > 0, "max royalty shares is zero");

        uint256 remainingAmount = amount;
        uint256 smallestShareIndex = 0;

        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            royaltyAddresses[i].balance +=
                (amount * royaltyAddresses[i].share) /
                maxShares;
            remainingAmount -= (amount * royaltyAddresses[i].share) / maxShares;

            if (
                royaltyAddresses[smallestShareIndex].share <
                royaltyAddresses[i].share
            ) {
                smallestShareIndex = i;
            }
        }

        royaltyAddresses[smallestShareIndex].balance += remainingAmount;
        remainingAmount = 0;
    }
}
