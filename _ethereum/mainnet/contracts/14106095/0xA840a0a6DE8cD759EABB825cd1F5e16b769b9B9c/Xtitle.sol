// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./erc721.sol";
import "./utils.sol";
import "./utf8.sol";
import "./IEns.sol";

contract Xtitle is ERC721Enumerable, ReentrancyGuard, Ownable, EnsOwnable {
        uint256 constant _maxTitlePerAddr = 3;
        uint256  _minTitleLen = 9;
        uint256  _maxTitleLen = 32;
        event TitleMint (
            address owner,
            string title,
            uint tokenId
        );

        struct TitleInfo {
            string title;
            uint256 tokenId;
        }

        uint256[] _priceTable = [0, 1e16, 1e17, 1e18, 1e19, 1e20, 1e21];

        //ens contract address, same for Mainnet, Testnet
        address private _ensRegistry = address(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        //admin, who receive ETH from users who add title
        address payable private _contractAdmin = payable(0x1F79544C06bd94c044Bd388ffeE03FeE72025052); 

        mapping(uint256 => string) _titles;
        mapping(bytes32 => bool) _titlesHash;
        uint256 _lastTokenId;

        function updateSettings(uint256 minTitleLen, uint256 maxTitleLen) public {
                require(msg.sender == _contractAdmin, "admin only");
                _minTitleLen = minTitleLen;
                _maxTitleLen = maxTitleLen;
        }

        function queryTitles(address user) public view returns (TitleInfo[] memory) {
                uint256 tokenCount = balanceOf(user);
                TitleInfo[] memory titleInfos = new TitleInfo[](tokenCount);
                for(uint i=0; i<tokenCount; i++) {
                  uint256 tokenId = tokenOfOwnerByIndex(user, i);
                  TitleInfo memory info = TitleInfo(_titles[tokenId], tokenId);
                  titleInfos[i] = info;
                }
                return titleInfos;
        }

        function disableEnsCheck() public onlyOwner() {
                requireENS = false;
        }

        function mint(string memory inputTitle) public nonReentrant  payable onlyEnsOwner {
                uint ensTitleCount = balanceOf(msg.sender);
                require(ensTitleCount < _maxTitlePerAddr, "number of titles exceeded");
                uint256 priceNeed = _priceTable[ensTitleCount];
                require(msg.value >= priceNeed, "paid not enough");

                string memory titleWords = Utils.trim(inputTitle);
                require(bytes(titleWords).length >= _minTitleLen, "title too short");
                require(bytes(titleWords).length <= _maxTitleLen, "title too long");
                //check duplication
                (bytes32 thash, bool titleUsed) = checkTitleUsed(titleWords);
                require(!titleUsed, "title already occupied");

                //save data
                uint256 tokenId = _lastTokenId + 1;
                _titlesHash[thash] = true;
                _titles[tokenId] = titleWords;
                _safeMint(msg.sender, tokenId);

                //transfer money
                _contractAdmin.transfer(msg.value);
                //increase tokenId
                _lastTokenId = tokenId;
                emit TitleMint(msg.sender, _titles[tokenId], tokenId);
        }

        function checkTitleChars(string memory str) internal pure returns (bool) {
                //now, only allow ascii or emoji
                //emoji unicode: https://www.w3schools.com/charsets/ref_emoji.asp
                (int ret, uint32[] memory unicodes) = UTF8.decode(str);
                if (ret < 0) {
                    return false;
                }
                for (uint i=0; i<unicodes.length; i++) {
                    uint32 u = unicodes[i];
                    if (u < 128) {
                        continue;
                    } else if (u==8986 || u==8987) {
                        continue;
                    } else if (u>=9193 && u <= 12953) {
                        continue;
                    } else if (u>=126980 && u <= 129510) {
                        continue;
                    } else {
                        return false;
                    }
                }
                return true;
        }

        function genTitleHash(string memory titleWords) internal pure returns (bytes32) {
                require(checkTitleChars(titleWords), "only ascii characters or emoji are allowed");
                string memory lowerCaseTitle = Utils.lowercase(titleWords);
                bytes32 thash = keccak256(abi.encodePacked(lowerCaseTitle));
                return thash;
        }

        //check if title already used
        function checkTitleUsed(string memory titleWords) public view returns (bytes32, bool) {
                bytes32 thash = genTitleHash(titleWords);
                return (thash, _titlesHash[thash]);
        }

        constructor () ERC721("XTitle", "XT") Ownable() {}

        function tokenURI(uint256 tokenId) override public view returns (string memory) {
                require(tokenId <= _lastTokenId, "not minted");
                require(tokenId > 0, "invalid tokenid");
                string[7] memory parts;
                parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white';
                parts[1] = '; font-family: serif; font-size: 25px; } </style>';
                parts[2] = '<rect width="100%" height="100%" fill="balck" /><text x="10" y="40" class="base">';
                parts[3] = _titles[tokenId];
                parts[4] = '</text></svg>';
                string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
                string memory json = Utils.b64encode(bytes(string(abi.encodePacked('{"name": "XTitle #', Utils.uint2str(tokenId), '", "description": "XTitle is title for ENS.", "image": "data:image/svg+xml;base64,', Utils.b64encode(bytes(output)), '"}'))));
                output = string(abi.encodePacked('data:application/json;base64,', json));
                return output;
        }

}
