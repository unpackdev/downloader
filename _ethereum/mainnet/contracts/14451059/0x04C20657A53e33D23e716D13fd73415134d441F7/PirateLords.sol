// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Mintable.sol";
import "./VRFConsumerBaseUpgradeable.sol";

contract OwnableDelegateProxy {

} // solhint-disable-line no-empty-blocks

/**
 * @notice Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 * @dev used to whitelist OpenSea so the user does not have to pay fees when listing
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PirateLords is
    Mintable,
    PaymentSplitterUpgradeable,
    IERC2981Upgradeable,
    UUPSUpgradeable,
    VRFConsumerBaseUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public constant VERSION = 2;

    string public baseTokenURI;
    bool public isRevealed;
    address private _openSeaProxyRegistryAddress;
    address private _raribleProxyRegistryAddress;

    /**
     * Chainlink VRF
     */
    bytes32 private keyHash;
    uint256 private fee;
    bytes32 private randomizationRequestId;
    uint256 public shiftValue;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), ERROR_TOKEN_ID);

        if (isRevealed) {
            uint256 shiftedIndex = ((shiftValue + tokenId) % MAX_SUPPLY);
            return string(abi.encodePacked(baseTokenURI, shiftedIndex.toString()));
        } else {
            return UNREVEALED_URI;
        }
    }

    function contractURI() external pure returns (string memory) {
        return "ipfs://QmYbkxUS7PZStruqzjfPyUPr96Ej1XWa5Exqi4Y8EoPLmo";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Reveal the art
     * @dev Set base
     * @dev Only owner can use this
     */
    function reveal(string memory _baseTokenURI) external onlyOwner {
        require(!isRevealed, ERROR_REVEALED);
        isRevealed = true;
        baseTokenURI = _baseTokenURI;
    }

    /**
     * Will request a random number from Chainlink to be stored privately in the contract
     */
    function generateSeed() external onlyOwner {
        require(shiftValue == 0, "Already generated");
        require(randomizationRequestId == 0, "Randomization already started");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        randomizationRequestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback when a random number gets generated
     * @param requestId id of the request sent to Chainlink
     * @param randomNumber random number returned by Chainlink
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        require(requestId == randomizationRequestId, "Invalid requestId");
        require(shiftValue == 0, "Already generated");
        uint256 tempShift = randomNumber % MAX_SUPPLY;
        // if random number is multiple of MAX_SUPPLY, use 1
        if (tempShift == 0) {
            shiftValue = 1;
        } else {
            shiftValue = tempShift;
        }
    }

    /**
     * For future use, implements the future standard
     * @dev We use a contract global royalty
     * @param tokenId Id of the token
     * @param salePrice Price of sale
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        pure
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(0xe44ADFA6BBec84B006b9735B041C97c13d0de15A);
        royaltyAmount = (salePrice * 750) / 10000;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's ProxyRegistry proxy accounts to
     * enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Approve OpenSea and Rarible proxy contract for gas-less trading
        ProxyRegistry openSeaProxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
        ProxyRegistry raribleProxyRegistry = ProxyRegistry(_raribleProxyRegistryAddress);
        if (
            address(openSeaProxyRegistry.proxies(owner)) == operator ||
            address(raribleProxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * UUPS upgradeable
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
