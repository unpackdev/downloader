// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SignatureChecker.sol";
import "./MessageHashUtils.sol";
import "./ERC6551AccountLib.sol";
import "./IERC6551Registry.sol";

import "./RGBPOINTS.sol";

interface Initializable {
    function initialize(address) external;
}

contract RGBNFT is ERC721, Ownable {
    error InvalidOracleSignature();
    error AlreadyClaimed();
    error ClaimPeriodOver();
    error Soulbound();

    event UpdatedOracle(address oracle);
    event UpdatedClaimOver(uint256 claimOver);
    event Locked(uint256 tokenId);

    bytes4 constant ERC5192_INTERFACE_ID = 0xb45a3c0e;
    address public immutable registry = 0x000000006551c19487814612e58FE06813775758;
    address public immutable accountProxy = 0x55266d75D1a14E4572138116aF39863Ed6596E7F;
    address public immutable accountImplementation = 0x41C8f39463A868d3A88af00cd0fe7102F30E44eC;

    RGBPOINTS public token;
    address public oracle;
    uint256 public claimOver = 1703462400;

    mapping(address => uint256) public claimed;

    constructor(address initialOwner, address _oracle) ERC721("RGBNFT", "RGBNFT") Ownable(initialOwner) {
        token = new RGBPOINTS(initialOwner);
        oracle = _oracle;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit UpdatedOracle(_oracle);
    }

    function setClaimOver(uint256 _claimOver) external onlyOwner {
        claimOver = _claimOver;
        emit UpdatedClaimOver(_claimOver);
    }

    function claim(address to, uint256 points, bytes calldata oracleSignature) external payable {
        // Validate claim period
        if (block.timestamp > claimOver) revert ClaimPeriodOver();

        // Validate oracle signature
        bytes32 oracleHash = MessageHashUtils.toEthSignedMessageHash(abi.encode(to, points));
        if (!SignatureChecker.isValidSignatureNow(oracle, oracleHash, oracleSignature)) revert InvalidOracleSignature();

        // Ensure points cannot be double claimed
        if (claimed[to] >= points) revert AlreadyClaimed();

        // Convert owner address to token ID
        uint256 tokenId = uint256(uint160(to));

        if (claimed[to] == 0) {
            // Mint NFT
            emit Transfer(address(0), to, tokenId);
            // Mark as soulbound
            emit Locked(tokenId);
        }

        // Calculate points to mint
        uint256 pointsToMint = points - claimed[to];

        // Calculate TBA address
        address tba = ERC6551AccountLib.computeAddress(registry, accountProxy, 0, block.chainid, address(this), tokenId);

        // Deploy TBA if it doesn't exist
        if (tba.code.length == 0) {
            IERC6551Registry(registry).createAccount(accountProxy, 0, block.chainid, address(this), tokenId);
            Initializable(tba).initialize(accountImplementation);
        }

        // mark as claimed
        claimed[to] = points;

        // Mint ERC20 tokens to address
        token.mint(tba, pointsToMint);
    }

    function withdraw() external {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function locked(uint256) external pure returns (bool) {
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == ERC5192_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }

        if (claimed[owner] > 0) return 1;

        return 0;
    }

    function _ownerOf(uint256 tokenId) internal view virtual override returns (address) {
        address owner = address(uint160(tokenId));

        if (claimed[owner] > 0) return owner;

        return address(0);
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "https://rgbpoints.xyz/api/metadata/";
    }

    function _update(address, uint256, address) internal virtual override returns (address) {
        revert Soulbound();
    }

    function _approve(address, uint256, address, bool) internal virtual override {
        revert Soulbound();
    }

    function _setApprovalForAll(address, address, bool) internal virtual override {
        revert Soulbound();
    }
}
