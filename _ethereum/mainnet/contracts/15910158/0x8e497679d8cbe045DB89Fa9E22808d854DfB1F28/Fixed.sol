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

/// @title ffxxdd mining rig mint contract.
/// @author Osman Ali.
/// @notice A ffxxdd mining rig can be staked to earn vvddrr.
contract Fixed is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice The background color of the ffxxdd mining rig.
    string private blackBackground = "000000";

    /// @notice The percentage mining return value for all ffxxdd mining rigs.
    uint256 private fixedPercentage = 10000;

    /// @notice The price of one ffxxdd mining rig.
    uint256 private price = 20000000000000000; // 0.02 Ether

    /// @notice The maximum number of ffxxdd mining rigs available for minting.
    uint256 public constant MAX_TOKENS = 100000;

    /// @notice The maximum number of ffxxdd mining rigs that can be purchased per transaction.
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 1;

    /// @notice A mapping of an address to a boolean indicating whether that address has acquired a mining rig.
    /// @dev This value is not unset at any point to avoid shift away single address mining.
    mapping(address => bool) public activeMiners;

    /// @notice Create the ffxxdd mining rig contract.
    constructor() ERC721("ffxxdd", "FFXXDD") Ownable() {}

    /// @notice Transform the basis point percentage assigned to a tokenId into a string.
    /// @param tokenId The tokenid whose mining percentage is to be stringified.
    function getMiningPercentageValue(uint256 tokenId) external view returns (uint256) {
        return fixedPercentage;
    }

    /// @notice Enter your wallet address to see which ffxxdd mining rigs you own.
    /// @param _owner The wallet address of a ffxxdd minting rig token owner.
    /// @return An array of the ffxxdd minting rig tokenIds owned by the address.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
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

    /// @notice Mint a ffxxdd mining rig.
    function mint(uint256 _count) public payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count), "Value sent is not correct");
        require(activeMiners[_msgSender()] == false, "Address already has mining rig");
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
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
        uint256 removeBasis = fixedPercentage / 100;
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

    /// @notice Generates the tokenURI for each ttkknn.
    /// @param tokenId The ttkknn token for which a URI is to be generated.
    /// @return The tokenURI formatted as a string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[7] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 700 700"><rect width="700" height="700" fill="#';
        p[1] = blackBackground;
        p[2] = '"></rect><rect x="340" y="340" width="10" height="10" fill="#';
        p[3] = getLeftSquareColor(tokenId);
        p[4] = '"></rect><rect x="350" y="340" width="10" height="10" fill="#';
        p[5] = getRightSquareColor(tokenId);
        p[6] = '"></rect></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "ffxxdd mining rig #', toString(tokenId), '", "description": "fulfill your destiny.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
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
          uint256 v = random(string(abi.encodePacked("75726db8-2f83-4403-9513-92bc30cab377", _msgSender(), block.timestamp, toString(tokenId))));
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
          uint256 v = random(string(abi.encodePacked("1cec0adf-a786-4a2f-aa1a-47968cf880e5", _msgSender(), block.timestamp, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;
      string memory j = string(abi.encodePacked(r[13],r[16],r[8],r[6],r[0],r[2]));
      return j;
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

    /// @notice A general random function to be used to shuffle and generate values.
    /// @param input Any string value to be randomized.
    /// @return The output of a random hash using keccak256.
    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

}
