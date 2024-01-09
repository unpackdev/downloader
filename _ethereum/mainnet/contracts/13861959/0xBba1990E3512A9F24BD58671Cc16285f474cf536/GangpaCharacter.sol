// contracts/GangpaCharacter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GangpaCharacter is ERC721, VRFConsumerBase, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    address public VRFCoordinator;
    // rinkeby: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
    address public LinkToken;
    // rinkeby: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709a

    struct Character {
        string background;
        string name;
    }

    Character[] public characters;

    mapping(bytes32 => string) requestToCharacterName;
    mapping(bytes32 => address) requestToSender;
    mapping(bytes32 => uint256) requestToTokenId;

    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash)
        public
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("Gangpa", "GPNFT")
    {   
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;
        keyHash = _keyhash;
        fee = 0.1 * 10**18; // 0.1 LINK
    }

    function requestNewRandomCharacter(
        string memory name
    ) public returns (bytes32) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToCharacterName[requestId] = name;
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
         internal
        override
    {
         uint256 newId = characters.length;
         string memory background = "";
        characters.push(
            Character(
                background,
               
                requestToCharacterName[requestId]
            )
        );
        _safeMint(requestToSender[requestId], newId);
    }

    function getNumberOfCharacters() public view returns (uint256) {
        return characters.length; 
    }

    function getCharacterProperties(uint256 tokenId)
        public
        view
        returns (
              string memory
        )
    {
        return (
            characters[tokenId].background
        );
    }

    function sqrt(uint256 x) internal view returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }
}
