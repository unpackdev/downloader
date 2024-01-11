// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

import "./base64.sol";
import "./ERC721.sol";

import "./SSTORE2.sol";
import "./DynamicBuffer.sol";

import "./console.sol";
import "./StringUtilsLib.sol";

contract mememe is ERC721, AccessControl, ReentrancyGuard {
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint160;
    using StringUtils for string;
    
    bytes public constant externalLink = "https://capsule21.com/collections/mememe";
    
    uint public constant costToMint = 0.01 ether;
    uint public constant costToUpdateBioOrAddSelfWorth = 0.001 ether;
    uint public constant maxBioLength = 280;
    
    uint public constant initialPhysicalCost = 0.15 ether;
    
    uint public constant maxSupply = 16 ** 40;
    
    bool public contractSealed;
    
    bool public isMintActive;
    
    address constant doveAddress = 0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    struct Token {
        bool isNumberOne;
        address bioPointer;
        uint64 mintedAt;
        uint selfWorth;
    }

    mapping(uint => Token) private idToToken;
    
    uint public topPayerTokenId;
    
    address[] public physicalRecipients;
    
    event SelfWorthUpdate(address indexed user, uint indexed oldSelfWorth, uint indexed newSelfWorth, string currentBio, uint occurredAt);
    event BioUpdate(address indexed user, string oldBio, string newBio, uint occurredAt);
    event NumberOneChanged(address indexed oldNumberOne, address indexed newNumberOne, uint newNumberOneSelfWorth, uint occurredAt);
    
    event NewPhysicalRecipientAdded(address indexed newRecipient, uint occurredAt);
    
    function flipMintState() external onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
        isMintActive = !isMintActive;
    }
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
        contractSealed = true;
    }
    
    function grantAdminRole(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, newAddress);
    }
    
    constructor() ERC721("mememe", "mememe") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, doveAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, middleAddress);
    }
    
    function removeBio() external {
        uint tokenId = uint(uint160(msg.sender));
        
        require(_exists(tokenId), "mememe does not exist");

        Token storage token = idToToken[tokenId];
        token.bioPointer = address(0);
    }
    
    function mintOrAddSelfWorthOrUpdateBio(string memory optionalBio) public payable nonReentrant {
        uint tokenId = uint(uint160(msg.sender));
        Token storage tokenStruct = idToToken[tokenId];
        
        if (!_exists(tokenId)) {
            require(isMintActive, "Mint is not active");
            require(msg.value >= costToMint, string.concat(
                "Send at least ", costToMint.toString()," to mint"
            ));

            _mint(msg.sender, tokenId);
            tokenStruct.mintedAt = uint64(block.timestamp);
        }
        
        require(msg.value >= costToUpdateBioOrAddSelfWorth,
               string.concat("Send at least ", costToUpdateBioOrAddSelfWorth.toString(), " to update bio or self worth")
               );
        
        uint oldSelfWorth = tokenStruct.selfWorth;
        uint newSelfWorth = oldSelfWorth + msg.value;
        
        if (bytes(optionalBio).length > 0) {
            require(bytes(optionalBio).length <= maxBioLength,
                string.concat("Bio is too long. Max length: ", maxBioLength.toString())
            );
            emit BioUpdate(msg.sender, string(SSTORE2.read(tokenStruct.bioPointer)), optionalBio, block.timestamp);
            tokenStruct.bioPointer = SSTORE2.write(bytes(optionalBio));
        }
        
        if (oldSelfWorth != newSelfWorth) {
            tokenStruct.selfWorth = newSelfWorth;
            updateTopPayerIfNecessary(msg.sender);
            
            emit SelfWorthUpdate(msg.sender, oldSelfWorth, newSelfWorth, string(SSTORE2.read(tokenStruct.bioPointer)), block.timestamp);
        }
    }
    
    fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {
        mintOrAddSelfWorthOrUpdateBio(string(_inputText));
    }
    
    receive () external payable {
        mintOrAddSelfWorthOrUpdateBio(string(""));
    }
    
    function updateTopPayerIfNecessary(address contenderAddress) private {
        uint contenderId = uint(uint160(contenderAddress));
        
        Token storage contenderToken = idToToken[contenderId];
        Token storage topPayerToken = idToToken[topPayerTokenId];
        
        if (contenderToken.selfWorth > topPayerToken.selfWorth) {
            emit NumberOneChanged(address(uint160(topPayerTokenId)),
            contenderAddress, contenderToken.selfWorth, block.timestamp);
            
            topPayerTokenId = contenderId;
            contenderToken.isNumberOne = true;
            topPayerToken.isNumberOne = false;
        }
    }
    
    function getColors(uint tokenId) private pure returns (string[] memory) {
        string memory base = string.concat("00", (toHexStringNoPrefix(uint160(tokenId), 20)));
        string memory cur;
        string[] memory ret = new string[](7);
        
        for (uint i; i < 7; ++i) {
            cur = base._substring(6, int(i) * 6);
            ret[i] = cur;
        }
        
        return ret;
    }
    
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "mememe does not exist");

        return constructTokenURI(id);
    }
    
    function existsForAddress(address user) public view returns (bool) {
        uint tokenId = uint(uint160(user));
        return _exists(tokenId);
    }
    
    function physicalCostThreshold(uint physicalIndex) public pure returns (uint) {
        uint newPhysicalCost = initialPhysicalCost;
        
        for (uint i = 0; i < physicalIndex; ++i) {
            newPhysicalCost = (newPhysicalCost * 150) / 100;
        }
        
        return newPhysicalCost;
    }
    
    function costOfNextPhysical() public view returns (uint) {
        return physicalCostThreshold(physicalRecipients.length);
    }
    
    function addPhysicalRecipient(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        physicalRecipients.push(recipient);
        
        emit NewPhysicalRecipientAdded(recipient, block.timestamp);
    }
    
    function getAllPhysicalRecipients() public view returns (address[] memory) {
        return physicalRecipients;
    }
    
    function tokenImage(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "mememe does not exist");
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 64);
        
        string[] memory colors = getColors(tokenId);
        
        svgBytes.appendSafe('<svg width="1200" height="1200" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 7 7">');
        
        
        for (uint i; i < colors.length; ++i) {
            bytes memory newRect = abi.encodePacked(
                            '<rect width="1" height="7" x="',
                            i.toString(),
                            '" y="0" fill="#',
                            colors[i],
                            '"/>'
                        );
            
            svgBytes.appendSafe(newRect);
        }
        
        svgBytes.appendSafe(bytes("</svg>"));
        
        return string(svgBytes);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("mememes cannot be transfered");
    }
    
    function getMymememe() public view returns (
        bool isNumberOne,
        string memory bio,
        uint64 mintedAt,
        uint selfWorth,
        string memory selfWorthString,
        string memory tokenImageSVG
    ) {
        return getmememe(msg.sender);
    }
    
    function getmememe(address _owner) public view returns (
        bool isNumberOne,
        string memory bio,
        uint64 mintedAt,
        uint selfWorth,
        string memory selfWorthString,
        string memory tokenImageSVG
    ) {
        uint tokenId = uint(uint160(_owner));
        require(_exists(tokenId), "mememe does not exist");

        Token memory tokenStruct = idToToken[tokenId];
        
        return (
            tokenStruct.isNumberOne,
            string(SSTORE2.read(tokenStruct.bioPointer)),
            tokenStruct.mintedAt,
            tokenStruct.selfWorth,
            weiToEtherString(tokenStruct.selfWorth),
            tokenImage(tokenId)
        );
    }
    
    function getTopPayermememe() public view returns (
        bool isNumberOne,
        string memory bio,
        uint64 mintedAt,
        uint selfWorth,
        string memory selfWorthString,
        string memory tokenImageSVG
    ) {
        return getmememe(topPayerAddress());
    }
    
    function topPayerAddress() public view returns (address) {
        return address(uint160(topPayerTokenId));
    }
    
    function weiToEtherString(uint weiAmount) public pure returns (string memory) {
        string memory wholePart = (weiAmount / 1e18).toString();
        string memory decimalPart = ((weiAmount / 1e16) % 100).toString();
        
        if (bytes(decimalPart).length == 1) {
            decimalPart = string.concat("0", decimalPart);
        }
        
        return string.concat(
            wholePart, ".", decimalPart
        );
    }
    
    function tokenIdToSelfWorthEtherString(uint tokenId) public view returns (string memory) {
        require(_exists(tokenId), "mememe does not exist");
        return weiToEtherString(idToToken[tokenId].selfWorth);
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        Token memory tokenStruct = idToToken[tokenId];
        string memory svg = tokenImage(tokenId);
        uint bioLength = SSTORE2.read(tokenStruct.bioPointer).length;
        
        string memory numberOneString = tokenStruct.isNumberOne ? "Yes" : "No";
        
        string memory tokenDescription = string.concat("This is ", uint160(tokenId).toHexString(20), ". The unique hexadecimal address has been rendered as 7 stripes of striking color, and any strong complements or coincidences are the result of direct translation.");
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', uint160(tokenId).toHexString(20), '",'
                                '"description":"', tokenDescription, '",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",'
                                '"external_url":"', externalLink, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "Is #1?",',
                                            '"value": "', numberOneString, '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Self Worth",',
                                            '"display_type": "number",',
                                            '"value": ', weiToEtherString(tokenStruct.selfWorth),
                                        '},'
                                        '{',
                                            '"trait_type": "Mint Date",',
                                            '"display_type": "date",',
                                            '"value": "', uint(tokenStruct.mintedAt).toString(), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Bio Length",',
                                            '"display_type": "number",',
                                            '"value": ', bioLength.toString(),
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint half = total / 2;
        
        Address.sendValue(payable(middleAddress), half);
        Address.sendValue(payable(doveAddress), total - half);
    }
    
    bytes16 internal constant ALPHABET = '0123456789abcdef';
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}