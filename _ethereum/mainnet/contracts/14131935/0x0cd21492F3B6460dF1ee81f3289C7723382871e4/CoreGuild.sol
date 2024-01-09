
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import "./ILore.sol";
import "./IERC721Metadata.sol";
import "./IERC1155MetadataURI.sol";

import "./CoreMimic.sol";
import "./GuildOwnable.sol";


contract CoreGuild is GuildOwnable, ILore {

    ////
    // Guild Data

    CoreMimic cMimic;
    address aShield;
    address aMeta;

    uint256 guildGenesis;
    uint256 guildRate18;

    ////
    // Events

    event Expedition(address indexed voyager, uint256 cost);

    ////
    // Constructor / init

    constructor(uint256 _guildGenesis, uint256 _guildRate18) {
        guildGenesis = _guildGenesis;
        guildRate18 = _guildRate18;
    }

    function init(address _mimic, address _shield, address _meta) external onlyOwner {
        require(address(cMimic) == address(0x0), "already initialized");
        cMimic = CoreMimic(_mimic);
        aShield = _shield;
        aMeta = _meta;
    }

    ////
    // Expeditions / Guild

    function guild_Expedition() public payable {
        require(cMimic.balanceOf(msg.sender) <= (cMimic.totalSupply() / 10), "gateway timeout"); // The Tourist - Chorus
        uint256 cost = guild_GetExpeditionCostInWei();
        require(msg.value >= cost, "We'll need more sauerkraut, Cap'n!");
        require(msg.value <= (cost + 2e16), "That's too much sauerkraut, Cap'n!");
        cMimic.cGuild_Mint(msg.sender);
        emit Expedition(msg.sender, msg.value);
    }

    function guild_GetExpeditionCostInWei() public view returns (uint256) {
        uint256 foundRate18 = guildRate18 * cMimic.totalSupply();
        uint256 epoch = block.timestamp - guildGenesis;
        uint256 price = foundRate18  / epoch;
        return price;
    }

    function guildmaster_Withdraw(uint256 _amount) external onlyOwnerOrActiveBackup {
        (bool success, ) = payable(msg.sender).call{ value: _amount }("");
        require(success, "nope");
    }

    ////
    // Lore / Introspection

    function lore() external view returns (string memory) {
        return string(abi.encodePacked(
            innerLore(),
            "\n",
            loreAddress("   Guild", address(this)),
            loreAddress("   Mimic", address(cMimic)),
            loreAddress("  Shield", aShield),
            loreAddress("Metadata", aMeta)
        ));
    }

    function loreAddress(string memory _name, address _address) internal pure returns (string memory) {
        return string(abi.encodePacked(_name, " Contract: 0x", string(addressToPaddedBytesHex(_address)), "\n"));
    }

    function innerLore() internal pure virtual returns (string memory) {
        return "OVERRIDE ME";
    }

    function getGuildAddress() external view returns(address) { return address(this); }
    function getMimicAddress() external view returns(address) { return address(cMimic); }
    function getShieldAddress() external view returns(address) { return aShield; }
    function getMetadataAddress() external view returns(address) { return aMeta; }

    ////
    // Tokenology

    function tokenologist_IsTokenErc721(address _tokenContract, uint _tokenId) public view returns (bool) {
        (bool uriCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", _tokenId));
        (bool ownerCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", _tokenId));

        return uriCheck && ownerCheck;
    }

    function tokenologist_IsTokenErc1155(address _tokenContract, uint _tokenId) public view returns (bool) {
        (bool uriCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("uri(uint256)", _tokenId));
        (bool ownerCheck, ) = _tokenContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", address(0x1337), _tokenId));

        return uriCheck && ownerCheck;
    }

    function tokenologist_IdentifyTokenFormat(address _tokenContract, uint256 _tokenId) public view returns (string memory) {
        if (tokenologist_IsTokenErc721(_tokenContract, _tokenId)) {
            return "ERC721";
        }

        if (tokenologist_IsTokenErc1155(_tokenContract, _tokenId)) {
            return "ERC1155";
        }

        return "Unknown Token Format";
    }

    function tokenologist_DoesTokenUseIdReplace(address _tokenContract, uint256 _tokenId) public view returns (bool) {
        bytes memory uriBytes;
        bool success;

        (success, uriBytes) = _tokenContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", _tokenId));

        if (!success) {
            (success, uriBytes) = _tokenContract.staticcall(abi.encodeWithSignature("uri(uint256)", _tokenId));
        }

        if (!success) {
            revert("Unknown Result");
        }

        return uriIdDetect(abi.decode(uriBytes, (string)));
    }

    ////
    // Util

    function uriIdDetect(string memory uri) internal pure returns (bool) {
        bytes memory s = bytes(uri);
        uint sLen = s.length;
        if (sLen < 4) {
            return false; // can't fit "{id}
        }

        uint sLenM3 = sLen - 3;

        uint si = 0;
        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                return true;
            }
            si++;
        }

        return false;
    }

    function addressToPaddedBytesHex(address _address) internal pure returns(bytes memory) {
        bytes20 _bytes = bytes20(_address);
        bytes memory HEX = "0123456789abcdef";
        bytes memory _out = new bytes(40);
        for(uint i = 0; i < 20; i++) {
            _out[i*2] = HEX[uint8(_bytes[i] >> 4)];
            _out[1+i*2] = HEX[uint8(_bytes[i] & 0x0f)];
        }
        return _out;
    }
}

