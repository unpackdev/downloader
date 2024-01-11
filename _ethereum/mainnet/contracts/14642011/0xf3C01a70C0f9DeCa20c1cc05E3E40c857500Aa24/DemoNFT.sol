//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./UsingHexagons.sol";
import "./Constants.sol";

contract DemoNFT is ERC721Enumerable, UsingHexagons {
    using Strings for uint256;

    struct Info {
        string hair;
    }

    mapping(uint256 => Info) public tokenInfo;
    string public baseURI;

    constructor() ERC721("Demo NFT", "DNFT") UsingHexagons() {}

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "DemoNFT: URI query for nonexistent token");

        Info storage info = tokenInfo[_tokenId];

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), "/", info.hair)) : "";
    }

    function mint() external {
        uint256 tokenId = totalSupply();
        tokenInfo[tokenId] = Info("blonde");
        _mint(msg.sender, tokenId);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    function setHairFor(string calldata _hair, uint256 _tokenId) external onlyOwner {
        tokenInfo[_tokenId].hair = _hair;
    }

    function getInfoOf(uint256 _tokenId) public view returns (Info memory) {
        return tokenInfo[_tokenId];
    }

    function _onHexagonsProtocolMessage(
        uint256 _protocolId,
        address _author,
        bytes calldata _data
    ) internal override {
        if (_protocolId == Constants.PROTOCOL_TWITTER) {
            string memory data = string(_data);

            uint256 tokenId = 0; // FIXME: extract it from _data
            Info storage info = tokenInfo[tokenId];

            if (_contains(data, "blonde")) {
                info.hair = "blonde";
                return;
            }
            if (_contains(data, "brown")) {
                info.hair = "brown";
                return;
            }
            if (_contains(data, "blue")) {
                info.hair = "blue";
                return;
            }

        } 
        if (_protocolId == Constants.PROTOCOL_LENS) {
            // TODO: handle messages coming from the Hexagons Lens Reference Module
        } 
    }

    function _contains (string memory _what, string memory _where) internal pure returns(bool) {
        bytes memory whatBytes = bytes (_what);
        bytes memory whereBytes = bytes (_where);

        if (whereBytes.length < whatBytes.length) return false;

        bool found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
       return found;
    }
}
