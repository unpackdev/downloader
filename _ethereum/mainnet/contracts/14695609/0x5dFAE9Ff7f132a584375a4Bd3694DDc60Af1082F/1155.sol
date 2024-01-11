pragma solidity ^0.8.4;

import "./ONFT1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract TinyGirls is ONFT1155 {
    
    string public name = "TinyGirls";
    string public symbol = "TG";

    //@notice Old TinyGirls Contract
    IERC721 public immutable oldContract;

    //@notice Support for ERC2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    //@notice Royalty Variables
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    constructor(address _layerZeroEndpoint, address _oldContract, address royaltyAddress, uint256 royaltyPercentage) ONFT1155("", _layerZeroEndpoint) {
        oldContract = IERC721(_oldContract);
        _royaltyAddress = royaltyAddress;
        _royaltyPercentage = royaltyPercentage;
        baseTokenURI = "ipfs://QmTkA2ue7mqfe7zYSNE4BYoanm6bcSM5WHz2S5LDuvjxbz/";
    }

    //@notice Migrates a oldContract token to current
    function remint(uint256[] memory tokenIds) external {
        uint256[] memory amounts = new uint256[](tokenIds.length);
        unchecked {
            for(uint256 i; i < tokenIds.length; i++) {
                uint256 currentId = tokenIds[i];
                amounts[i] = 1;
                oldContract.transferFrom(msg.sender, address(this), currentId);
            }
        }
        _mintBatch(msg.sender, tokenIds, amounts, "");
    }

    function withdraw(address user, uint256[] memory tokenIds) external onlyOwner {
        unchecked {
            for(uint256 i; i < tokenIds.length;i++) {
                oldContract.transferFrom(address(this), user, tokenIds[i]);
            }
        }
    }

    //@notice Update royalty percentage
    //@param percentage to edit
    function editRoyaltyFee(address user, uint256 bps) external onlyOwner {
        _royaltyPercentage = bps;
        _royaltyAddress = user;
    }

    //@notice View royalty info for tokens
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyAddress, value * _royaltyPercentage / 10000);
    }
    function uri(uint256 tokenId) override public view returns (string memory) {
        // Tokens minted above the supply cap will not have associated metadata.
        
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function setURI(string memory newURI) external onlyOwner {
        baseTokenURI = newURI;
    }
}
