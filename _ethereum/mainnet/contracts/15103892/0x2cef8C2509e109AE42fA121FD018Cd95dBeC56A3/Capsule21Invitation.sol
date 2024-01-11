pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./Address.sol";
import "./Strings.sol";
import "./base64.sol";

import "./ERC721A.sol";
import "./ERC2981.sol";

import "./SSTORE2.sol";
import "./DynamicBuffer.sol";

import "./AccessControl.sol";

interface IReverseRegistrar {
    function setName(string memory name) external returns (bytes32);
}

interface RendererContract {
    struct Invitation {
        uint24 id;
        uint24[10] gradientColors;
        bool isRadialGradient;
        uint24 textColor;
        uint8 fontSize;
        uint16 linearGradientAngleDeg;
        address textPointer;
        address descriptionPointer;
        uint32 eventTime;
        uint32 mintStart;
        uint24 mintDuration;
        uint24 editionSize;
    }
    
    struct ExtraTokenInfo {
        uint24 invitationId;
        uint24 editionNumber;
        address to;
        address from;
    }
    
    function addressToEnsName(address _address) external view returns (string memory);
    
    function tokenImage(
        uint tokenId,
        Invitation memory invitation,
        ExtraTokenInfo memory tokenInfo
    ) external view returns (string memory);
}

