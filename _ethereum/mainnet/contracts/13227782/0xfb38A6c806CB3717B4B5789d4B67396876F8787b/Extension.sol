//SPDX-License-Identifier: MIT

//Contract is not audited, use at your own risk
//https://github.com/ExtensionNFT/contracts

pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./IRenderExtension.sol";
import "./ISvgValidator.sol";

// solhint-disable quotes
contract Extension is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20;
    using SafeMathUpgradeable for uint256;

    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes4 public constant RENDER_INTERFACE_ID = type(IRenderExtension).interfaceId;
    uint256 public constant MAX_MINTS = 10;
    uint256 public constant REGISTRATION_COST = 200_000_000_000_000_000;
    uint256 public constant MINT_COST = 100_000_000_000_000_000;
    uint256 public constant MAX_EXTENSIONS = 8;

    struct GenerationDetails {
        uint256 mintNumStart;
        uint256 mintNumEnd;
        uint256 totalMinted;
        uint256 nextOwnerMintId;
        uint256 nextPublicMintId;
        uint256 maxOwnerMints;
    }

    mapping(uint256 => GenerationDetails) public generations;

    uint256 public currentGeneration;
    uint256 public currentExtensionSet;

    mapping(uint256 => uint256) public tokenExtensionSet;
    mapping(uint256 => address[]) public extensionSetAddresses;
    mapping(uint256 => uint256) public tokenGeneration;

    mapping(address => bool) public bannedAddresses;

    address public validatorAddress;

    bool public canModerate;
    address public moderator;

    function initialize(
        uint256 amtForInitGen,
        uint256 ownerMintsForInitGen,
        address validator
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained("Extension NFT", "ExNFT");
        __ERC721Enumerable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        currentGeneration = 1;
        canModerate = true;
        moderator = msg.sender;

        generations[1] = GenerationDetails({
            mintNumStart: 1,
            mintNumEnd: amtForInitGen,
            totalMinted: 0,
            nextOwnerMintId: 1,
            nextPublicMintId: 1 + ownerMintsForInitGen,
            maxOwnerMints: ownerMintsForInitGen
        });
        validatorAddress = validator;
    }

    event ModerationRelinquished();
    event ValidatorAddressSet(address validator);
    event ModeratorSet(address moderator);
    event AddressModerationChanged(address addr, bool allowed);
    event ExtensionAdded(address added, uint256 addedAt, address removed);
    event ExtensionReplaced(address newAddress, address oldAddress, uint256 index);
    event ExtensionRemoved(address extension, uint256 index);
    event NextGenerationStart(uint256 currentGeneration);
    event ETHExit(address to, uint256 amount);
    event ERC20Exit(address token, address to, uint256 amount);

    function relinquishModeration() external onlyOwner {
        require(canModerate, "NO_MODERATION");

        canModerate = false;

        emit ModerationRelinquished();
    }

    function setValidatorAddress(address validator) external onlyOwner {
        validatorAddress = validator;

        emit ValidatorAddressSet(validator);
    }

    function setModerator(address mod) external onlyOwner {
        moderator = mod;

        emit ModeratorSet(mod);
    }

    function moderateAddress(address modAddress, bool allowed) external onlyOwner {
        require(canModerate, "NO_MODERATION");

        bannedAddresses[modAddress] = allowed;

        emit AddressModerationChanged(modAddress, allowed);
    }

    function addExtension(address contractAddress) external payable nonReentrant {
        require(!canModerate || (canModerate && !bannedAddresses[contractAddress]), "CONTRACT_BANNED");
        require(!canModerate || (canModerate && !bannedAddresses[msg.sender]), "SENDER_BANNED");
        require(contractAddress != address(0), "INVALID_ADDRESS");
        require(IRenderExtension(contractAddress).supportsInterface(RENDER_INTERFACE_ID), "NO_RENDER_SUPPORT");
        require(msg.value == REGISTRATION_COST || (canModerate && owner() == msg.sender), "NO_REGISTRATION_FEE");

        uint256 newExtensionSetId = currentExtensionSet.add(1);
        uint256 currentExtensionSetLength = extensionSetAddresses[currentExtensionSet].length;
        uint256 i = 0;
        address removed = address(0);
        if (currentExtensionSetLength == MAX_EXTENSIONS) {
            i = 1;
            removed = extensionSetAddresses[currentExtensionSet][0];
        }
        for (; i < currentExtensionSetLength; i++) {
            extensionSetAddresses[newExtensionSetId].push(extensionSetAddresses[currentExtensionSet][i]);
        }
        extensionSetAddresses[newExtensionSetId].push(contractAddress);

        currentExtensionSet = newExtensionSetId;

        emit ExtensionAdded(contractAddress, i, removed);
    }

    function replaceExtension(
        uint256 extensionIndex,
        address existingAddress,
        address contractAddress
    ) external payable nonReentrant {
        require(!canModerate || (canModerate && !bannedAddresses[contractAddress]), "CONTRACT_BANNED");
        require(!canModerate || (canModerate && !bannedAddresses[msg.sender]), "SENDER_BANNED");
        require(contractAddress != address(0), "INVALID_ADDRESS");
        require(extensionSetAddresses[currentExtensionSet][extensionIndex] == existingAddress, "MISMATCH_REPLACE");
        require(IRenderExtension(contractAddress).supportsInterface(RENDER_INTERFACE_ID), "NO_RENDER_SUPPORT");
        require(msg.value == REGISTRATION_COST || (canModerate && owner() == msg.sender), "NO_REGISTRATION_FEE");

        uint256 newExtensionSetId = currentExtensionSet.add(1);
        address replaced;
        for (uint256 i = 0; i < extensionSetAddresses[currentExtensionSet].length; i++) {
            if (i == extensionIndex) {
                replaced = extensionSetAddresses[currentExtensionSet][i];
                extensionSetAddresses[newExtensionSetId].push(contractAddress);
            } else {
                extensionSetAddresses[newExtensionSetId].push(extensionSetAddresses[currentExtensionSet][i]);
            }
        }

        currentExtensionSet = newExtensionSetId;

        emit ExtensionReplaced(contractAddress, replaced, extensionIndex);
    }

    function removeExtension(uint256 extensionIndex, address existingAddress) external payable nonReentrant {
        require(!canModerate || (canModerate && !bannedAddresses[msg.sender]), "SENDER_BANNED");
        require(extensionSetAddresses[currentExtensionSet][extensionIndex] == existingAddress, "MISMATCH_REPLACE");
        require(msg.value == REGISTRATION_COST || (canModerate && owner() == msg.sender), "NO_REGISTRATION_FEE");
        require(extensionSetAddresses[currentExtensionSet].length > 1, "MUST_HAVE_ONE");

        uint256 newExtensionSetId = currentExtensionSet.add(1);
        for (uint256 i = 0; i < extensionSetAddresses[currentExtensionSet].length; i++) {
            if (i != extensionIndex) {
                extensionSetAddresses[newExtensionSetId].push(extensionSetAddresses[currentExtensionSet][i]);
            }
        }

        currentExtensionSet = newExtensionSetId;

        emit ExtensionRemoved(existingAddress, extensionIndex);
    }

    function mint(uint256 amtToMint) external payable {
        require(amtToMint > 0, "MUST_MINT_ONE");
        require(amtToMint <= MAX_MINTS, "TOO_MANY");
        require(msg.value == (amtToMint * MINT_COST), "INVALID_FUNDS");
        require(generations[currentGeneration].nextPublicMintId.add(amtToMint).sub(1) <= generations[currentGeneration].mintNumEnd, "GENERATION_LOCKED");

        for (uint256 i = 0; i < amtToMint; i++) {
            _mintTo(msg.sender, generations[currentGeneration].nextPublicMintId);
            generations[currentGeneration].nextPublicMintId = generations[currentGeneration].nextPublicMintId.add(1);
        }
    }

    function ownerMint(uint256 amtToMint, address to) external onlyOwner {
        require(amtToMint > 0, "MUST_MINT_ONE");
        require(amtToMint <= MAX_MINTS, "TOO_MANY");
        require(
            generations[currentGeneration].nextOwnerMintId.add(amtToMint).sub(1) < generations[currentGeneration].mintNumStart.add(generations[currentGeneration].maxOwnerMints),
            "OWNER_MINT_COMPLETE"
        );

        for (uint256 i = 0; i < amtToMint; i++) {
            _mintTo(to, generations[currentGeneration].nextOwnerMintId);
            generations[currentGeneration].nextOwnerMintId = generations[currentGeneration].nextOwnerMintId.add(1);
        }
    }

    function nextGeneration(uint256 mintAmount, uint256 ownerMints) external onlyOwner {
        GenerationDetails memory prevGen = generations[currentGeneration];

        require(prevGen.nextPublicMintId > prevGen.mintNumEnd, "PUBLIC_NOT_ENDED");
        require(mintAmount > ownerMints, "GIVE_THE_PUBLIC_SOMETHING");

        currentGeneration = currentGeneration.add(1);

        generations[currentGeneration] = GenerationDetails({
            mintNumStart: prevGen.nextPublicMintId,
            mintNumEnd: prevGen.nextPublicMintId.add(mintAmount).sub(1),
            totalMinted: 0,
            nextOwnerMintId: prevGen.nextPublicMintId,
            nextPublicMintId: prevGen.nextPublicMintId.add(ownerMints),
            maxOwnerMints: ownerMints
        });

        emit NextGenerationStart(currentGeneration);
    }

    function ethRecoup(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "NO_BURN");
        require(address(this).balance > 0, "NO_FUNDS");
        require(amount > 0, "INVALID_AMOUNT");
        require(to.send(amount), "SEND_FAIL");

        emit ETHExit(to, amount);
    }

    function erc20Recoup(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "NO_BURN");
        require(token != address(0), "INVALID_TOKEN");
        require(amount > 0, "INVALID_AMOUNT");
        require(IERC20(token).balanceOf(address(this)) > 0, "NO_FUNDS");

        IERC20(token).safeTransfer(to, amount);

        emit ERC20Exit(token, to, amount);
    }

    function getExtensionsSetAddresses(uint256 extensionSetId) external view returns (address[] memory addresses) {
        addresses = extensionSetAddresses[extensionSetId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN_DOES_NOT_EXIST");

        address[] memory extensions = extensionSetAddresses[tokenExtensionSet[tokenId]];
        string[MAX_EXTENSIONS + 2] memory parts;
        string[MAX_EXTENSIONS + 6] memory attrs;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 8px; }</style><rect width="100%" height="100%" fill="black" />'; // solhint-disable-line quotes

        attrs[0] = '[{"trait_type":"Generation","value":"';
        attrs[1] = toString(tokenGeneration[tokenId]);
        attrs[2] = '"},{"trait_type":"Extension Set","value":"';
        attrs[3] = toString(tokenExtensionSet[tokenId]);
        attrs[4] = '"}';

        for (uint256 i = 0; i < extensions.length; i++) {
            if (extensions[i] != address(0)) {
                try IRenderExtension(extensions[i]).generate(tokenId, tokenGeneration[tokenId]) returns (IRenderExtension.GenerateResult memory result) {
                    bool isValid = ISvgValidator(validatorAddress).isValid(result.svgPart);

                    if (isValid == false) {
                        parts[i + 1] = result.svgPart;
                        attrs[i + 5] = result.attributes;
                    } else {
                        parts[i + 1] = "";
                        attrs[i + 5] = "";
                    }
                } catch {
                    parts[i + 1] = "";
                    attrs[i + 5] = "";
                }
            } else {
                parts[i + 1] = "";
                attrs[i + 5] = "";
            }
        }

        parts[MAX_EXTENSIONS - 1] = "</svg>";

        attrs[attrs.length - 1] = "]";

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9]));

        string memory attrOutput = string(abi.encodePacked(attrs[0], attrs[1], attrs[2], attrs[3], attrs[4], attrs[5], attrs[6], attrs[7], attrs[8]));
        attrOutput = string(abi.encodePacked(attrOutput, attrs[9], attrs[10], attrs[11], attrs[12], attrs[13]));

        string memory json = base64Encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Extension NFT #',
                        toString(tokenId),
                        '", "description": "What has the community done to this NFT?", "attributes": ',
                        attrOutput,
                        ', "image": "data:image/svg+xml;base64,',
                        base64Encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function contractURI() public view returns (string memory) {
        string memory props = string(
            abi.encodePacked(
                '{"name": "Extension NFT", "description": "An experiment in community driven NFTs. When you can affect the look and rarity of your mint, where will your code fall? Creative Good or Developer Evil?",',
                '"image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAALEAAACrCAIAAACmBupvAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAHYcAAB2HAY/l8WUAAAEmSURBVHhe7dahbkNBEARB//9PJ6SH25ECnrcKtnRoB9wLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB7p53O95Ft150/0km/VnT/RS75Vd/5EL/km3Xaq7+nNVHm67jnV9/Rmqjxd95zqe3ozVZ6ue071Pb2ZKpe1halyWVuYKpe1halyWVuYKpe1halyWVuYKpe1halyWVuYKtd0/6lyWVuYKpe1halyWVuYKtd0/6lyWVuYKpe1halyWVuYKtd0/6lyWVuYKpe1halyWVuYKpe1halyWVuYKpe1halyWVuYKgAA/F1/y6lyWVuYKpe1halyWVuYKgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/l9foFLnXlN+EHpoQAAAAASUVORK5CYII=",',
                '"seller_fee_basis_points": 100,',
                '"fee_recipient": "0x',
                getChecksum(address(this)),
                '"}'
            )
        );

        string memory json = base64Encode(bytes(props));

        string memory output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function _mintTo(address to, uint256 tokenId) internal {
        tokenGeneration[tokenId] = currentGeneration;
        tokenExtensionSet[tokenId] = currentExtensionSet;
        generations[currentGeneration].totalMinted = generations[currentGeneration].totalMinted;
        _safeMint(to, tokenId);
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

    function base64Encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        //solhint-disable
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }
        //solhint-enable

        return string(result);
    }

    /**
     * @dev Get a checksummed string hex representation of an account address.
     * @param account address The account to get the checksum for.
     * @return accountChecksum The checksummed account string in ASCII format. Note that leading
     * "0x" is not included.
     */
    function getChecksum(address account) public pure returns (string memory accountChecksum) {
        // call internal function for converting an account to a checksummed string.
        return _toChecksumString(account);
    }

    /**
     * @dev Get a fixed-size array of whether or not each character in an account
     * will be capitalized in the checksum.
     * @param account address The account to get the checksum capitalization
     * information for.
     * @return characterCapitalized A fixed-size array of booleans that signify if each character or
     * "nibble" of the hex encoding of the address will be capitalized by the
     * checksum.
     */
    function getChecksumCapitalizedCharacters(address account) public pure returns (bool[40] memory characterCapitalized) {
        // call internal function for computing characters capitalized in checksum.
        return _toChecksumCapsFlags(account);
    }

    /**
     * @dev Determine whether a string hex representation of an account address
     * matches the ERC-55 checksum of that address.
     * @param accountChecksum string The checksummed account string in ASCII
     * format. Note that a leading "0x" MUST NOT be included.
     * @return ok A boolean signifying whether or not the checksum is valid.
     */
    function isChecksumValid(string calldata accountChecksum) public pure returns (bool ok) {
        // call internal function for validating checksum strings.
        return _isChecksumValid(accountChecksum);
    }

    function _toChecksumString(address account) internal pure returns (string memory asciiString) {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2 * i];
            rightCaps = caps[2 * i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(asciiBytes);
    }

    function _toChecksumCapsFlags(address account) internal pure returns (bool[40] memory characterCapitalized) {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 && leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 && rightNibbleHash > 7);
        }
    }

    function _isChecksumValid(string memory provided) internal pure returns (bool ok) {
        // convert the provided string into account type.
        address account = _toAddress(provided);

        // return false in the event the account conversion returned null address.
        if (account == address(0)) {
            // ensure that provided address is not also the null address first.
            bytes memory b = bytes(provided);
            for (uint256 i; i < b.length; i++) {
                if (b[i] != hex"30") {
                    return false;
                }
            }
        }

        // get the capitalized characters in the actual checksum.
        string memory actual = _toChecksumString(account);

        // compare provided string to actual checksum string to test for validity.
        return (keccak256(abi.encodePacked(actual)) == keccak256(abi.encodePacked(provided)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps) internal pure returns (uint8 offset) {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toAddress(string memory account) internal pure returns (address accountAddress) {
        // convert the account argument from address to bytes.
        bytes memory accountBytes = bytes(account);

        // create a new fixed-size byte array for the ascii bytes of the address.
        bytes memory accountAddressBytes = new bytes(20);

        // declare variable types.
        uint8 b;
        uint8 nibble;
        uint8 asciiOffset;

        // only proceed if the provided string has a length of 40.
        if (accountBytes.length == 40) {
            for (uint256 i; i < 40; i++) {
                // get the byte in question.
                b = uint8(accountBytes[i]);

                // ensure that the byte is a valid ascii character (0-9, A-F, a-f)
                if (b < 48) return address(0);
                if (57 < b && b < 65) return address(0);
                if (70 < b && b < 97) return address(0);
                if (102 < b) return address(0); //bytes(hex"");

                // find the offset from ascii encoding to the nibble representation.
                if (b < 65) {
                    // 0-9
                    asciiOffset = 48;
                } else if (70 < b) {
                    // a-f
                    asciiOffset = 87;
                } else {
                    // A-F
                    asciiOffset = 55;
                }

                // store left nibble on even iterations, then store byte on odd ones.
                if (i % 2 == 0) {
                    nibble = b - asciiOffset;
                } else {
                    accountAddressBytes[(i - 1) / 2] = (bytes1(16 * nibble + (b - asciiOffset)));
                }
            }

            // pack up the fixed-size byte array and cast it to accountAddress.
            bytes memory packed = abi.encodePacked(accountAddressBytes);
            assembly {
                accountAddress := mload(add(packed, 20))
            }
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data) internal pure returns (string memory asciiString) {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(leftNibble + (leftNibble < 10 ? 48 : 87));
            asciiBytes[2 * i + 1] = bytes1(rightNibble + (rightNibble < 10 ? 48 : 87));
        }

        return string(asciiBytes);
    }
}
