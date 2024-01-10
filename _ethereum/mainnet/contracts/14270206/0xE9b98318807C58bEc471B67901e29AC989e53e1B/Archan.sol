// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./DateTime.sol";

bytes32 constant SUPPORT_ROLE = keccak256("SUPPORT");

contract ARCHANNAIR is ERC721Enumerable, AccessControl, ReentrancyGuard, DateTime {

    uint constant MAX_TOKENS = 10;
    uint constant SECONDS_PER_HOUR = 3600;
    
    using Strings for uint;
    using Strings for int;

    uint8 constant NUM_STATES = 2;
    string private BASE_URI;

    enum State { Day, Night }

    mapping(State => string) private stateString;
    mapping(State => string) private colorModesString;
    mapping(State => string) private perceptionsString;
    mapping(State => string) private tonesString;
    mapping(uint => int) public offsets;

    constructor(string memory _baseURI) ERC721("ARCHAN NAIR", "$ARCHAN") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);

        BASE_URI = _baseURI;

        stateString[State.Day] = "Day";
        stateString[State.Night] = "Night";

        colorModesString[State.Day] = "light";
        colorModesString[State.Night] = "dark";

        perceptionsString[State.Day] = "spark";
        perceptionsString[State.Night] = "contemplation";

        tonesString[State.Day] = "vibrant";
        tonesString[State.Night] = "contrast";
    }

    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        BASE_URI = baseURI_;
    }

    function setStateString(State state, string memory s) external onlyRole(SUPPORT_ROLE) {
        stateString[state] = s;
    }
    
    function validOffset(int offset) public pure returns(bool) {
        return (offset >= -14 && offset <= 14);
    }

    function setOffset(uint256 tokenId, int offset) public {
        require(msg.sender == ownerOf(tokenId), "Must be the token owner.");
        require(validOffset(offset), "Invalid offset");
        offsets[tokenId] = offset;
    }

    function getState(uint8 hour) internal pure returns (State) {
        return (hour < 6 || hour >= 18) ? State.Night : State.Day;
    }

    function currentState(uint256 tokenId) public view returns(State) {
        uint256 ts = block.timestamp - (14 * SECONDS_PER_HOUR) + (uint256(offsets[tokenId] + 14) * SECONDS_PER_HOUR);
        return getState(getHour(ts));
    }

    function reserve(address to) external onlyRole(SUPPORT_ROLE) {
        require(totalSupply() == 0, "Already minted");
        for (uint i; i < MAX_TOKENS; i++) {
            _safeMint(to, i);
        }
    }

    function getImageURL(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(BASE_URI,
                                       "/",
                                       stateString[currentState(tokenId)],
                                       ".jpeg"));
    }

    function getAnimationURL(uint256 tokenId) public view returns(string memory) {
        return string(abi.encodePacked(BASE_URI,
                                       "/",
                                       stateString[currentState(tokenId)],
                                       ".mp4"));
    }

    function getName(uint256 tokenId) public pure returns(string memory) {
        return string(abi.encodePacked("Chryseis #",
                                       (tokenId + 1).toString(),
                                       "/",
                                       MAX_TOKENS.toString()));
    }

    function getDescription() internal pure returns(string memory) {
        return "True understanding lies beyond knowledge and conception in the source of awareness...where there seems to be an emergence which on the surface seems like infinite loops processing with each other, but in its core is pure joy...expressing its radiance which is infinite creativity and love.  Chryseis is my first Dynamic NFT which is based on timezone.  The artwork changes between Day and Night mode based on the GMT zone from 6am and 6pm. Music created using generative processing and explorations. Have always loved exploring soundscapes and this comes as a beautiful way of sharing alongside my visual Journey.";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Invalid token id");
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"',getName(tokenId),
                                         '", "description":"',getDescription(),
                                         '", "image":"',getImageURL(tokenId),
                                         '", "animation_url":"',getAnimationURL(tokenId),
                                         '", "attributes":[',
                                            _getChangingData(tokenId),
                                         ']',
                                         '}'));
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _getChangingData(uint256 tokenId) internal view returns(string memory) {
        State state = currentState(tokenId);
        return string(abi.encodePacked(
            _wrapTrait("Color Modes", colorModesString[state]),
            ',',
            _wrapTrait("Perceptions", perceptionsString[state]),
            ',',
            _wrapTrait("Tones", tonesString[state]),
            ',',
            _wrapTrait("Artist", "Archan Nair")
        ));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}