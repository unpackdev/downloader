//SPDX-License-Identifier: GPL-3.0

/// @title The LilNouns ERC-721 token

import "./Ownable.sol";
import "./INounsSeeder.sol";
import "./INounsToken.sol";
import "./ILilNounsToken.sol";
import "./ILilNounsDescriptor.sol";

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

import "./IProxyRegistry.sol";
import "./base64.sol";

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░ LilNouns ░░░░░░░░░░░░░░░░ *
 *********************************/

/*
A LIL NOUN,
OF A NOUN,
EVERY DAY, 
FOREVER.
@thelilnouns
*/

pragma solidity ^0.8.6;

contract LilNounsToken is
    ILilNounsToken,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable
{
    uint256 private price = 0.15 ether;
    uint256 public numTokensMinted;

    bool public allSalesPaused = true;
    bool public reservedMintsLocked = false;

    // An address who has permissions to mint Nouns
    address public minter;

    address public nounsTokenContract =
        0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;

    // The nouns DAO address
    address public nounsDAO = 0x0BC3807Ec262cB779b38D65b38158acC3bfedE10;

    uint256 public nounsTokenIndexOffset;

    INounsToken public nounsToken;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // The LilNouns token URI descriptor
    ILilNounsDescriptor public descriptor;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Whether the seeder can be updated
    bool public isNounsTokenLocked;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, "Minter is locked");
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, "Descriptor is locked");
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, "Seeder is locked");
        _;
    }

    /**
     * @notice Require that the nounsToken has not been locked.
     */
    modifier whenNounsTokenNotLocked() {
        require(!isNounsTokenLocked, "Nouns Token is locked");
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    /**
     * @notice Require that the sender is the nouns DAO.
     */
    modifier onlyNounsDAO() {
        require(msg.sender == nounsDAO, "Sender is not the nouns DAO");
        _;
    }

    constructor(
        address _nounsDAO,
        INounsToken _nounsToken,
        ILilNounsDescriptor _descriptor,
        INounsSeeder _seeder
    ) ERC721("lilnoun", "LILNOUNS") Ownable() {
        nounsDAO = _nounsDAO;
        nounsToken = _nounsToken;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = IProxyRegistry(
            0xa5409ec958C83C3f309868babACA7c86DCB077c1
        );
    }

    function fetchSeeds(uint256 tokenId)
        public
        view
        returns (INounsSeeder.Seed memory)
    {
        INounsSeeder.Seed memory nounSeed = nounsToken.seeds(tokenId);
        return nounSeed;
    }

    function generateSeed(uint256 nounId)
        public
        view
        returns (INounsSeeder.Seed memory)
    {
        return seeder.generateSeed(nounId, descriptor);
    }

    function fetchLilNoun(uint256 tokenId) public view returns (string memory) {
        require(isNounValid(tokenId), "This noun does not exist (yet). So its Lil Noun cannot exist either.");
        INounsSeeder.Seed memory nounSeed = fetchSeeds(tokenId);
        string memory lilNoun = descriptor.generateSVGImage(nounSeed);
        return lilNoun;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent noun");
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Lil Noun ',
                        toString(tokenId),
                        '", "description": "Lil Noun ',
                        toString(tokenId),
                        " is a lil version of Noun ",
                        toString(tokenId),
                        '", "image": "data:image/svg+xml;base64, ',
                        fetchLilNoun(tokenId),
                        '"}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));
        return json;
    }

    // Checks if a supplied tokenId is a valid noun
    function isNounValid(uint256 tokenId) private view returns (bool) {
        bool isValid = (tokenId + nounsTokenIndexOffset ==
            IERC721Enumerable(nounsTokenContract).tokenByIndex(tokenId));
        return isValid;
    }

    // Updates nounsTokenIndexOffset. Default value is 0 (since indexOf(tokenId) check should match tokenId), but in case a Noun is burned, the offset may require a manual update to allow LilNouns to be minted again
    function setNounsTokenIndexOffset(uint256 newOffset) public onlyOwner {
        nounsTokenIndexOffset = newOffset;
    }

    // Mint function that mints the supplied tokenId and increments counters
    function mint(address destination, uint256 tokenId) private {
        require(isNounValid(tokenId), "This noun does not exist (yet). So its Lil Noun cannot exist either.");

        numTokensMinted += 1;

        _safeMint(destination, tokenId);
    }

    // Public minting for a supplied tokenId, except for every 10th LilNoun
    function publicMint(
        uint256 tokenId,
        uint256 amount,
        string memory message,
        bytes memory signature
    ) public payable virtual {
        require(!allSalesPaused, "Sales are currently paused");

        require(
            tokenId % 10 != 0,
            "Every 10th Lil Noun is reserved for NounsDAO."
        );

        require(
            verify(_msgSender(), amount, message, tokenId, signature),
            "Signature must be valid to mint."
        );

        require(amount == msg.value, "ETH amount is incorrect");

        mint(_msgSender(), tokenId);
    }

    //The LilNoun-Nouns Virtuous Cycle. Mint a lil noun at given tokenId + (minter willing) up to 9 nounder lil nouns to the nounsDAO for free.
    function publicMintWithGift(
        uint256 tokenId,
        uint256[] memory nounsGiftTokenIds,
        uint256 amount,
        string memory message,
        bytes memory signature
    ) public payable virtual {
        require(!allSalesPaused, "Sales are currently paused");

        require(
            verify(_msgSender(), amount, message, tokenId, signature),
            "Signature must be valid to mint."
        );

        require(amount == msg.value, "ETH amount is incorrect");

        require(nounsGiftTokenIds.length < 10, "Cannot mint too much at once!");

        mint(_msgSender(), tokenId);

        for (uint256 i = 0; i < nounsGiftTokenIds.length; i++) {
            require(
                nounsGiftTokenIds[i] % 10 == 0,
                "Can only batch mint every 10th Lil Noun reserved for NounsDAO."
            );

            uint256 availToken = nounsGiftTokenIds[i];
            mint(nounsDAO, availToken);
        }
    }

    //Per 4156's request, anyone can mint nounder lil nouns (tokenId % 10 == 0) to the nounsDao for free
    function nounsDaoMint(uint256[] memory tokenIds) public virtual {
        require(!allSalesPaused, "Sales are currently paused");
        require(tokenIds.length <= 10, "Cannot mint too much at once!");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] % 10 == 0,
                "Can only batch mint every 10th Lil Noun reserved for NounsDAO."
            );

            uint256 availToken = tokenIds[i];
            mint(nounsDAO, availToken);
        }
    }

    // Allows owner to mint any available tokenId. To be used with discretion & lockable via lockReservedMints()
    function reservedMint(address destination, uint256 tokenId)
        public
        onlyOwner
    {
        require(!reservedMintsLocked, "Reserved mints locked.");
        mint(destination, tokenId);
    }

    function verify(
        address _signer,
        uint256 _amount,
        string memory _message,
        uint256 _nonce,
        bytes memory signature
    ) private pure returns (bool) {
        bytes32 messageHash = getMessageHash(_amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function getMessageHash(
        uint256 _amount,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _message, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter)
        external
        override
        onlyOwner
        whenMinterNotLocked
    {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Set the NounsDAO Token address.
     * @dev Only callable by the owner when not locked.
     */
    function setNounsDAO(address _nounsDAO) external onlyOwner {
        nounsDAO = _nounsDAO;
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(address _descriptor)
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        descriptor = ILilNounsDescriptor(_descriptor);
        emit DescriptorUpdated(descriptor);
    }

    /**
     * @notice Set the token URI Token.
     * @dev Only callable by the owner when not locked.
     */
    function setNounsToken(address _nounsToken)
        external
        override
        onlyOwner
        whenNounsTokenNotLocked
    {
        nounsToken = INounsToken(_nounsToken);
        emit NounsTokenUpdated(nounsToken);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockNounsToken()
        external
        override
        onlyOwner
        whenNounsTokenNotLocked
    {
        isNounsTokenLocked = true;
        emit NounsTokenLocked();
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor()
        external
        override
        onlyOwner
        whenDescriptorNotLocked
    {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(address _seeder)
        external
        override
        onlyOwner
        whenSeederNotLocked
    {
        seeder = INounsSeeder(_seeder);
        emit SeederUpdated(seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    // Pauses all sales, except reserved mints
    function toggleAllSalesPaused() public onlyOwner {
        allSalesPaused = !allSalesPaused;
    }

    // Locks owners ability to use reservedMints()
    function lockReservedMints() public onlyOwner {
        reservedMintsLocked = true;
    }

    // Withdraws contract balance to contract owners account
    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
