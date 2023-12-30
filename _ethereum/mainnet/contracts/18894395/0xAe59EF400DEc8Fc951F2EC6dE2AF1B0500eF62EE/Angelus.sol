// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IVerifier.sol";
import "./ITokenURI.sol";
import "./SSTORE2.sol";
import "./Base64.sol";

/// @author xaltgeist, with consultation from 113
/// @title Angelus
contract Angelus is
    Initializable,
    ERC721Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable
{
    /// @dev The ZK verifiers
    enum VerifierType {
        Price,
        Purchase,
        Image,
        Reveal
    }

    /// @dev Data structure for a ZK verifier
    struct Verifier {
        VerifierType verifierType;
        address addr;
        string sourceCode;
    }

    event PriceProven(address prover);
    event ImageProven(address prover);
    event ImageRevealed(address prover);
    event TokenURIEndpointSet(address tokenURIEndpoint);
    event ContractSealed(uint timestamp);
    event VerifierUpgraded(
        VerifierType verifier,
        address oldAddress,
        address newAddress
    );

    /// @dev The contract can be sealed to prevent any further changes
    modifier notSealed() {
        require(!isSealed, "Contract is sealed");
        _;
    }

    /// @dev Proofs are only accepted after the state roots are set
    modifier forSale() {
        require(stateRootsSet, "Not for sale until state roots are set");
        _;
    }

    // Contract metadata
    string public version;
    string public title;
    bool public isSealed;
    bool public stateRootsSet;
    bool public priceProvenToExist;

    // ZK verifiers
    Verifier public priceVerifier;
    Verifier public purchaseVerifier;
    Verifier public imageVerifier;
    Verifier public revealVerifier;

    // Endpoint for tokenURI
    address public tokenURIEndpoint;

    // Prime field
    uint public P;
    uint public MAX_VALUE;
    uint public QUANTIZATION_FACTOR;

    // State roots
    uint[32] public imageRowCommits;
    uint[32] public imageRowSumCommits;

    // Record of which addresses have proven the price and image
    mapping(address => bool) public priceProven;
    mapping(address => bool) public imageProven;

    // Storage pointers
    mapping(uint => address) public imageStoragePointers;
    address public abiStoragePointer;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Initialization and Proxy Administration
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[4] calldata _verifierAddresses,
        string[4] calldata _verifierSources
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721_init("Angelus", "ANGELUS");

        version = "Version 1.0";
        title = "Angelus";

        P = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        MAX_VALUE = P - 1;
        QUANTIZATION_FACTOR = MAX_VALUE / 10;

        priceVerifier.verifierType = VerifierType.Price;
        priceVerifier.addr = _verifierAddresses[0];
        priceVerifier.sourceCode = _verifierSources[0];

        purchaseVerifier.verifierType = VerifierType.Purchase;
        purchaseVerifier.addr = _verifierAddresses[1];
        purchaseVerifier.sourceCode = _verifierSources[1];

        imageVerifier.verifierType = VerifierType.Image;
        imageVerifier.addr = _verifierAddresses[2];
        imageVerifier.sourceCode = _verifierSources[2];

        revealVerifier.verifierType = VerifierType.Reveal;
        revealVerifier.addr = _verifierAddresses[3];
        revealVerifier.sourceCode = _verifierSources[3];
    }

    /// @notice Sets the state roots for the image
    /// @param _rowCommits The commitments for each row
    /// @param _rowSumCommits  The commitments for each row sum
    function setStateRoots(
        uint256[32] calldata _rowCommits,
        uint256[32] calldata _rowSumCommits
    ) public onlyOwner notSealed {
        require(!stateRootsSet, "State roots already set");
        imageRowCommits = _rowCommits;
        imageRowSumCommits = _rowSumCommits;
        stateRootsSet = true;
        _safeMint(address(this), 0);
    }

    /// @notice Required override for authorization of upgrade
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner notSealed {}

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Zero Knowledge Proof Verification and Purchase Functions
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Proves the price of the artwork
    ///         The price is encoded as a 32x32 pixel image
    ///         The image encodes the price as the sum of all pixel values
    ///         Each pixel value is a uint256 between 0 and P-1, inclusive
    /// @param _proof The zk proof
    /// @param _pubSignals The zk public signals
    function provePrice(
        uint256[24] memory _proof,
        uint256[33] memory _pubSignals
    ) public forSale {
        require(!priceProven[msg.sender], "Price already proven");
        require(
            address(uint160(_pubSignals[0])) == msg.sender,
            "Invalid sender"
        );
        bool result = IVerifier(priceVerifier.addr).verifyProof(
            _proof,
            _pubSignals
        );
        require(result, "Price proof failed");
        priceProven[msg.sender] = true;
        if (!priceProvenToExist) {
            priceProvenToExist = true;
        }
        emit PriceProven(msg.sender);
    }

    /// @notice Proves knowledge of the image.
    ///         The image encodes the price as the sum of all pixel values.
    ///         Each pixel value is a uint256 between 0 and P-1, inclusive.
    /// @param _proofs An array of 32 proofs, one for each row
    /// @param _pubSignals An array of 32 zk public signals, one for each row.
    function proveImage(
        uint[24][32] calldata _proofs,
        uint[3][32] calldata _pubSignals
    ) public forSale {
        for (uint8 i; i < 32; i++) {
            _proveRow(i, _proofs[i], _pubSignals[i]);
        }
        imageProven[msg.sender] = true;
        if (!priceProvenToExist) {
            priceProvenToExist = true;
        }
        emit ImageProven(msg.sender);
    }

    /// @notice Purchases the artwork, if the purchaser can prove they know the price
    /// @param _priceProof The zk proof for the price
    /// @param _pricePubSignals The zk public signals for the price
    /// @param _imageProofs An array of 32 proofs, one for each row
    /// @param _imagePubSignals An array of 32 zk public signals, one for each row
    function purchaseWithImageProof(
        uint256[24] calldata _priceProof,
        uint256[34] calldata _pricePubSignals,
        uint[24][32] calldata _imageProofs,
        uint[3][32] calldata _imagePubSignals
    ) public payable forSale {
        proveImage(_imageProofs, _imagePubSignals);
        _validatePurchase(_priceProof, _pricePubSignals);
        _transfer(ownerOf(0), msg.sender, 0);
    }

    /// @notice Purchases the artwork, if the purchaser can prove they know the price
    /// @param _proof The zk proof for the price
    /// @param _pubSignals The zk public signals
    function purchase(
        uint256[24] calldata _proof,
        uint256[34] calldata _pubSignals
    ) public payable forSale {
        require(imageProven[msg.sender], "Purchaser must prove the image");
        _validatePurchase(_proof, _pubSignals);
        _transfer(ownerOf(0), msg.sender, 0);
    }

    /// @notice Permanently reveals the image that encodes the price of the artwork
    /// @param _proofs An array of 32 proofs, one for each row
    /// @param _pubSignals An array of 32 zk public signals, one for each row
    function revealImage(
        uint[24][32] calldata _proofs,
        uint[35][32] calldata _pubSignals
    ) public forSale {
        require(ownerOf(0) == msg.sender, "Only the owner can reveal");

        bytes memory slice;
        uint start = 4 + 24 * 32 * 32; // The starting location of the first row within the _pubSignals calldata
        for (uint i; i < 32; i++) {
            require(
                address(uint160(_pubSignals[i][32])) == msg.sender,
                "Invalid sender"
            );

            bool result = IVerifier(revealVerifier.addr).verifyProof(
                _proofs[i],
                _pubSignals[i]
            );
            require(result, "Reveal proof failed");

            assembly {
                // Create a dynamic bytes array of the correct size
                slice := mload(0x40)
                mstore(slice, 1024) // 1024 is the size of the row in bytes
                // Copy the slice
                calldatacopy(add(slice, 32), start, 1024)
                // Update free memory pointer
                mstore(0x40, add(slice, add(32, 1024)))
            }
            imageStoragePointers[i] = SSTORE2.write(slice);
            start += 1120; // 1024 bytes for the row + 96 bytes for the other public signals
        }

        emit ImageRevealed(msg.sender);
    }

    /// @notice Proves the sender knows the pixel values of a row of the price-image
    /// @param rowIndex The index of the row of pixels being proven
    /// @param _proof The zk proof
    /// @param _pubSignals The zk public signals
    function _proveRow(
        uint8 rowIndex,
        uint256[24] calldata _proof,
        uint256[3] calldata _pubSignals
    ) internal view {
        require(
            address(uint160(_pubSignals[0])) == msg.sender,
            "Invalid sender"
        );
        require(
            imageRowCommits[rowIndex] == _pubSignals[1],
            "Row commitment does not match"
        );
        require(
            imageRowSumCommits[rowIndex] == _pubSignals[2],
            "Row sum commitment does not match"
        );

        bool result = IVerifier(imageVerifier.addr).verifyProof(
            _proof,
            _pubSignals
        );
        require(result, "Image proof failed");
    }

    /// @notice Validates the purchase proof and the purchase price
    /// @param _proof The zk proof
    /// @param _pubSignals The zk public signals
    function _validatePurchase(
        uint[24] calldata _proof,
        uint[34] calldata _pubSignals
    ) internal {
        require(ownerOf(0) == address(this), "Must be owned by this contract");
        require(
            address(uint160(_pubSignals[1])) == msg.sender,
            "Invalid sender"
        );
        require(
            msg.value == _pubSignals[0] % 1000 gwei,
            "Must send the correct price"
        );
        bool result = IVerifier(purchaseVerifier.addr).verifyProof(
            _proof,
            _pubSignals
        );
        require(result, "Purchase proof failed");
        if (!priceProvenToExist) {
            priceProvenToExist = true;
        }
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * UI Functions
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Returns the tokenURI for the piece
    /// @param tokenId The token ID
    /// @return The tokenURI for the piece
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (tokenURIEndpoint != address(0)) {
            return ITokenURI(tokenURIEndpoint).tokenURI(tokenId);
        }
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Angelus","description":"Angelus by Mathcastles","image": "data:image/svg+xml;base64,',
                        Base64.encode(
                            bytes(
                                '<?xml version="1.0" encoding="UTF-8"?><svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><defs><style>.c1{fill:#181818;}</style></defs><rect class="c1" width="512" height="512"/></svg>'
                            )
                        ),
                        '"}'
                    )
                )
            );
    }

    /// @notice Returns the source code for a ZK verifier
    /// @param verifier The type of the ZK verifier
    function getVerifierSourceCode(
        VerifierType verifier
    ) public view returns (string memory) {
        if (verifier == VerifierType.Price) {
            return priceVerifier.sourceCode;
        } else if (verifier == VerifierType.Purchase) {
            return purchaseVerifier.sourceCode;
        } else if (verifier == VerifierType.Image) {
            return imageVerifier.sourceCode;
        } else if (verifier == VerifierType.Reveal) {
            return revealVerifier.sourceCode;
        } else {
            revert("Invalid verifier");
        }
    }

    /// @notice Returns the ABI of this contract as a JSON string
    /// @return The ABI JSON string
    function abiString() public view returns (string memory) {
        if (abiStoragePointer != address(0)) {
            bytes memory b = SSTORE2.read(abiStoragePointer);
            return string(b);
        }
        return "";
    }

    /// @notice Returns the build info for the ZK verifiers and dependencies
    /// @return result The build info
    function getVerifierBuildInfo() public pure returns (string memory) {
        return
            string.concat(
                "{",
                '"circom":"2.1.6",',
                '"circomlib":"2.0.5",',
                '"circomlibjs":"0.1.7",',
                '"snarkjs":"0.7.2",',
                '"solidity":"0.8.20",',
                '"powers_of_tau":"powersOfTau28_hez_final.ptau(https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final.ptau)",',
                '"ptau_blake2b_hash":"55c77ce8562366c91e7cda394cf7b7c15a06c12d8c905e8b36ba9cf5e13eb37d1a429c589e8eaba4c591bc4b88a0e2828745a53e170eac300236f5c1a326f41a"',
                "}"
            );
    }

    /// @notice Returns the price-image with its pixel values quantized to 0-9
    /// @return result The quantized price-image
    function quantizedImage() public view returns (uint[32][32] memory result) {
        for (uint8 i; i < 32; i++) {
            result[i] = _quantizeRow(_readRow(i));
        }
    }

    /// @notice Returns the unquantized price-image
    /// @return result The unquantized price-image
    function rawImage() public view returns (uint[32][32] memory result) {
        for (uint i; i < 32; i++) {
            result[i] = _readRow(i);
        }
    }

    /// @notice Quantizes a uint256 between 0 and P to 0-9
    /// @param x The uint256 to quantize
    /// @return result The quantized uint256
    function quantizeUint(uint256 x) public view returns (uint256) {
        if (x >= MAX_VALUE) {
            return 9;
        }
        return (x / QUANTIZATION_FACTOR);
    }

    /// @notice Returns the pixel values of a row of the price-image
    /// @param index The index of the row
    /// @return row The pixel values of the row
    function _readRow(uint index) internal view returns (uint[32] memory row) {
        if (imageStoragePointers[index] != address(0)) {
            bytes memory b = SSTORE2.read(imageStoragePointers[index]);
            row = abi.decode(b, (uint[32]));
        }
    }

    /// @notice Quantizes the pixel values of a row of the price-image
    /// @param row The pixel values of the row
    /// @return row The quantized pixel values of the row
    function _quantizeRow(
        uint[32] memory row
    ) internal view returns (uint[32] memory) {
        for (uint i; i < 32; i++) {
            row[i] = quantizeUint(row[i]);
        }
        return row;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Admin-Only Functions
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    /// @notice Seals the contract, preventing any further changes
    function sealContract() external onlyOwner notSealed {
        isSealed = true;
        emit ContractSealed(block.timestamp);
    }

    /// @notice Sets the tokenURI endpoint
    /// @param _tokenURIEndpoint The new tokenURI endpoint
    function setTokenURIEndpoint(
        address _tokenURIEndpoint
    ) external onlyOwner notSealed {
        tokenURIEndpoint = _tokenURIEndpoint;
        emit TokenURIEndpointSet(_tokenURIEndpoint);
    }

    /// @notice Upgrades a ZK verifier
    /// @param verifier The ZK verifier to upgrade
    /// @param newAddr The new ZK verifier address
    /// @param newSource The new ZK verifier source code
    function upgradeVerifier(
        VerifierType verifier,
        address newAddr,
        string calldata newSource
    ) external onlyOwner notSealed {
        Verifier storage v;

        if (verifier == VerifierType.Price) {
            v = priceVerifier;
        } else if (verifier == VerifierType.Purchase) {
            v = purchaseVerifier;
        } else if (verifier == VerifierType.Image) {
            v = imageVerifier;
        } else if (verifier == VerifierType.Reveal) {
            v = revealVerifier;
        } else {
            revert("Invalid verifier");
        }

        address oldAddr = v.addr;
        v.addr = newAddr;
        v.sourceCode = newSource;

        emit VerifierUpgraded(verifier, oldAddr, newAddr);
    }

    /// @notice Sets the ABI JSON string for this contract
    /// @param _abiString The new ABI JSON string
    function setABIString(string memory _abiString) public onlyOwner notSealed {
        abiStoragePointer = SSTORE2.write(bytes(_abiString));
    }

    /// @notice Withdraws the contract balance
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * ERC721 Receiver; Fallback; Receive Functions
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Receives ether
    receive() external payable {}

    /// @notice Fallback function
    fallback() external payable {
        revert(abiString());
    }
}
