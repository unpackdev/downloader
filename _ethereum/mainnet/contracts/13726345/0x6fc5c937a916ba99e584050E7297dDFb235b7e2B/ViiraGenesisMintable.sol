// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

/**

oooooo     oooo ooooo ooooo ooooooooo.         .o.         
 `888.     .8'  `888' `888' `888   `Y88.      .888.        
  `888.   .8'    888   888   888   .d88'     .8"888.      
   `888. .8'     888   888   888ooo88P'     .8' `888.    
    `888.8'      888   888   888`88b.      .88ooo8888.  
     `888'       888   888   888  `88b.   .8'     `888.
      `8'       o888o o888o o888o  o888o o88o     o8888o   


VIIRA Genesis Artist Contract

Author: github.com/iainnnash
Purpose: Generalized semi-centralized artist minting contract for viira.io platform
 */

import "./ERC721.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";

struct ConfigSettings {
    string uriBase;
    string ipfsBase;
    address royaltyPayout;
    uint256 ipfsMax;
}

contract ViiraGenesisMintable is ERC721, IERC2981, Ownable {
    mapping(address => bool) private allowedMinters;
    mapping(address => bool) private allowedMarkets;
    string private constant ALLOWED_ERROR = "Only allowed";
    ConfigSettings private advancedConfig;
    uint256 private supplyCounter;

    constructor() ERC721("VIIRA.IO", "VIIRANFT") {}

    /// Only allow certain minters
    modifier onlyAllowedMinter() {
        require(
            allowedMinters[msg.sender] || msg.sender == owner(),
            ALLOWED_ERROR
        );
        _;
    }

    /// IERC721 enumerable partial spec
    function totalSupply() external view returns (uint256) {
        return supplyCounter;
    }

    /// IERC721 optional extension
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), ALLOWED_ERROR);
        _burn(tokenId);
        supplyCounter -= 1;
    }

    /// artist direct mint fn
    function mint(address recipient, uint256[] calldata tokenIds) external onlyAllowedMinter {
        supplyCounter += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(recipient, tokenIds[i]);
        }
    }

    /// admin mint batch to users
    /// arrays need to align
    function mintAdminBatch(
        uint256[] calldata tokenIds,
        address[] calldata creators,
        bool transferAdmin
    ) external onlyOwner {
        require(tokenIds.length == creators.length, "wrong args");
        supplyCounter += tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            address creator = creators[i];
            uint256 tokenId = tokenIds[i];
            _mint(creator, tokenId);
            if (transferAdmin) {
                _transfer(creator, msg.sender, tokenId);
            }
        }
    }

    /// Default simple token-uri implementation. works for ipfs folders too
    /// @param tokenId token id ot get uri for
    /// @return default uri getter functionality
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");

        return
            string(
                abi.encodePacked(
                    (tokenId < advancedConfig.ipfsMax)
                        ? advancedConfig.ipfsBase
                        : advancedConfig.uriBase,
                    Strings.toString(tokenId)
                )
            );
    }

    /// Getter to expose approval status with allowed proxy markets
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            ERC721.isApprovedForAll(_owner, operator) ||
            allowedMarkets[operator];
    }

    // IERC2981 spec
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        address payout = advancedConfig.royaltyPayout;
        if (payout == address(0x0)) {
            payout = owner();
        }
        return (payout, (salePrice * 1000) / 10000);
    }

    // Admin functions

    /// Set base media uri
    function setBaseURI(string memory uriPrefix) external onlyOwner {
        advancedConfig.uriBase = uriPrefix;
    }

    function setRoyaltyPayoutAddress(address _royaltyPayout)
        external
        onlyOwner
    {
        advancedConfig.royaltyPayout = _royaltyPayout;
    }

    function setIpfsBase(string memory ipfsPrefix, uint256 ipfsMax)
        external
        onlyOwner
    {
        advancedConfig.ipfsBase = ipfsPrefix;
        advancedConfig.ipfsMax = ipfsMax;
    }

    /// Set allowed markets
    function setAllowedMarket(address market, bool allowed) external onlyOwner {
        allowedMarkets[market] = allowed;
    }

    // Set allowed minters
    function setAllowedMinters(address[] calldata creators, bool status)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < creators.length; i++) {
            allowedMinters[creators[i]] = status;
        }
    }
}
