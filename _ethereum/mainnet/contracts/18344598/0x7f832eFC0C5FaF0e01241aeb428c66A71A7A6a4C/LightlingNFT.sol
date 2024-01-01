// SPDX-License-Identifier: MIT
//
//
//   █ ▄▄  ██   █▄▄▄▄    ▄▄▄▄▀ ▄█ ▄█▄    █     ▄███▄       ▄█    ▄   █  █▀ 
//   █   █ █ █  █  ▄▀ ▀▀▀ █    ██ █▀ ▀▄  █     █▀   ▀      ██     █  █▄█   
//   █▀▀▀  █▄▄█ █▀▀▌      █    ██ █   ▀  █     ██▄▄        ██ ██   █ █▀▄   
//   █     █  █ █  █     █     ▐█ █▄  ▄▀ ███▄  █▄   ▄▀     ▐█ █ █  █ █  █  
//    █       █   █     ▀       ▐ ▀███▀      ▀ ▀███▀        ▐ █  █ █   █   
//     ▀     █   ▀                                            █   ██  ▀    
//          ▀                                                              
                                                                                                           
                                                                                                                                            
pragma solidity 0.8.17;

import "./ERC721SeaDropUpgradeable.sol";

library LightlingTokenStorage {
    struct Layout {
        /// @notice The only address that can burn tokens on this contract.
        address burnAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("seaDrop.contracts.storage.lightling");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

/*
 * @notice This contract uses ERC721SeaDrop,
 *         an ERC721A token contract that is compatible with SeaDrop.
 *         The set burn address is the only sender that can burn tokens.
 */
contract LightlingNFT is ERC721SeaDropUpgradeable  {
    
    using LightlingTokenStorage for LightlingTokenStorage.Layout;
    
    function init() external initializer initializerERC721A {
        // Addresses
        address seadrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;

        // Token config
        string memory tokenName = "Genesis pARticle pack";
        string memory tokenSymbol = "LIGHTLING";
        
        address[] memory allowedSeadrop = new address[](1);
        allowedSeadrop[0] = seadrop;
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            tokenName,
            tokenSymbol,
            allowedSeadrop
        );
    }

    /**
     * @notice A token can only be burned by the set burn address.
     */
    error BurnIncorrectSender();

    /**
     * @notice Initialize the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function setBurnAddress(address newBurnAddress) external onlyOwner {
        LightlingTokenStorage.layout().burnAddress = newBurnAddress;
    }

    function getBurnAddress() public view returns (address) {
        return LightlingTokenStorage.layout().burnAddress;
    }

    /**
     * @notice Destroys `tokenId`, only callable by the set burn address.
     *
     * @param tokenId The token id to burn.
     */
    function burn(uint256 tokenId) external {
        if (msg.sender != LightlingTokenStorage.layout().burnAddress) {
            revert BurnIncorrectSender();
        }

        _burn(tokenId);
    }
    
}
