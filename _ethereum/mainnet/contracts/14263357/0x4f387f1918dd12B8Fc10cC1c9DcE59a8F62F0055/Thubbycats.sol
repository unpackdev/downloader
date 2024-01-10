// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";

import "./Base64.sol";

contract Thubbycats is ERC721, Ownable {
    using Strings for uint256;
    using Address for address;
    using Address for address payable;

    /**
     * Constants
     */

    uint256 public constant MINTING_TIP = 0.01 ether;
    address public constant TUBBY_CONTRACT =
        0xCa7cA7BcC765F77339bE2d648BA53ce9c8a262bD;
    address public constant TUBBY_TREASURY =
        0x5FE038640E440006e1002EbE69b22E12C5c055aD;

    /**
     * Variables
     */

    string public baseURI;

    constructor(string memory _baseURI) ERC721("Thubby Cats", "THUBBY") {
        baseURI = _baseURI;
    }

    /**
     * Public functions
     */

    /// @dev Mint a thubby cat
    function mint(uint256 _tokenId) external payable {
        require(msg.value >= MINTING_TIP, "Not enough ether");

        _mint(msg.sender, _tokenId);

        IERC721 tubbies = IERC721(TUBBY_CONTRACT);
        address tubbyOwner = tubbies.ownerOf(_tokenId);

        // If the original tubby cat has an owner
        // and it's an EOA, forward minting fees to them
        if (tubbyOwner != address(0) && !tubbyOwner.isContract()) {
            payable(tubbyOwner).sendValue(MINTING_TIP);
        }
    }

    /// @dev Check if the thubby cat is still available
    function isMintable(uint _tokenId) external view returns (bool) {
        return !_exists(_tokenId);
    }

    /// @dev Get token metadata URI
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    /// @dev Get base64-encoded contract metadata
    function contractURI() external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"thubby cats",',
                                    '"description":"thubby cats is a flipped tubby cats derivative with a twist. All secondary sale royalties go to the tubby cats treasury and minting fees to OG tubby cat holders. Note that thubby cats are in no way affiliated with the tubby cats project or the tubby collective.",',
                                    // Same 2.5% royalties as tubby cats
                                    '"seller_fee_basis_points": 250,'
                                    // Send royalties to the tubby cats treasury
                                    '"fee_recipient": "',
                                    uint256(uint160(TUBBY_TREASURY))
                                        .toHexString(),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * Admin functions
     */

    /// @dev Withdraw minting fees
    function withdraw(address payable _destination) external onlyOwner {
        _destination.sendValue(address(this).balance);
    }

    /// @dev Update baseURI
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }
}
