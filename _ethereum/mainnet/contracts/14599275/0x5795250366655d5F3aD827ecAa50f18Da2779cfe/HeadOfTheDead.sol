//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

interface ITokehands {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

error DirectClaim();
error HashError();
error QtyZero();
error SoldOut();
error IncorrectFunds();
error MaxPerTransaction();
error PublicNotActive();
error TokehandsNotActive();
error InvalidAddress();
error NotYours();
error WithdrawFailed();

contract HeadOfTheDead is ERC721A, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 266;
    uint256 public constant PRICE = 0.055 ether;
    uint256 public constant MAX_PER_PUBLIC_MINT = 3;
    string public contractBaseURI;
    bool public isPublicSaleActive = false;
    bool public isTokehandsClaimActive = false;
    bool public isRevealed = false;
    address private burnContract;
    address private tokehandsAddress;
    address private signerAddress;
    address private withdrawalAddress;

    mapping(uint256 => bool) private claimedTokehands;
    mapping(string => bool) private usedNonces;

    constructor(
        string memory _metadataURI,
        address _deployedTokehands,
        address _signerAddress,
        address _withdrawalAddress
    ) ERC721A("Head of the Dead", "HOTD") {
        contractBaseURI = _metadataURI;
        tokehandsAddress = _deployedTokehands;
        signerAddress = _signerAddress;
        withdrawalAddress = _withdrawalAddress;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(withdrawalAddress).call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }

    function withdrawTokens(IERC20 token) public onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @notice Allows someone to check if a tokehand has been claimed for a skull.
     */
    function hasTokehandBeenClaimed(uint256[] memory _tokehandsIds)
        public
        view
        returns (bool[] memory)
    {
        uint256 count = _tokehandsIds.length;
        bool[] memory result = new bool[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = claimedTokehands[_tokehandsIds[i]];
        }

        return result;
    }

    function _baseURI() internal view override returns (string memory) {
        return contractBaseURI;
    }

    /**
     * @dev Bot Security
     * Checks that a mint was initiated from our website
     */
    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == signerAddress;
    }

    /**
     * @dev Free Mint
     * For Giveaways / Marketing
     */
    function mintForAddresses(address[] memory _receivers) public onlyOwner {
        if (totalSupply().add(_receivers.length) > MAX_SUPPLY - 1) {
            revert SoldOut();
        }

        for (uint256 i = 0; i < _receivers.length; i++) {
            _safeMint(_receivers[i], 1);
        }
    }

    /**
     * @dev Public Mint
     * Mint tokens during mint perio
     */
    function mint(
        bytes32 hash,
        bytes memory signature,
        string memory nonce,
        uint256 qty
    ) external payable {
        uint256 totalMinted = totalSupply();
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, qty, nonce));

        if (!matchAddresSigner(hash, signature)) {
            revert DirectClaim();
        }
        if (!isPublicSaleActive) {
            revert PublicNotActive();
        }
        if (usedNonces[nonce]) {
            revert HashError();
        }
        if (hash != msgHash) {
            revert HashError();
        }
        if (qty > MAX_PER_PUBLIC_MINT) revert MaxPerTransaction();
        if (qty < 1) revert QtyZero();
        if (totalMinted.add(qty) > MAX_SUPPLY - 1) revert SoldOut();
        if (msg.value != PRICE * qty) revert IncorrectFunds();

        usedNonces[nonce] = true;
        _safeMint(msg.sender, qty);
    }

    /**
     * @dev Tokehands Redeem
     * Free claim for tokehands holder
     */
    function tokehandsClaim(uint256[] memory _tokehandsIds) public {
        uint256 totalMinted = totalSupply();

        if (!isTokehandsClaimActive) {
            revert TokehandsNotActive();
        }

        if (totalMinted.add(_tokehandsIds.length) > MAX_SUPPLY - 1)
            revert SoldOut();

        for (uint256 i; i < _tokehandsIds.length; i++) {
            uint256 tokenId = _tokehandsIds[i];
            if (
                tokehandsOwner(tokenId) == msg.sender &&
                !claimedTokehands[tokenId]
            ) {
                claimedTokehands[tokenId] = true;
                _safeMint(msg.sender, 1);
            } else {
                revert NotYours();
            }
        }
    }

    function tokehandsOwner(uint256 tokenId) public view returns (address) {
        return ITokehands(tokehandsAddress).ownerOf(tokenId);
    }

    function setTokehandsAddress(address _tokehandsAddress) external onlyOwner {
        tokehandsAddress = _tokehandsAddress;
    }

    function setWithdrawalAddress(address _withdrawalAddress)
        external
        onlyOwner
    {
        withdrawalAddress = _withdrawalAddress;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleTokehandsClaim() external onlyOwner {
        isTokehandsClaimActive = !isTokehandsClaimActive;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        contractBaseURI = _baseUri;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }
}
