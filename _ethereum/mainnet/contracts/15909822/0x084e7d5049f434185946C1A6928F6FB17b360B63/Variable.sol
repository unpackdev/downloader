// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Arrays.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

/// @title vvrrbb mining rig mint contract.
/// @author Osman Ali.
/// @notice A vvrrbb mining rig can be staked to earn vvddrr.
contract Variable is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice The background color of the vvrrbb mining rig.
    string private blackBackground = "000000";

    /// @notice The price of one vvrrbb mining rig.
    uint256 private price = 10000000000000000; // 0.01 Ether

    /// @notice The maximum number of vvrrbb mining rigs available for minting.
    uint256 public constant MAX_TOKENS = 100000;

    /// @notice The maximum number of vvrrbb mining rigs that can be purchased per transaction.
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1;

    /// @notice A mapping of an address to a boolean indicating whether that address has acquired a mining rig.
    /// @dev This value is not unset at any point to avoid shift away single address mining.
    mapping(address => bool) public activeMiners;

    /// @notice An array holding all the mining percentages assigned to each tokenId.
    uint256[100000] public miningPercentageValue;

    /// @notice An randomly shuffled array of all the available percentage available to be assigned to a mining rig.
    /// @dev Expressed in percentage basis points.
    uint256[101] private percentages = [10800, 6300, 10400, 9100, 5400, 12600, 7400, 14700, 13700, 7700, 9500, 7900, 12200, 11500, 11800, 8600, 14600, 12500, 10500, 9700, 9300, 14200, 11000, 13900, 9900, 7000, 9600, 13100, 13400, 9000, 11200, 7200, 7600, 6700, 5700, 8500, 8800, 14300, 6800, 13500, 14800, 13200, 9800, 9400, 10300, 14900, 12000, 12900, 5300, 5100, 5600, 12700, 8100, 9200, 5800, 13800, 11100, 5200, 7800, 11300, 8000, 14100, 7300, 5900, 14400, 8400, 7100, 8200, 5500, 8900, 11900, 12100, 14000, 13000, 6200, 8300, 8700, 10700, 13300, 12400, 11400, 7500, 10600, 14500, 10100, 6600, 12800, 5000, 6500, 10900, 6100, 12300, 10200, 6400, 11700, 13600, 15000, 10000, 6900, 11600, 6000];

    /// @notice Create the vvrrbb mining rig contract.
    constructor() ERC721("vvrrbb", "VVRRBB") Ownable() {}

    /// @notice An explicit function to provide the mining percentage for a speciic tokenId.
    /// @param tokenId The tokenId for which to retrieve a mining percentage value.
    function getMiningPercentageValue(uint256 tokenId) external view returns (uint256) {
        return miningPercentageValue[tokenId];
    }

    /// @notice Enter your wallet address to see which vvrrbb mining rigs you own.
    /// @param _owner The wallet address of a vvrrbb minting rig token owner.
    /// @return An array of the vvrrbb minting rig tokenIds owned by the address.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /// @notice Mint a vvrrbb mining rig.
    function mint(uint256 _count) public payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count), "Value sent is not correct");
        require(activeMiners[_msgSender()] == false, "Address already has mining rig");
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
            miningPercentageValue[totalSupply + i] = miningPercentage(totalSupply + i);
            activeMiners[_msgSender()] = true;
        }
    }

    /// @notice The contract owner can withdraw ETH accumulated in the contract.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice Transform the basis point percentage assigned to a tokenId into a string.
    /// @param tokenId The tokenid whose mining percentage is to be stringified.
    function getPercentageDescription(uint256 tokenId) public view returns (string memory) {
        uint256 removeBasis = miningPercentageValue[tokenId] / 100;
        string memory statement = string(abi.encodePacked(toString(removeBasis)," %"));
        return statement;
    }

    /// @dev Required override for ERC721Enumerable.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Generates the tokenURI for each vvrrbb mining rig.
    /// @param tokenId The vvrrbb mining rig token for which a URI is to be generated.
    /// @return The tokenURI formatted as a string.
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[15] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 700 700"><rect width="700" height="700" fill="#';

        p[1] = blackBackground;

        p[2] = '"></rect><rect x="';

        p[3] = leftXValue(tokenId);

        p[4] = '" y="';

        p[5] = leftYValue(tokenId);

        p[6] = '" width="10" height="10" fill="#';

        p[7] = getLeftSquareColor(tokenId);

        p[8] = '"></rect><rect x="';

        p[9] = rightXValue(tokenId);

        p[10] = '" y="';

        p[11] = rightYValue(tokenId);

        p[12] = '" width="10" height="10" fill="#';

        p[13] = getRightSquareColor(tokenId);

        p[14] = '"></rect></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        o = string(abi.encodePacked(o, p[9], p[10], p[11], p[12], p[13], p[14]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "vvrrbb mining rig #', toString(tokenId), '", "description": "fulfill your destiny.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    /// @dev Required override for ERC721Enumerable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Returns an integer value as a string.
    /// @param value The integer value to have a type change.
    /// @return A string of the inputted integer value.
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

    /// @notice A shuffle function to output a random hex string for the left square color.
    /// @param tokenId The tokenId for which a left square color value is to be generated.
    /// @return A string providing a hex color value.
    function getLeftSquareColor(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["a", "3", "4", "1", "e", "7", "5", "9", "b", "d", "2", "8", "f", "0", "c", "6", "2", "8", "e", "3", "9", "6", "0", "b", "5", "d", "f", "4", "a", "1", "7", "c"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("9d39cb50-d006-44d9-a353-9f32683dfc7f", _msgSender(), block.timestamp, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[3],r[17],r[1],r[14],r[9],r[12]));
      return j;
    }

    /// @notice A shuffle function to output a random hex string for the right square color.
    /// @param tokenId The tokenId for which a right square color value is to be generated.
    /// @return A string providing a hex color value.
    function getRightSquareColor(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["7", "4", "c", "5", "2", "b", "d", "6", "0", "f", "e", "3", "8", "a", "1", "9", "4", "0", "b", "f", "1", "e", "d", "a", "3", "7", "c", "9", "2", "6", "5", "8"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("34735ca9-9194-4d25-ae44-b3316cc887b4", _msgSender(), block.timestamp, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[13],r[16],r[8],r[6],r[0],r[2]));
      return j;
    }

    /// @notice Generate the left svg x value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the left x value.
    function leftXValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("a54a22a5-6f47-4a68-b65e-a968bcf3b141", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
        if (v < 10) {
            v = 10;
        }
        string memory r = toString(v);
        return r;
    }

    /// @notice Generate the left svg y value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the left y value.
    function leftYValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("a39fb398-a209-445f-b6af-f80d13e83e17", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
        if (v < 10) {
            v = 10;
        }
        string memory r = toString(v);
        return r;
    }

    /// @notice Generate the attributes to be used for the token metadata.
    /// @param tokenId The token for which the metadata is to be generated.
    /// @return A string of the metadata for the token.
    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        string[3] memory traits;

        traits[0] = string(abi.encodePacked('{"trait_type":"left:","value":"', getLeftSquareColor(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"right:","value":"', getRightSquareColor(tokenId), '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"mining percentage:","value":"', getPercentageDescription(tokenId), '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2]));

        return attributes;
    }

    /// @notice Randomly select a mining percentage from the available array.
    /// @param tokenId The tokenId for which to generate a mining percentage.
    /// @return A mining percentage expressed in percentage basis points.
    function miningPercentage(uint256 tokenId) private view returns (uint256) {
      uint l = percentages.length;
      uint256 v = random(string(abi.encodePacked("084811ff82358069939e38f31ae4e8ec160420126e7e151521a1583539a60b77", _msgSender(), block.timestamp, toString(tokenId))));
      uint256 i = v % l--;
      uint256 r = percentages[i];
      return r;
    }

    /// @notice Generate the right svg x value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the right x value.
    function rightXValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("f967b88e-5ee5-47dd-b1ce-5eeb37adf0c2", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
        if (v < 10) {
            v = 10;
        }
        string memory r = toString(v);
        return r;
    }

    /// @notice Generate the right svg y value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the right y value.
    function rightYValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("fbe26347-fe31-4bc5-a8c8-b19554acf47c", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
        if (v < 10) {
            v = 10;
        }
        string memory r = toString(v);
        return r;
    }

    /// @notice A general random function to be used to shuffle and generate values.
    /// @param input Any string value to be randomized.
    /// @return The output of a random hash using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

}
