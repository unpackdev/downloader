// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./NFTCClaimlist.sol";
import "./NFTCWhitelist.sol";

/**
 * @title Moonray Presale Passes
 * @author @NiftyMike, NFT Culture
 * @dev Mint presale passes for Moonray.game. The presale passes can be redeemed on
 * Stacks, decentralized apps and smart contracts for Bitcoin, by calling the redeem
 * function and passing your Stacks wallet address.
 */
contract MoonrayPresalePassBase is
    ERC1155Supply,
    Ownable,
    NFTCClaimlist,
    NFTCWhitelist
{
    event PassRedeemed(address indexed redeemer, string indexed stxWallet);

    uint256 public constant MAX_MINT_PER_TRANS = 99;
    uint256 public constant PRESALE_PASS_TOKEN = 1;

    uint256 public pricePerToken;
    uint256 public maxTokensForSale;
    uint256 public startingBlockNumber;

    bool public mintingActive;
    bool public burningActive;

    mapping(address => string) internal _stxWallets;

    uint256 internal _mintCounter;

    constructor(
        string memory __uri,
        uint256 __startingBlockNumber,
        uint256 __maxTokensForSale,
        uint256 __pricePerToken
    ) ERC1155(__uri) {
        startingBlockNumber = __startingBlockNumber;
        maxTokensForSale = __maxTokensForSale;
        pricePerToken = __pricePerToken;
    }

    function setMintingState(
        bool __mintingActive,
        uint256 __startingBlockNumber,
        uint256 __pricePerToken,
        bool __burningActive
    ) external onlyOwner {
        mintingActive = __mintingActive;

        if (__startingBlockNumber > 0) {
            startingBlockNumber = __startingBlockNumber;
        }

        if (__pricePerToken > 0) {
            pricePerToken = __pricePerToken;
        }

        burningActive = __burningActive;
    }

    function setNewURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintPassFromClaim(bytes32[] memory claim) external payable {
        require(block.number > startingBlockNumber, 'Not started');
        require(mintingActive, 'Not active');

        bytes32[][] memory claims = new bytes32[][](1);
        claims[0] = claim;

        _mintPassFromClaim(_msgSender(), claims, 1);
    }

    function mintPassesFromWhitelist(uint256 count) external payable {
        require(block.number > startingBlockNumber, 'Not started');
        require(mintingActive, 'Not active');
        require(0 < count && count <= MAX_MINT_PER_TRANS, 'Invalid count');
        require(msg.value >= pricePerToken * count, 'Invalid price');
        require(count <= _getWhitelistAmount(_msgSender()), 'Too many');

        _mintTokens(_msgSender(), count);

        _decrementWhitelistAmount(_msgSender(), count);
    }

    function redeemPresalePass(string memory stxWallet) external {
        require(burningActive, 'Burning off');
        require(bytes(stxWallet).length == 41, 'Invalid wallet length'); // sufficient for UTF-8 encoded strings.
        require(bytes(stxWallet)[0] == 'S', 'Invalid wallet format');

        _burn(_msgSender(), PRESALE_PASS_TOKEN, 1);

        emit PassRedeemed(_msgSender(), stxWallet);
    }

    function _mintPassFromClaim(
        address minter,
        bytes32[][] memory claims,
        uint256 count
    ) internal {
        require(0 < count && count <= MAX_MINT_PER_TRANS, 'Invalid count');
        require(msg.value >= pricePerToken * count, 'Invalid price');
        require(claims.length == count, 'Mismatch claims');

        // Verify each claim passed in, make sure its valid.
        for (uint256 i = 0; i < claims.length; i++) {
            require(
                _validateClaim(
                    claims[i],
                    _generateLeaf(minter, _getNextIndex(minter) + i)
                ),
                'Claim invalid'
            );
        }

        _mintTokens(minter, count);

        _incrementClaimIndex(minter, count);
    }

    function _mintTokens(address minter, uint256 count) internal {
        require(minter != address(0), 'Bad address');
        require(_mintCounter + count <= maxTokensForSale, 'Limit exceeded');

        _mintCounter += count;
        _mint(minter, PRESALE_PASS_TOKEN, count, '');
    }
}
