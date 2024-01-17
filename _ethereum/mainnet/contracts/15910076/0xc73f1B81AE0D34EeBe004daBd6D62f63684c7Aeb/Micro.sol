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

/// @title mmccrr mining rig mint contract.
/// @author Osman Ali.
/// @notice A mmccrr mining rig can be staked to earn vvddrr.
contract Micro is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice The background color of the mmccrr mining rig.
    string private blackBackground = "000000";

    /// @notice The price of one mmccrr mining rig.
    uint256 private price = 5000000000000000; // 0.005 Ether

    /// @notice The maximum number of mmccrr mining rigs available for minting.
    uint256 public constant MAX_TOKENS = 100000;

    /// @notice The maximum number of mmccrr mining rigs that can be purchased per transaction.
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1;

    /// @notice A mapping of an address to a boolean indicating whether that address has acquired a mining rig.
    /// @dev This value is not unset at any point to avoid shift away single address mining.
    mapping(address => bool) public activeMiners;

    /// @notice An array holding all the mining percentages assigned to each tokenId.
    uint256[100000] public miningPercentageValue;

    /// @notice An randomly shuffled array of all the available percentage available to be assigned to a mining rig.
    /// @dev Expressed in percentage basis points.
    uint256[41] private percentages = [3200, 3500, 2400, 1700, 4500, 3000, 4700, 4900, 2200, 1200, 4300, 2300, 5000, 4000, 3600, 1300, 4200, 1900, 4100, 3300, 3900, 3400, 2800, 1400, 2100, 3800, 1800, 3100, 3700, 2000, 4600, 1000, 1600, 2500, 4400, 1100, 2700, 1500, 2600, 4800, 2900];

    /// @notice Create the mmccrr mining rig contract.
    constructor() ERC721("mmccrr", "MMCCRR") Ownable() {}

    /// @notice An explicit function to provide the mining percentage for a speciic tokenId.
    /// @param tokenId The tokenId for which to retrieve a mining percentage value.
    function getMiningPercentageValue(uint256 tokenId) external view returns (uint256) {
        return miningPercentageValue[tokenId];
    }

    /// @notice Enter your wallet address to see which mmccrr mining rigs you own.
    /// @param _owner The wallet address of a mmccrr minting rig token owner.
    /// @return An array of the mmccrr minting rig tokenIds owned by the address.
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

    /// @notice Mint a mmccrr mining rig.
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

    /// @notice Generates the tokenURI for each mmccrr mining rig.
    /// @param tokenId The mmccrr mining rig token for which a URI is to be generated.
    /// @return The tokenURI formatted as a string.
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[9] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 700 700"><rect width="700" height="700" fill="#';

        p[1] = blackBackground;

        p[2] = '"></rect><rect x="';

        p[3] = xValue(tokenId);

        p[4] = '" y="';

        p[5] = yValue(tokenId);

        p[6] = '" width="10" height="10" fill="#';

        p[7] = getSquareColor(tokenId);

        p[8] = '"></rect></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "mmccrr mining rig #', toString(tokenId), '", "description": "fulfill your destiny.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
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
    function getSquareColor(uint256 tokenId) private view returns (string memory) {
      string[32] memory r;
      string[32] memory s = ["a", "3", "4", "1", "e", "7", "5", "9", "b", "d", "2", "8", "f", "0", "c", "6", "2", "8", "e", "3", "9", "6", "0", "b", "5", "d", "f", "4", "a", "1", "7", "c"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("b3d01e7d-fcaa-44dd-94a3-4805d209f1ea", _msgSender(), block.timestamp, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[3],r[17],r[1],r[14],r[9],r[12]));
      return j;
    }

    /// @notice Generate the attributes to be used for the token metadata.
    /// @param tokenId The token for which the metadata is to be generated.
    /// @return A string of the metadata for the token.
    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        string[2] memory traits;

        traits[0] = string(abi.encodePacked('{"trait_type":"left:","value":"', getSquareColor(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"mining percentage:","value":"', getPercentageDescription(tokenId), '"}'));


        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1]));

        return attributes;
    }

    /// @notice Randomly select a mining percentage from the available array.
    /// @param tokenId The tokenId for which to generate a mining percentage.
    /// @return A mining percentage expressed in percentage basis points.
    function miningPercentage(uint256 tokenId) private view returns (uint256) {
      uint l = percentages.length;
      uint256 v = random(string(abi.encodePacked("8c408fced58b333002a1dab7326e777248381ee005eca96bb1c0479969a24d2b", _msgSender(), block.timestamp, toString(tokenId))));
      uint256 i = v % l--;
      uint256 r = percentages[i];
      return r;

    }

    /// @notice Generate the svg x value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the x value.
    function xValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("49a9742b-30af-4915-b5de-60c589fecb59", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
        if (v < 10) {
            v = 10;
        }
        string memory r = toString(v);
        return r;
    }

    /// @notice Generate the svg y value.
    /// @param tokenId The current tokenId for which the value is being generated.
    /// @return A string representing the y value.
    function yValue(uint256 tokenId) private view returns(string memory) {
        uint v = uint(keccak256(abi.encodePacked("7958329f-601a-459f-a09a-8201c901be81", _msgSender(), block.timestamp, toString(tokenId)))) % 681;
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
