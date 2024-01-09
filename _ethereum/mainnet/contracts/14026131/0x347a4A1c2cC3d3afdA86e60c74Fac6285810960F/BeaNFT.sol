//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./OwnableUpgradeable.sol";
import "./BeaNFTInternal.sol";

contract BeaNFT is BeaNFTInternal, OwnableUpgradeable {

    event SignerUpdated(address oldSigner, address newSigner);

    function initialize(
        address _signer,
        address genesis,
        string memory baseHash, 
        uint256 baseLimit

    ) public initializer {
        __ERC721_init("BeaNFT", "BEANFT");
        __Ownable_init();
        __baseTokenURI = "https://ipfs.io/ipfs/";
        genesisAddress = genesis;
        signer = _signer;
        __baseHash = baseHash;
        _baseLimit = baseLimit;
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function setSigner(address newSigner) external onlyOwner {
        address oldSigner = signer;
        signer = newSigner;

        emit SignerUpdated(oldSigner, newSigner);
    }

    function mint(
        address account,
        uint256 tokenId,
        bytes calldata signature
    ) public {
        checkBeforeMint(tokenId, account, signature);
        _safeMint(account, tokenId);
    }

    function batchMint(
        address[] calldata accounts,
        uint256[] calldata tokenIds,
        bytes[] calldata signatures
    ) external {
        require(
            accounts.length == tokenIds.length &&
            tokenIds.length == signatures.length,
            "BeaNFT: length mismatch"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], tokenIds[i], signatures[i]);
        }
    }

    function batchMintAccount(
        address account,
        uint256[] calldata tokenIds,
        bytes[] calldata signatures
    ) external {
        require(
            tokenIds.length == signatures.length,
            "BeaNFT: length mismatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            checkBeforeMint(tokenIds[i], account, signatures[i]);
        }

        _batchMintToAccount(account, tokenIds);
    }

    function checkBeforeMint(uint256 tokenId, address account, bytes calldata signature) internal view {
        require(!_exists(tokenId), "BeaNFT: token minted");
        require(subcollection(tokenId) == 1, "BeaNFT: Only winter collection mintable");
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(account, tokenId))
        );
        require(
            recoverSigner(message, signature) == signer,
            "BeaNFT: invalid signature"
        );
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        __baseTokenURI = baseTokenURI;
    }

    function setBaseHash(string memory baseHash, uint256 baseLimit) public onlyOwner {
        __baseHash = baseHash;
        _baseLimit = baseLimit;
    }
}
