// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract RoboLobsters is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public nextTokenId = 1;
    uint256 public price = 0.35 ether;

    // maximum value of an unsigned 256-bit integer
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // the supply is 100, but offset by 2 because nextTokenId starts at 1
    // and is incremented _after_ the mint call
    // this lets us skip a <= check to save some gas
    uint256 public constant SUPPLY = 102;

    string public _baseTokenURI;

    bool public saleActive = false;

    // there are only 100 total lobsters, so we can use 256 bytes to store 100 allowlist spots
    uint256[1] _claimGroups = [MAX_INT];

    address private p = 0xD5090279d8b3a7e6b3351Aa2A5B98Aa0C0afcCC2;
    address private r = 0x03838BEb6AE40E4D48d8ECd874bbf855A94B311E;
    address _freeSigner = address(0);
    address _paidSigner = address(0);

    event Mint(address purchaser);
    event SaleStateChange(bool newState);

    constructor(
        string memory baseURI,
        address freeSigner,
        address paidSigner
    ) ERC721("RoboLobsters", "ROBOLOBSTER") {
        _baseTokenURI = baseURI;
        _freeSigner = freeSigner;
        _paidSigner = paidSigner;
    }

    function mint(bytes calldata _signature, uint256 spotId) external payable {
        uint256 _nextTokenId = nextTokenId;
        require(saleActive, "SALE_INACTIVE");
        require(_nextTokenId + 1 < SUPPLY, "SOLD_OUT");
        require(msg.value == price, "INCORRECT_ETH");
        require(
            _verifyPaid(
                keccak256(abi.encodePacked(msg.sender, spotId)),
                _signature
            ),
            "INVALID_SIGNATURE"
        );

        _claimAllowlistSpot(spotId);
        _mint(msg.sender, _nextTokenId);

        unchecked {
            _nextTokenId++;
        }

        nextTokenId = _nextTokenId;
        emit Mint(msg.sender);
    }

    function freeMint(bytes[] calldata _signatures, uint256[] calldata spotIds)
        external
    {
        uint256 _nextTokenId = nextTokenId;
        require(saleActive, "SALE_INACTIVE");
        require(_nextTokenId + spotIds.length < SUPPLY, "SOLD_OUT");

        for (uint256 i = 0; i < spotIds.length; i++) {
            require(
                _verifyFree(
                    keccak256(abi.encodePacked(msg.sender, spotIds[i])),
                    _signatures[i]
                ),
                "INVALID_SIGNATURE"
            );
            _claimAllowlistSpot(spotIds[i]);
            _mint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
        emit Mint(msg.sender);
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Admin
    function devMint(address receiver, uint256 qty) external onlyOwner {
        uint256 _nextTokenId = nextTokenId;
        require(_nextTokenId + qty < SUPPLY, "SOLD_OUT");

        for (uint256 i = 0; i < qty; i++) {
            _mint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
    }

    function setFreeSigner(address signer) external onlyOwner {
        _freeSigner = signer;
    }

    function setPaidSigner(address signer) external onlyOwner {
        _paidSigner = signer;
    }

    function flipSaleState() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStateChange(saleActive);
    }

    function withdraw() external onlyOwner {
        (bool s1, ) = p.call{value: (address(this).balance * 70) / 100}("");
        (bool s2, ) = r.call{value: (address(this).balance)}("");

        require(s1 && s2, "Transfer failed");
    }

    // internal
    // this technique is adopted from https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
    // it saves buyers from expensive SSTORE operations when marking an allowlist spot as "used"
    function _claimAllowlistSpot(uint256 spotId) internal {
        // make sure the spot ID can fit somewhere in the array
        // (ie, spotId of 1000 if claimGroups can only store 256 bytes, is invalid)
        require(spotId < _claimGroups.length * 256, "INVALID_ID");

        uint256 groupIndex;
        uint256 spotIndex;
        uint256 localGroup;
        uint256 storedBit;

        unchecked {
            // which index of the claimGroups array the provided ID falls into
            // for ex, if the ID is 256, then we're in group[1]
            // (group[0] would be 0-255, group[1] would be 256-511, etc)
            groupIndex = spotId / 256;
            // which of the 256 bits in that group the ID falls into
            spotIndex = spotId % 256;
        }

        // assign the group we're interested into a temporary variable
        localGroup = _claimGroups[groupIndex];

        // shift the group bits to the right by the number of bits at the specified index
        // this puts the bit we care about at the rightmost position
        // bitwise AND the result with a 1 to zero-out everything except the bit being examined
        storedBit = (localGroup >> spotIndex) & uint256(1);
        // if we got a 1, the spot was already used
        require(storedBit == 1, "ALREADY_MINTED");
        // zero-out the bit at the specified index by shifting it back to its original spot, and then bitflip
        localGroup = localGroup & ~(uint256(1) << spotIndex);

        // store the modified group back into the array
        // this modified group will have the spot ID set to 1 at its corresponding index
        _claimGroups[groupIndex] = localGroup;
    }

    function _verifyFree(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(_freeSigner != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _freeSigner;
    }

    function _verifyPaid(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(_paidSigner != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _paidSigner;
    }
}