contract Capsule21Invitation is ERC721A, ERC2981, AccessControl {
    using Address for address;
    using Strings for uint160;
    using Strings for uint32;
    using Strings for uint24;
    
    RendererContract public renderingContract;
    
    address public contractImagePointer;
    string constant contractDescription = "Invitations to Capsule 21 sponsored events.";
    string constant contractExternalURL = "https://www.capsule21.com/collections/capsule-21-invitations";

    bytes32 public constant INVITE_SENDER_ROLE = keccak256("INVITE_SENDER_ROLE");

    address constant pivAddress = 0xf98537696e2Cf486F8F32604B2Ca2CDa120DBBa8;
    address constant doveAddress = 0x5FD2E3ba05C862E62a34B9F63c45C0DF622Ac112;
    address constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    
    uint24 public nextInvitationId = 1;
    
    function _startTokenId() internal view virtual override returns (uint256) { return 1; }
    
    mapping(uint24 => RendererContract.Invitation) public invitationIdToInvitation;
    mapping(uint64 => RendererContract.ExtraTokenInfo) public tokenIdToExtraInfo;
    
    mapping(address => mapping(uint24 => bool)) public addressToInvitationsMinted;
    
    function setRenderingContract(address newContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        renderingContract = RendererContract(newContract);
    }
    
    function setContractImageData(string memory contractImageData) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractImagePointer = SSTORE2.write(bytes(contractImageData));
    }
    
    function grantInviteSenderRole(address newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(INVITE_SENDER_ROLE, newAddress);
    }
    
    function addReverseENSRecord(string memory name) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148).setName(name);
    }
    
    constructor(
        address _renderingContract,
        string memory contractImageData
    ) ERC721A("Capsule 21 Invitations", "C21I") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, doveAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, middleAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, pivAddress);
        
        grantInviteSenderRole(msg.sender);
        grantInviteSenderRole(doveAddress);
        grantInviteSenderRole(middleAddress);
        grantInviteSenderRole(pivAddress);
        
        setRenderingContract(_renderingContract);
        setContractImageData(contractImageData);
        
        addReverseENSRecord("capsule21.eth");
        
        _setDefaultRoyalty(address(this), 1_000); // 10%
    }
    
    function getInvitationForToken(uint64 tokenId) public view returns (RendererContract.Invitation memory) {
        require(_exists(tokenId), "Token doesn't exist");
        RendererContract.ExtraTokenInfo memory extraTokenInfo = getExtraTokenInfo(tokenId);
        
        uint24 invitationId = extraTokenInfo.invitationId;
        require(invitationExists(invitationId), "Invitation does not exist.");
                
        return invitationIdToInvitation[invitationId];
    }
    
    function getInvitationById(uint24 invitationId) public view returns (RendererContract.Invitation memory) {
        require(invitationExists(invitationId), "Invitation does not exist.");
        return invitationIdToInvitation[invitationId];
    }
    
    function invitationExists(uint24 invitationId) public view returns (bool) {
        return invitationIdToInvitation[invitationId].id > 0;
    }
    
    function getExtraTokenInfo(uint64 tokenId) public view returns (RendererContract.ExtraTokenInfo memory) {
        require(_exists(tokenId), "Token doesn't exist");
        
        return tokenIdToExtraInfo[tokenId];
    }
    
    fallback (bytes calldata _inputText) external payable returns (bytes memory _output) {}
    
    receive () external payable {}
    
    function createInvitation(
                      string calldata text,
                      uint24 textColor,
                      bool isRadialGradient,
                      uint8 fontSize,
                      uint16 linearGradientAngleDeg,
                      uint24[10] calldata gradientColors,
                      uint32 eventTime,
                      string calldata description
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RendererContract.Invitation storage newInvitation = invitationIdToInvitation[nextInvitationId];
        
        require(eventTime > 0, "Need a start time");
        require(bytes(text).length > 0, "Need text");
        require(bytes(description).length > 0, "Need description");
        
        newInvitation.id = nextInvitationId;
        newInvitation.textPointer = SSTORE2.write(bytes(text));
        newInvitation.descriptionPointer = SSTORE2.write(bytes(description));
        newInvitation.textColor = textColor;
        newInvitation.isRadialGradient = isRadialGradient;
        newInvitation.fontSize = fontSize;
        newInvitation.linearGradientAngleDeg = linearGradientAngleDeg;
        newInvitation.gradientColors = gradientColors;
        newInvitation.eventTime = eventTime;
        
        unchecked { ++nextInvitationId; }
    }
    
    function startMint(uint24 invitationId, uint32 mintStartTime, uint24 mintDuration) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(invitationExists(invitationId), "Invitation does not exist.");
        
        RendererContract.Invitation storage invitation = invitationIdToInvitation[invitationId];
        require(invitation.mintStart == 0, "Mint already started.");
        
        invitation.mintStart = mintStartTime > uint32(block.timestamp) ? mintStartTime : uint32(block.timestamp);
        invitation.mintDuration = mintDuration;
    }
    
    function invitationMintEndTime(uint24 invitationId) public view returns (uint) {
        require(invitationExists(invitationId), "Invitation does not exist.");
        
        RendererContract.Invitation memory invitation = invitationIdToInvitation[invitationId];
        
        return invitation.mintStart + invitation.mintDuration;
    }
    
    function requestInvitation(uint24 invitationId) external returns (uint) {
        require(msg.sender == tx.origin, "Contracts cannot mint");

        return internalMint(invitationId, address(this), msg.sender);
    }
    
    function sendInvitation(uint24 invitationId, address[] memory tos) external onlyRole(INVITE_SENDER_ROLE) {
        for (uint i; i < tos.length; ++i) {
            internalMint(invitationId, msg.sender, tos[i]);
        }
    }
    
    function internalMint(uint24 invitationId, address from, address to) private returns (uint) {
        require(invitationExists(invitationId), "Invitation does not exist.");
        
        RendererContract.Invitation storage invitation = invitationIdToInvitation[invitationId];
        
        require(!addressToInvitationsMinted[to][invitationId], "Only on mint per invite per address");
        require(block.timestamp >= invitation.mintStart, "Mint hasn't started");
        require(block.timestamp <= invitationMintEndTime(invitationId), "Mint is over");
        
        uint64 aboutToMintId = uint64(_nextTokenId());
        
        _mint(to, 1);
        invitation.editionSize++;

        RendererContract.ExtraTokenInfo storage extraTokenInfo = tokenIdToExtraInfo[aboutToMintId];
        
        extraTokenInfo.to = to;
        extraTokenInfo.from = from;
        extraTokenInfo.invitationId = invitationId;
        extraTokenInfo.editionNumber = invitation.editionSize;
        
        addressToInvitationsMinted[to][invitationId] = true;
        
        return aboutToMintId;
    }
    
    function tokenImage(uint64 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "doesn't exist");
        
        RendererContract.ExtraTokenInfo memory extraTokenInfo = tokenIdToExtraInfo[tokenId];

        return renderingContract.tokenImage(tokenId, getInvitationForToken(tokenId), extraTokenInfo);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "doesn't exist");
        
        return constructTokenURI(uint64(tokenId));
    }
    
    function constructTokenURI(uint64 tokenId) private view returns (string memory) {
        RendererContract.ExtraTokenInfo memory extraTokenInfo = tokenIdToExtraInfo[tokenId];
        RendererContract.Invitation memory invitation = getInvitationForToken(tokenId);
        bytes memory svg = bytes(tokenImage(tokenId));
        
        string memory title = string.concat(
            "Capsule 21 Invitation #",
            invitation.id.toString(),
            " (", extraTokenInfo.editionNumber.toString(),
            " of ",
            invitation.editionSize.toString(), ")"
        );
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":', SSTORE2.read(invitation.descriptionPointer), ','
                                '"image_data":"', svg, '",'
                                '"external_url":"', contractExternalURL, '",'
                                    '"attributes": [',
                                        '{',
                                            '"trait_type": "From",',
                                            '"value": "', renderingContract.addressToEnsName(extraTokenInfo.from), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "To",',
                                            '"value": "', renderingContract.addressToEnsName(extraTokenInfo.to), '"',
                                        '},'
                                        '{',
                                            '"trait_type": "Event Time",',
                                            '"display_type": "date",',
                                            '"value": ', invitation.eventTime.toString(), '',
                                        '}'
                                    ']'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', name(), '",'
                                '"description":"', contractDescription, '",'
                                '"image":"data:image/svg+xml;base64,', Base64.encode(SSTORE2.read(contractImagePointer)), '",'
                                '"external_link":"', contractExternalURL, '"'
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = address(this).balance;
        
        require(balance > 0, "Nothing to withdraw");
        
        uint middleShare = balance / 3;
        uint doveShare = balance / 3;
        uint pivShare = balance - middleShare - doveShare;
        
        Address.sendValue(payable(pivAddress), pivShare);
        Address.sendValue(payable(doveAddress), doveShare);
        Address.sendValue(payable(middleAddress), middleShare);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}
