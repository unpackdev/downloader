// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./Base64.sol";

contract PresidentialNFT is ERC721Enumerable, Ownable {
    using Address for address payable;

    /**********************
     * Variables & events *
     **********************/

    uint256 public constant MAX_PRINT_COUNT = 1826;

    uint256 public currentPrintCount = 0;
    mapping(address => bool) public hasMinted;

    string private ipfsHash = "QmY5Wgvv5atmTZPW5mNEuFa8f9JcNoaWRUPPCixbQN2Dib";

    constructor() ERC721("PresidentialNFT", "PRESIDENT") {}

    /******************
     * Public actions *
     ******************/

    /**
     * @dev Mint a new print of the original NFT
     */
    function mint() public {
        require(currentPrintCount < MAX_PRINT_COUNT, "No prints left");
        require(!hasMinted[msg.sender], "One mint per wallet");

        currentPrintCount += 1;
        hasMinted[msg.sender] = true;

        _safeMint(msg.sender, currentPrintCount);
    }

    /******************
     * View functions *
     ******************/

    /**
     * @dev Get the base64-encoded token metadata JSON
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory name = "President Kersti Kaljulaid";
        string memory description;

        if (tokenId == 0) {
            description = "The original NFT accompanying President Kaljulaid's portrait (painted by Alice Kask) gifted to her on 09.10.2021.";
        } else {
            name = string(
                abi.encodePacked("Print #", _toString(tokenId), " of ", name)
            );

            description = "This is a copy of the original NFT gifted to President Kersti Kaljulaid. 1826 are freely mintable by anyone, one for each day she was in office.";
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "',
                        description,
                        '", "image": "ipfs://',
                        ipfsHash,
                        '"}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /*******************
     * Admin functions *
     *******************/

    /**
     * @dev Mint the original NFT to target wallet
     */
    function claim(address to) public onlyOwner {
        _safeMint(to, 0);
    }

    /**
     * @dev Update the IPFS hash for the token image
     */
    function setIpfsHash(string memory newHash) public onlyOwner {
        ipfsHash = newHash;
    }

    /*************
     * Internals *
     *************/

    /**
     * @dev Convert an uint256 into a string
     */
    function _toString(uint256 value) internal pure returns (string memory) {
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
}

// HOK
