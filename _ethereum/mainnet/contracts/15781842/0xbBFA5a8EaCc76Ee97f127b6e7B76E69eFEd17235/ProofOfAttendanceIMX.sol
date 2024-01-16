/* SPDX-License-Identifier: MIT

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                                
                                                                                
                                                                                
         (@@@@@@#   .@                                                          
     @@@@@@@@@@@@@@@@@@@*                                %@@@@#          (@@@@& 
  ,@@@@@@@&*..*&@@@@@@@@#                               .@@@@@@@@      @@@@@@@@,
 &@@@@@*     &@@@@@@@@@@@                                  %@@@@@@@%#@@@@@@@&   
 @@@@@    .@@@@@@@@#@@@@@/                                   .@@@@@@@@@@@@.     
*@@@@@  &@@@@@@@@   %@@@@%                                     #@@@@@@@@%       
 @@@@@@@@@@@@@(    .@@@@@.                                   @@@@@@@@@@@@@@.    
  @@@@@@@@@@     .@@@@@@,                                 %@@@@@@@&  %@@@@@@@&  
,@@@@@@@@@@@@@@@@@@@@@&                                 @@@@@@@@.       @@@@@@@@
  .@@@@@@@@@@@@@@@@&                                      &@@#            #@*/

pragma solidity ^0.8.12;

/**
 *   @title Fr0ntierX Proof of Attendance
 *   @author Fr0ntier X <dev@fr0ntierx.com>
 *   @notice ERC-721 token for the Fr0ntierX Proof of Attendance product
 */

// IMX support
import "./Mintable.sol";

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

/// @custom:security-contact dev@fr0ntierx.com
contract ProofOfAttendanceIMX is
    ERC721,
    Pausable,
    Ownable,
    ERC721Burnable,
    Mintable
{
    using Strings for uint256;

    // Base URL for the metadata
    string public baseURI = "";

    //  EIP-5129 interface ID
    bytes4 constant SOULBOUND_VALUE = bytes4(keccak256("soulbound")); // 0x9e7ed7f8;

    /**
    @dev Default constructor
     */
    constructor(address _owner, address _imx)
        ERC721("Fr0ntierX Proof Of Attendance", "FXPOA")
        Mintable(_owner, _imx)
    {}

    /**
    @dev Change the base URI for the metadata
    @param uri new base URI
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // Called at the time of withdrawing a minted token from IMX L2 to Mainnet L1.
    function _mintFor(
        address to,
        uint256 id,
        bytes memory
    ) internal override {
        require(
            balanceOf(to) == 0,
            "ProofOfAttendance: the wallet already contains a Proof of Attendance token"
        );

        _safeMint(to, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    @notice Block the transfer of the token to another wallet (only burning is allowed)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        require(
            from == address(0) || to == address(0),
            "ProofOfAttendance: non transferrable"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     @notice Add the soulbound interface as defined in EIP-5192
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == SOULBOUND_VALUE ||
            super.supportsInterface(interfaceId);
    }
}
